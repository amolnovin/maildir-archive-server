<#
.SYNOPSIS
    بازگردانی بکاپ ساخته‌شده توسط Backup-Archive.ps1
.EXAMPLE
    .\Restore-Archive.ps1 -ZipPath "..\backup\mas-full-20260806-120000.zip"
#>
param(
    [Parameter(Mandatory=$true)][string]$ZipPath,
    [switch]$MergeUsers
)

. "$PSScriptRoot\Common.ps1"

if (-not (Test-Path $ZipPath)) { Write-Err "فایل بکاپ یافت نشد: $ZipPath"; exit 1 }

$temp = Get-TempDir -Prefix "mas-restore"
Write-Info "استخراج بکاپ ..."
Expand-Archive -Path $ZipPath -DestinationPath $temp -Force

$mailSrc = Join-Path $temp "mail"
if (Test-Path $mailSrc) {
    Write-Info "بازگردانی ایمیل‌ها ..."
    Copy-Tree -Source $mailSrc -Destination $MailRoot
    Write-Ok "ایمیل‌ها بازگردانی شدند."
}

$usersSrc = Join-Path $temp "users"
if (Test-Path $usersSrc) {
    if ($MergeUsers -and (Test-Path $UsersFile)) {
        $current = @(Get-UsersTable)
        $emails  = $current.Email
        $added = 0
        foreach ($line in Get-Content $usersSrc -Encoding UTF8) {
            if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
            $e = $line.Split(':')[0]
            if ($emails -notcontains $e) {
                $current += [pscustomobject]@{ Email=$e; Domain=($e -split '@')[1]; User=($e -split '@')[0]; Hash=''; Raw=$line }
                $added++
            }
        }
        Save-UsersTable -Rows $current
        Write-Ok "$added کاربر جدید ادغام شد."
    } else {
        Copy-Item $usersSrc $UsersFile -Force
        Write-Ok "فایل کاربران بازگردانی شد."
    }
}

Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
Restart-Dovecot
Write-Ok "بازگردانی کامل شد."
