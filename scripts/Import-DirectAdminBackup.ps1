<#
.SYNOPSIS
    Import مستقیم بکاپ ایمیل دایرکت‌ادمین (Maildir) بدون تبدیل به mbox.

.DESCRIPTION
    ورودی می‌تواند یکی از این‌ها باشد:
      1) فایل بکاپ دایرکت‌ادمین:  user.admin.username.tar.gz  یا  backup-*.tar.zst
      2) پوشه‌ای که قبلاً extract شده و داخل آن پوشه imap/ وجود دارد
      3) مستقیماً یک پوشه Maildir

    ساختار بکاپ دایرکت‌ادمین:
        imap/<domain>/<user>/Maildir/{cur,new,tmp,.Sent,.Drafts,...}

    خروجی در پروژه:
        mail/<domain>/<user>/Maildir/...

.EXAMPLE
    .\Import-DirectAdminBackup.ps1 -Source "D:\backups\user.admin.komaj.tar.gz"
.EXAMPLE
    .\Import-DirectAdminBackup.ps1 -Source "D:\backups\extracted" -OnlyDomain komajsaba.com
.EXAMPLE
    .\Import-DirectAdminBackup.ps1 -Source "D:\backups\user.tar.gz" -CreateAccounts -DefaultPassword "Archive2026!"
#>
param(
    [Parameter(Mandatory=$true)][string]$Source,
    [string]$OnlyDomain,
    [switch]$CreateAccounts,
    [string]$DefaultPassword,
    [switch]$WhatIfOnly
)

. "$PSScriptRoot\Common.ps1"

if (-not (Test-Path $Source)) { Write-Err "مسیر ورودی یافت نشد: $Source"; exit 1 }

