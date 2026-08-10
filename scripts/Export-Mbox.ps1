<#
.SYNOPSIS
    خروجی گرفتن از یک اکانت به فرمت mbox (برای Thunderbird / ImportExportTools NG).

.DESCRIPTION
    از دستور `doveadm backup` داخل کانتینر استفاده می‌کند که تبدیل استاندارد
    Maildir → mbox را انجام می‌دهد. Maildir اصلی دست‌نخورده باقی می‌ماند.

    خروجی: پوشه‌ای در backup\<user>_<domain>_mbox\ شامل یک فایل برای هر پوشه:
        inbox      ← INBOX
        Sent       ← INBOX.Sent
        Trash      ← INBOX.Trash
        ...

.EXAMPLE
    .\Export-Mbox.ps1 -Email info@komajsaba.com
.EXAMPLE
    .\Export-Mbox.ps1 -Email info@komajsaba.com -Compress
#>
param(
    [Parameter(Mandatory=$true)][string]$Email,
    [switch]$Compress
)

. "$PSScriptRoot\Common.ps1"

if (-not (Test-ContainerRunning)) {
    Write-Err "کانتینر اجرا نیست. ابتدا start.bat را اجرا کنید."
    exit 1
}

$Email = $Email.Trim().ToLower()
$safe  = ($Email -replace '[@]','_' -replace '[^\w\-.]','_')
$outName = "${safe}_mbox"

# مسیر داخل کانتینر (روی volume مشترک backup)
$containerDir = "/srv/backup/$outName"
$hostDir      = Join-Path $BackupRoot $outName

if (Test-Path $hostDir) {
    $ans = Read-Host "پوشه خروجی از قبل وجود دارد. حذف و ساخت دوباره؟ (y/N)"
    if ($ans -ne 'y') { Write-Info "لغو شد."; exit 0 }
    Remove-Item $hostDir -Recurse -Force
}

Write-Info "در حال تبدیل Maildir به mbox برای $Email ..."
Write-Info "(برای mailboxهای بزرگ ممکن است چند دقیقه طول بکشد)"

docker exec mas-dovecot sh -c "rm -rf '$containerDir' && mkdir -p '$containerDir'" | Out-Null

# ابتدا ایندکس‌ها را سالم کن تا خطای اندازه/کش رخ ندهد
docker exec mas-dovecot doveadm force-resync -u $Email '*' 2>$null | Out-Null

$err = docker exec mas-dovecot doveadm backup -u $Email "mbox:$containerDir" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Err "تبدیل ناموفق بود:"
    $err | Select-Object -First 5 | ForEach-Object { Write-Host "   $_" }
    exit 1
}
if ($err) {
    Write-Warn2 "هشدارهای Dovecot (معمولاً بی‌خطر):"
    $err | Select-Object -First 3 | ForEach-Object { Write-Host "   $_" }
}

# پاک کردن فایل‌های کمکی که برای Thunderbird لازم نیستند
docker exec mas-dovecot sh -c "rm -rf '$containerDir/.imap' '$containerDir'/*.lock" 2>$null | Out-Null

if (-not (Test-Path $hostDir)) {
    Write-Err "پوشه خروجی ساخته نشد. آیا volume ./backup به کانتینر متصل است؟"
    exit 1
}

$files = Get-ChildItem -Path $hostDir -File | Where-Object { $_.Name -notlike ".*" }
Write-Host ""
Write-Ok "فایل‌های mbox ساخته شدند در: $hostDir"
$files | ForEach-Object {
    "   {0,-20} {1,8} MB" -f $_.Name, [math]::Round($_.Length/1MB,2) | Write-Host
}

if ($Compress) {
    $zip = "$hostDir.zip"
    Compress-Archive -Path (Join-Path $hostDir '*') -DestinationPath $zip -Force
    Write-Ok "فایل فشرده: $zip"
}

Write-Host ""
Write-Info "نحوه استفاده در Thunderbird:"
Write-Host "   ۱) یک پوشه محلی (Local Folders) بسازید"
Write-Host "   ۲) راست‌کلیک → ImportExportTools NG → Import mbox file"
Write-Host "   ۳) فایل موردنظر (مثلاً inbox یا Sent) را انتخاب کنید"
Write-Host ""
Write-Warn2 "توجه: هر فایل mbox یک پیام اضافی با عنوان"
Write-Warn2 "«DON'T DELETE THIS MESSAGE -- FOLDER INTERNAL DATA» دارد که"
Write-Warn2 "بخش استاندارد فرمت mbox است و می‌توانید بعد از import حذفش کنید."
