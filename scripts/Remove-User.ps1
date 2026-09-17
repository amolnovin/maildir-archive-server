<#
.SYNOPSIS
    حذف یک اکانت از فایل کاربران (به‌صورت پیش‌فرض ایمیل‌ها حذف نمی‌شوند).
.EXAMPLE
    .\Remove-User.ps1 -Email old@komajsaba.com
    .\Remove-User.ps1 -Email old@komajsaba.com -DeleteMail
#>
param(
    [Parameter(Mandatory=$true)][string]$Email,
    [switch]$DeleteMail
)

. "$PSScriptRoot\Common.ps1"

$Email = $Email.Trim().ToLower()
$rows = @(Get-UsersTable)
if (-not ($rows | Where-Object { $_.Email -eq $Email })) {
    Write-Warn2 "چنین کاربری وجود ندارد: $Email"
    exit 0
}

Save-UsersTable -Rows ($rows | Where-Object { $_.Email -ne $Email })
Write-Ok "کاربر از فهرست حذف شد: $Email"

if ($DeleteMail) {
    $local  = ($Email -split '@')[0]
    $domain = ($Email -split '@')[1]
    $path = Join-Path (Join-Path $MailRoot $domain) $local
    $ans = Read-Host "حذف کامل پوشه ایمیل‌ها؟ این عمل برگشت‌ناپذیر است. تایپ کنید DELETE"
    if ($ans -eq 'DELETE') {
        Remove-Item -Path $path -Recurse -Force
        Write-Ok "پوشه ایمیل حذف شد: $path"
    } else {
        Write-Info "حذف فایل‌ها لغو شد."
    }
}

Restart-Dovecot
