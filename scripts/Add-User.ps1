<#
.SYNOPSIS
    ساخت یا به‌روزرسانی یک اکانت ایمیل (mailbox) روی سرور آرشیو.
.EXAMPLE
    .\Add-User.ps1 -Email info@komajsaba.com -Password "Str0ngPass!"
.EXAMPLE
    .\Add-User.ps1 -Email info@komajsaba.com          # رمز به‌صورت امن پرسیده می‌شود
#>
param(
    [Parameter(Mandatory=$true)][string]$Email,
    [string]$Password,
    [switch]$Force
)

. "$PSScriptRoot\Common.ps1"

$Email = $Email.Trim().ToLower()
if ($Email -notmatch '^[^@\s]+@[a-z0-9.-]+\.[a-z]{2,}$') {
    Write-Err "آدرس ایمیل معتبر نیست: $Email"
    exit 1
}

$local  = ($Email -split '@')[0]
$domain = ($Email -split '@')[1]

if (-not $Password) {
    $sec = Read-Host "رمز عبور برای $Email" -AsSecureString
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}
if ($Password.Length -lt 6) {
    Write-Err "رمز عبور باید حداقل ۶ کاراکتر باشد."
    exit 1
}

if (-not (Test-Docker)) { exit 1 }
if (-not (Test-ContainerRunning)) {
    Write-Err "کانتینر در حال اجرا نیست. ابتدا start.bat را اجرا کنید."
    exit 1
}

# ساخت ساختار پوشه Maildir
$home_ = Join-Path (Join-Path $MailRoot $domain) $local
$maildir = Join-Path $home_ "Maildir"
foreach ($sub in @("cur","new","tmp")) {
    New-Item -ItemType Directory -Path (Join-Path $maildir $sub) -Force | Out-Null
}
foreach ($folder in @(".Sent",".Drafts",".Trash",".Junk",".Archive")) {
    foreach ($sub in @("cur","new","tmp")) {
        New-Item -ItemType Directory -Path (Join-Path (Join-Path $maildir $folder) $sub) -Force | Out-Null
    }
}

# ثبت پوشه‌ها در subscriptions تا در Thunderbird دیده شوند
Write-Subscriptions -MaildirPath $maildir | Out-Null

$hash = New-PasswordHash -PlainPassword $Password
$line = "{0}:{1}:5000:5000::/srv/mail/{2}/{3}" -f $Email, $hash, $domain, $local

$rows = @(Get-UsersTable)
$existing = $rows | Where-Object { $_.Email -eq $Email }
if ($existing) {
    if (-not $Force) {
        $ans = Read-Host "کاربر $Email از قبل وجود دارد. رمز به‌روزرسانی شود؟ (y/N)"
        if ($ans -ne 'y') { Write-Info "لغو شد."; exit 0 }
    }
    $rows = $rows | Where-Object { $_.Email -ne $Email }
    Write-Info "رمز کاربر موجود به‌روزرسانی می‌شود."
}
$rows += [pscustomobject]@{ Email=$Email; Domain=$domain; User=$local; Hash=$hash; Raw=$line }
Save-UsersTable -Rows $rows
Restart-Dovecot

Write-Ok "اکانت آماده است: $Email"
Write-Host ""
Write-Host "  تنظیمات کلاینت (Thunderbird / Outlook):" -ForegroundColor White
Write-Host "  Server        : localhost"
Write-Host "  IMAP Port     : 143  (STARTTLS)  یا  993 (SSL/TLS)"
Write-Host "  Username      : $Email"
Write-Host "  Authentication: Normal password"
Write-Host "  SMTP          : ندارد (این سرور فقط آرشیو خواندنی/IMAP است)"
