<#
.SYNOPSIS
    گرفتن بکاپ کامل از آرشیو (ایمیل‌ها + فایل کاربران + پیکربندی).
.EXAMPLE
    .\Backup-Archive.ps1
    .\Backup-Archive.ps1 -Domain komajsaba.com -Destination "D:\archive-backups"
#>
param(
    [string]$Domain,
    [string]$Destination
)

. "$PSScriptRoot\Common.ps1"

if (-not $Destination) { $Destination = $BackupRoot }
if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$name  = if ($Domain) { "mas-$($Domain)-$stamp" } else { "mas-full-$stamp" }
$staging = Join-Path (Get-TempDir -Prefix "mas-backup") $name
New-Item -ItemType Directory -Path $staging -Force | Out-Null

Write-Info "آماده‌سازی بکاپ: $name"

# ایمیل‌ها
$mailStage = Join-Path $staging "mail"
New-Item -ItemType Directory -Path $mailStage -Force | Out-Null
if ($Domain) {
    $src = Join-Path $MailRoot $Domain.ToLower()
    if (-not (Test-Path $src)) { Write-Err "دامنه یافت نشد: $Domain"; exit 1 }
    Copy-Tree -Source $src -Destination (Join-Path $mailStage $Domain.ToLower())
} else {
    Copy-Tree -Source $MailRoot -Destination $mailStage
}

# پیکربندی و کاربران
if (Test-Path $UsersFile) { Copy-Item $UsersFile (Join-Path $staging "users") -Force }
Copy-Item (Join-Path $ProjectRoot "docker\dovecot\dovecot.conf") $staging -Force -ErrorAction SilentlyContinue

@{
    createdAt = (Get-Date).ToString("s")
    domain    = if ($Domain) { $Domain } else { "ALL" }
    tool      = "Maildir Archive Server 1.0"
} | ConvertTo-Json | Set-Content (Join-Path $staging "manifest.json") -Encoding UTF8

$zip = Join-Path $Destination "$name.zip"
Write-Info "فشرده‌سازی ..."
Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $zip -CompressionLevel Optimal -Force
Remove-Item $staging -Recurse -Force

$sizeMB = [math]::Round((Get-Item $zip).Length / 1MB, 2)
Write-Ok "بکاپ ساخته شد: $zip ($sizeMB MB)"
