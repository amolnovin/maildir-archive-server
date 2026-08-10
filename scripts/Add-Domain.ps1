<#
.SYNOPSIS
    افزودن یک دامنه جدید به سرور آرشیو.
.EXAMPLE
    .\Add-Domain.ps1 -Domain komajsaba.com
#>
param(
    [Parameter(Mandatory=$true)][string]$Domain
)

. "$PSScriptRoot\Common.ps1"

$Domain = $Domain.Trim().ToLower()
if ($Domain -notmatch '^[a-z0-9.-]+\.[a-z]{2,}$') {
    Write-Err "نام دامنه معتبر نیست: $Domain"
    exit 1
}

$path = Join-Path $MailRoot $Domain
if (Test-Path $path) {
    Write-Warn2 "دامنه از قبل وجود دارد: $Domain"
} else {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Write-Ok "دامنه ساخته شد: $Domain"
}

Write-Info "مسیر: $path"
Write-Info "گام بعد: ساخت کاربر با  .\Add-User.ps1 -Email info@$Domain"
