# ============================================================
#  توابع مشترک اسکریپت‌های PowerShell
#  Maildir Archive Server
# ============================================================

$ErrorActionPreference = "Stop"

# ریشه پروژه = پوشه والد scripts
$Global:ProjectRoot = Split-Path -Parent $PSScriptRoot
$Global:MailRoot    = Join-Path $ProjectRoot "mail"
$Global:UsersFile   = Join-Path $ProjectRoot "docker\dovecot\users"
$Global:BackupRoot  = Join-Path $ProjectRoot "backup"
$Global:ComposeFile = Join-Path $ProjectRoot "docker-compose.yml"

function Write-Ok    ($m) { Write-Host "[OK]    $m" -ForegroundColor Green }
function Write-Info  ($m) { Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Write-Warn2 ($m) { Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Err   ($m) { Write-Host "[ERROR] $m" -ForegroundColor Red }

function Test-Docker {
    try {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw "docker not found" }
        docker version --format '{{.Server.Version}}' | Out-Null
        return $true
    } catch {
        Write-Err "Docker در دسترس نیست. لطفاً Docker Desktop را اجرا کنید."
        return $false
    }
}

function Test-ContainerRunning {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return $false }
    try {
        $name = "mas-dovecot"
        $running = docker ps --filter "name=$name" --filter "status=running" --format "{{.Names}}" 2>$null
        return ($running -eq $name)
    } catch { return $false }
}

function Invoke-Doveadm {
    param([Parameter(Mandatory=$true)][string[]]$Args)
    if (-not (Test-ContainerRunning)) {
        throw "کانتینر mas-dovecot در حال اجرا نیست. ابتدا start.bat را اجرا کنید."
    }
    & docker exec mas-dovecot doveadm @Args
}

function New-PasswordHash {
    param([Parameter(Mandatory=$true)][string]$PlainPassword)
    if (-not (Test-ContainerRunning)) {
        throw "برای ساخت hash رمز، کانتینر باید در حال اجرا باشد. ابتدا start.bat را اجرا کنید."
    }
    $hash = & docker exec mas-dovecot doveadm pw -s SHA512-CRYPT -p $PlainPassword
    if ([string]::IsNullOrWhiteSpace($hash)) { throw "ساخت hash رمز ناموفق بود." }
    return $hash.Trim()
}

function Get-UsersTable {
    if (-not (Test-Path $UsersFile)) { return @() }
    $rows = @()
    foreach ($line in Get-Content $UsersFile -Encoding UTF8) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line.Split(':')
        if ($parts.Count -lt 2) { continue }
        $email = $parts[0]
        $rows += [pscustomobject]@{
            Email  = $email
            Domain = ($email -split '@')[1]
            User   = ($email -split '@')[0]
            Hash   = $parts[1]
            Raw    = $line
        }
    }
    return $rows
}

function Save-UsersTable {
    param([Parameter(Mandatory=$true)]$Rows)
    $header = @(
        "# Maildir Archive Server - فایل کاربران Dovecot",
        "# قالب: email:{SCHEME}hash:uid:gid::home",
        "# این فایل توسط اسکریپت‌های scripts\ مدیریت می‌شود."
    )
    $lines = $header + ($Rows | ForEach-Object { $_.Raw })
    $dir = Split-Path -Parent $UsersFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    # بدون BOM و با پایان خط LF (Dovecot به آن حساس است)
    $content = ($lines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($UsersFile, $content, (New-Object System.Text.UTF8Encoding($false)))
}

function Restart-Dovecot {
    if (Test-ContainerRunning) {
        Write-Info "بارگذاری مجدد پیکربندی Dovecot ..."
        docker exec mas-dovecot doveadm reload 2>$null | Out-Null
        Write-Ok "پیکربندی بارگذاری شد."
    }
}

function Get-TempDir {
    param([string]$Prefix = "mas")
    $base = [System.IO.Path]::GetTempPath()
    $p = Join-Path $base ("$Prefix-" + [guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    return $p
}

<#
 کپی درختی پوشه.
 روی ویندوز از robocopy استفاده می‌کند (سریع، چندنخی، مقاوم در برابر مسیرهای طولانی)
 و در غیر این صورت به Copy-Item برمی‌گردد. برای Maildir حیاتی است که نام فایل‌ها
 (که شامل ':' هستند) دست‌نخورده بمانند؛ هر دو روش این را رعایت می‌کنند.
#>
function Copy-Tree {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    $useRobocopy = $false
    if ($IsWindows -or ($null -eq $IsWindows)) {   # PS 5.1 روی ویندوز $IsWindows ندارد
        if (Get-Command robocopy -ErrorAction SilentlyContinue) { $useRobocopy = $true }
    }

    if ($useRobocopy) {
        $p = Start-Process -FilePath robocopy -ArgumentList @(
                "`"$Source`"", "`"$Destination`"", "/E", "/NFL", "/NDL",
                "/NJH", "/NJS", "/R:1", "/W:1", "/MT:8"
             ) -Wait -PassThru -NoNewWindow
        # کدهای ۰ تا ۷ در robocopy یعنی موفقیت
        if ($p.ExitCode -ge 8) { throw "robocopy failed with exit code $($p.ExitCode)" }
    } else {
        Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force -ErrorAction Stop
    }
}

<#
 حذف ایندکس‌های Dovecot که از سرور مبدأ آمده‌اند.
 اگر باقی بمانند، Dovecot ممکن است پوشه‌ها را خالی نشان دهد.
#>
function Remove-DovecotIndexes {
    param([Parameter(Mandatory=$true)][string]$Path)
    $names = @('dovecot.index','dovecot.index.log','dovecot.index.cache',
               'dovecot-uidlist','dovecot.mailbox.log','dovecot-keywords')
    $removed = 0
    Get-ChildItem -Path $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Where-Object { $names -contains $_.Name -or $_.Name -like 'dovecot.index*' } |
        ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue; $removed++ }
    return $removed
}

<#
 ساخت فایل subscriptions از روی پوشه‌های Maildir موجود،
 تا Thunderbird همه پوشه‌ها را ببیند.

 ⚠️ نکته مهم: چون در dovecot.conf مقدار `prefix = INBOX.` تنظیم شده،
 نام‌ها در فایل subscriptions باید *بدون* پیشوند INBOX. نوشته شوند.
 اگر «INBOX.Sent» بنویسیم، Dovecot آن را «INBOX.INBOX.Sent» گزارش می‌کند
 و Thunderbird پوشه‌های تکراری و خالی نشان می‌دهد.
 پس ".Sent" روی دیسک  →  "Sent" در فایل subscriptions.
#>
function Write-Subscriptions {
    param([Parameter(Mandatory=$true)][string]$MaildirPath)
    $folders = Get-ChildItem -Path $MaildirPath -Directory -Force -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -like '.*' -and $_.Name -ne '.' -and $_.Name -ne '..' } |
               ForEach-Object { $_.Name.Substring(1) } |
               Where-Object { $_ -ne '' }
    $subs = @('INBOX') + $folders
    [System.IO.File]::WriteAllText(
        (Join-Path $MaildirPath 'subscriptions'),
        (($subs -join "`n") + "`n"),
        (New-Object System.Text.UTF8Encoding($false)))
    return $subs.Count
}

function Get-FolderSizeMB {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    $bytes = (Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
              Measure-Object -Property Length -Sum).Sum
    if (-not $bytes) { return 0 }
    return [math]::Round($bytes / 1MB, 2)
}