# ---------- بررسی پیش‌نیاز: این اسکریپت به Docker نیاز دارد ----------
# بدون موتور Docker، ایمیل‌ها کپی می‌شوند ولی هیچ راهی برای خواندنشان
# نیست. بهتر است همین اول صریح بگوییم تا کاربر وقت هدر ندهد.
if (-not (Test-ContainerRunning)) {
    Write-Host ""
    Write-Err "کانتینر Docker در حال اجرا نیست."
    Write-Host ""
    Write-Info "این اسکریپت برای حالت Docker است. بدون آن، ایمیل‌ها فقط"
    Write-Info "کپی می‌شوند ولی قابل خواندن نخواهند بود."
    Write-Host ""
    Write-Host "  اگر Docker دارید:" -ForegroundColor White
    Write-Host "     اول start.bat را اجرا کنید، بعد این اسکریپت را."
    Write-Host ""
    Write-Host "  اگر Docker ندارید یا کار نمی‌کند (مثلاً مجازی‌سازی نیست):" -ForegroundColor White
    Write-Host "     از مبدل mbox استفاده کنید که هیچ پیش‌نیازی ندارد:"
    Write-Host ""
    Write-Host "       .\convert-to-mbox.bat" -ForegroundColor Green
    Write-Host ""
    Write-Host "     یا مستقیم:"
    Write-Host "       powershell -ExecutionPolicy Bypass -File scripts\Convert-MaildirToMbox.ps1 -Source `"$Source`"" -ForegroundColor Green
    Write-Host ""
    Write-Info "راهنمای کامل: docs\START-HERE.md"
    Write-Host ""
    exit 1
}

$temp = $null
$root = $null

# ---------- مرحله ۱: آماده‌سازی مسیر منبع ----------
if ((Get-Item $Source).PSIsContainer) {
    $root = (Resolve-Path $Source).Path
    Write-Info "منبع: پوشه — $root"
} else {
    $temp = Get-TempDir -Prefix "mas-import"
    Write-Info "در حال استخراج بکاپ در مسیر موقت ..."
    Write-Info "(برای بکاپ‌های چند گیگابایتی ممکن است چند دقیقه طول بکشد)"

    $ext = [IO.Path]::GetExtension($Source).ToLower()
    try {
        if ($ext -eq ".zst" -or $Source -like "*.tar.zst") {
            # نیازمند zstd؛ در غیر این صورت با tar جدید ویندوز
            & tar --use-compress-program=unzstd -xf $Source -C $temp
        } else {
            & tar -xzf $Source -C $temp
        }
    } catch {
        Write-Err "استخراج ناموفق بود. مطمئن شوید tar در دسترس است (ویندوز ۱۰ به بالا دارد)."
        Write-Err $_.Exception.Message
        exit 1
    }
    $root = $temp
    Write-Ok "استخراج انجام شد."
}

# ---------- مرحله ۲: پیدا کردن پوشه imap ----------
$imapDirs = @(Get-ChildItem -Path $root -Directory -Recurse -Force -Filter "imap" -ErrorAction SilentlyContinue |
              Select-Object -First 3)

$pairs = @()   # لیست: domain, user, sourceMaildir

if ($imapDirs.Count -gt 0) {
    $imap = $imapDirs[0].FullName
    Write-Info "پوشه imap پیدا شد: $imap"
    foreach ($d in Get-ChildItem -Path $imap -Directory -Force) {
        if ($OnlyDomain -and $d.Name -ne $OnlyDomain.ToLower()) { continue }
        foreach ($u in Get-ChildItem -Path $d.FullName -Directory -Force) {
            $md = Join-Path $u.FullName "Maildir"
            if (Test-Path $md) {
                $pairs += [pscustomobject]@{ Domain=$d.Name; User=$u.Name; Path=$md }
            }
        }
    }
} else {
    # حالت جایگزین: خود پوشه یک Maildir است
    $maybe = Get-ChildItem -Path $root -Directory -Recurse -Force -Filter "Maildir" -ErrorAction SilentlyContinue |
             Select-Object -First 50
    foreach ($md in $maybe) {
        $userDir   = $md.Parent
        $domainDir = $userDir.Parent
        if ($OnlyDomain -and $domainDir.Name -ne $OnlyDomain.ToLower()) { continue }
        $pairs += [pscustomobject]@{ Domain=$domainDir.Name; User=$userDir.Name; Path=$md.FullName }
    }
}

if ($pairs.Count -eq 0) {
    Write-Err "هیچ Maildir ای در منبع پیدا نشد."
    Write-Info "انتظار می‌رفت ساختاری مثل  imap/<domain>/<user>/Maildir  وجود داشته باشد."
    if ($temp) { Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue }
    exit 1
}

Write-Host ""
Write-Info "mailboxهای پیدا شده:"
$pairs | ForEach-Object {
    "{0,-40} {1,8} MB" -f "$($_.User)@$($_.Domain)", (Get-FolderSizeMB -Path $_.Path) | Write-Host
}
Write-Host ""

if ($WhatIfOnly) {
    Write-Warn2 "حالت پیش‌نمایش (WhatIfOnly) — هیچ فایلی کپی نشد."
    if ($temp) { Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue }
    exit 0
}

# ---------- مرحله ۳: کپی ----------
$imported = 0
foreach ($p in $pairs) {
    $dest = Join-Path (Join-Path $MailRoot $p.Domain) $p.User
    $destMaildir = Join-Path $dest "Maildir"
    New-Item -ItemType Directory -Path $destMaildir -Force | Out-Null

    Write-Info "کپی $($p.User)@$($p.Domain) ..."
    try {
        Copy-Tree -Source $p.Path -Destination $destMaildir
    } catch {
        Write-Err "خطا در کپی $($p.User)@$($p.Domain): $($_.Exception.Message)"
        continue
    }

    # اطمینان از وجود cur/new/tmp
    foreach ($sub in @("cur","new","tmp")) {
        New-Item -ItemType Directory -Path (Join-Path $destMaildir $sub) -Force | Out-Null
    }

    # حذف ایندکس‌های قدیمی Dovecot تا دوباره ساخته شوند
    $n = Remove-DovecotIndexes -Path $destMaildir
    if ($n -gt 0) { Write-Info "  $n فایل ایندکس قدیمی حذف شد." }

    # ساخت فایل subscriptions تا همه پوشه‌ها در Thunderbird دیده شوند
    $c = Write-Subscriptions -MaildirPath $destMaildir
    Write-Info "  $c پوشه در subscriptions ثبت شد."

    $imported++
    Write-Ok "$($p.User)@$($p.Domain) وارد شد."

    if ($CreateAccounts) {
        $pass = if ($DefaultPassword) { $DefaultPassword } else { "Archive-" + $p.User + "-2026" }
        try {
            & "$PSScriptRoot\Add-User.ps1" -Email "$($p.User)@$($p.Domain)" -Password $pass -Force
        } catch {
            Write-Warn2 "ساخت اکانت ناموفق بود (کانتینر اجرا نیست؟): $($_.Exception.Message)"
        }
    }
}

if ($temp) {
    Write-Info "پاک‌سازی فایل‌های موقت ..."
    Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Ok "$imported mailbox وارد شد."
try {
    if (Test-ContainerRunning) {
        Write-Info "بازسازی ایندکس‌ها ..."
        docker exec mas-dovecot doveadm force-resync -A "*" 2>$null | Out-Null
        docker exec mas-dovecot doveadm index -A "*" 2>$null | Out-Null
        Write-Ok "ایندکس‌ها ساخته شدند."
    } else {
        Write-Info "کانتینر اجرا نیست؛ ایندکس‌ها در اولین اتصال ساخته می‌شوند."
    }
} catch {
    Write-Warn2 "ساخت ایندکس رد شد (Docker در دسترس نیست). مشکلی نیست؛ خودکار ساخته می‌شود."
}
Write-Info "گام بعد: اگر از -CreateAccounts استفاده نکردید، با Add-User.ps1 برای هر اکانت رمز تعریف کنید."
