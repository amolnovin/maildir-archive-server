<#
.SYNOPSIS
    تبدیل بکاپ Maildir دایرکت‌ادمین به فایل‌های mbox — بدون Docker و بدون مجازی‌سازی.

.DESCRIPTION
    این اسکریپت هیچ نیازی به Docker، WSL یا مجازی‌سازی ندارد. فقط PowerShell.
    خروجی آن فایل‌های mbox است که افزونهٔ ImportExportTools NG در Thunderbird
    مستقیماً می‌تواند import کند.

    نکات فنی رعایت‌شده:
      • جداکنندهٔ استاندارد "From " در ابتدای هر پیام
      • escape کردن خطوطی از متن که با "From " شروع می‌شوند (سبک mboxrd)
      • تبدیل فلگ‌های Maildir به هدرهای Status/X-Status تا وضعیت
        خوانده‌شده/پاسخ‌داده‌شده/ستاره‌دار در Thunderbird حفظ شود
      • پردازش هر دو پوشهٔ cur و new
      • تبدیل پوشه‌های تودرتو مثل .Sent.2024 به Sent.2024

.PARAMETER Source
    مسیر بکاپ. می‌تواند یکی از این‌ها باشد:
      - پوشه‌ای که داخلش imap/ هست (بکاپ extract شدهٔ دایرکت‌ادمین)
      - مستقیماً یک پوشهٔ Maildir
      - پوشه‌ای شامل چند دامنه/کاربر

.PARAMETER Destination
    پوشهٔ خروجی. پیش‌فرض: mbox-export کنار پروژه.

.PARAMETER OnlyDomain
    فقط یک دامنهٔ خاص را تبدیل کن.

.EXAMPLE
    .\Convert-MaildirToMbox.ps1 -Source "D:\backup\extracted"
.EXAMPLE
    .\Convert-MaildirToMbox.ps1 -Source "D:\backup\extracted" -OnlyDomain komajsaba.com
#>
param(
    [Parameter(Mandatory=$true)][string]$Source,
    [string]$Destination,
    [string]$OnlyDomain
)

$ErrorActionPreference = "Stop"

function Write-Ok    ($m) { Write-Host "[OK]    $m" -ForegroundColor Green }
function Write-Info  ($m) { Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Write-Warn2 ($m) { Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Err   ($m) { Write-Host "[ERROR] $m" -ForegroundColor Red }

if (-not (Test-Path $Source)) { Write-Err "مسیر ورودی یافت نشد: $Source"; exit 1 }

# ---------------------------------------------------------------
#  اگر ورودی یک فایل فشرده است، اول آن را استخراج کن
#  (tar.gz / tgz / tar / tar.zst / zip)
# ---------------------------------------------------------------
$TempExtract = $null
if (-not (Get-Item $Source).PSIsContainer) {
    $name = [IO.Path]::GetFileName($Source).ToLower()
    $TempExtract = Join-Path ([System.IO.Path]::GetTempPath()) ("mas-x-" + [guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item -ItemType Directory -Path $TempExtract -Force | Out-Null

    Write-Info "ورودی یک فایل فشرده است. در حال استخراج..."
    Write-Info "(برای بکاپ‌های چند گیگابایتی چند دقیقه طول می‌کشد)"

    try {
        if ($name -like "*.zip") {
            Expand-Archive -Path $Source -DestinationPath $TempExtract -Force
        }
        elseif ($name -like "*.tar.zst" -or $name -like "*.zst") {
            & tar --use-compress-program=unzstd -xf $Source -C $TempExtract
            if ($LASTEXITCODE -ne 0) { throw "tar/zstd خطا داد (کد $LASTEXITCODE)" }
        }
        elseif ($name -like "*.tar.gz" -or $name -like "*.tgz") {
            & tar -xzf $Source -C $TempExtract
            if ($LASTEXITCODE -ne 0) { throw "tar خطا داد (کد $LASTEXITCODE)" }
        }
        elseif ($name -like "*.tar") {
            & tar -xf $Source -C $TempExtract
            if ($LASTEXITCODE -ne 0) { throw "tar خطا داد (کد $LASTEXITCODE)" }
        }
        else {
            Write-Err "نوع فایل شناخته نشد: $name"
            Write-Info "فرمت‌های پشتیبانی‌شده: .tar.gz .tgz .tar .tar.zst .zip"
            Write-Info "یا فایل را دستی اکسترکت کنید و مسیر پوشه را بدهید."
            Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
            exit 1
        }
    } catch {
        Write-Err "استخراج ناموفق بود: $($_.Exception.Message)"
        Write-Info "مطمئن شوید دستور tar در دسترس است (ویندوز ۱۰ به بالا دارد):  tar --version"
        Write-Info "یا فایل را با 7-Zip اکسترکت کنید و مسیر پوشه را بدهید."
        Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Write-Ok "استخراج انجام شد."

    # بعضی بکاپ‌ها دو لایه فشرده‌اند: داخلشان یک .tar دیگر هست
    $innerTar = Get-ChildItem -Path $TempExtract -File -Filter "*.tar" -ErrorAction SilentlyContinue |
                Select-Object -First 1
    if ($innerTar -and -not (Get-ChildItem -Path $TempExtract -Directory -Force -ErrorAction SilentlyContinue)) {
        Write-Info "یک فایل tar داخلی پیدا شد، در حال استخراج لایهٔ دوم..."
        & tar -xf $innerTar.FullName -C $TempExtract
        Remove-Item $innerTar.FullName -Force -ErrorAction SilentlyContinue
        Write-Ok "لایهٔ دوم استخراج شد."
    }

    $Source = $TempExtract
}

if (-not $Destination) {
    $Destination = Join-Path (Split-Path -Parent $PSScriptRoot) "mbox-export"
}
if (-not (Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor White
Write-Host "  Maildir  ->  mbox   (بدون Docker)" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor White
Write-Host ""
Write-Info "ورودی : $Source"
Write-Info "خروجی : $Destination"
Write-Host ""

# ---------------------------------------------------------------
#  پیدا کردن همهٔ Maildirها
# ---------------------------------------------------------------
$maildirs = @()

$imapDir = Get-ChildItem -Path $Source -Directory -Recurse -Force -Filter "imap" -ErrorAction SilentlyContinue |
           Select-Object -First 1

if ($imapDir) {
    Write-Info "ساختار بکاپ دایرکت‌ادمین شناسایی شد: $($imapDir.FullName)"
    foreach ($d in Get-ChildItem -Path $imapDir.FullName -Directory -Force -ErrorAction SilentlyContinue) {
        if ($OnlyDomain -and $d.Name -ne $OnlyDomain.ToLower()) { continue }
        foreach ($u in Get-ChildItem -Path $d.FullName -Directory -Force -ErrorAction SilentlyContinue) {
            $md = Join-Path $u.FullName "Maildir"
            if (Test-Path $md) {
                $maildirs += [pscustomobject]@{ Domain=$d.Name; User=$u.Name; Path=$md }
            }
        }
    }
}

if ($maildirs.Count -eq 0) {
    # حالت جایگزین: دنبال هر پوشه‌ای به نام Maildir بگرد
    $found = Get-ChildItem -Path $Source -Directory -Recurse -Force -Filter "Maildir" -ErrorAction SilentlyContinue |
             Select-Object -First 200
    foreach ($md in $found) {
        $user   = $md.Parent
        $domain = if ($user.Parent) { $user.Parent.Name } else { "local" }
        if ($OnlyDomain -and $domain -ne $OnlyDomain.ToLower()) { continue }
        $maildirs += [pscustomobject]@{ Domain=$domain; User=$user.Name; Path=$md.FullName }
    }
}

if ($maildirs.Count -eq 0) {
    # آخرین حالت: خود مسیر ورودی یک Maildir است
    if ((Test-Path (Join-Path $Source "cur")) -or (Test-Path (Join-Path $Source "new"))) {
        $maildirs += [pscustomobject]@{ Domain="local"; User=(Split-Path $Source -Leaf); Path=$Source }
    }
}

if ($maildirs.Count -eq 0) {
    Write-Err "هیچ Maildir ای پیدا نشد."
    Write-Info "انتظار می‌رفت ساختاری مثل imap/<domain>/<user>/Maildir وجود داشته باشد،"
    Write-Info "یا مسیری که مستقیماً شامل پوشه‌های cur/ و new/ باشد."
    exit 1
}

Write-Ok "$($maildirs.Count) mailbox پیدا شد."
Write-Host ""

# ---------------------------------------------------------------
#  توابع کمکی
# ---------------------------------------------------------------

# تبدیل فلگ‌های Maildir به هدرهای mbox
# فلگ‌ها بعد از ":2," در نام فایل می‌آیند:  S=Seen R=Replied F=Flagged D=Draft T=Trashed
function Get-StatusHeaders {
    param([string]$FileName)
    $flags = ""
    if ($FileName -match ':2,([A-Za-z]*)$') { $flags = $Matches[1] }

    $status  = ""
    $xstatus = ""
    if ($flags -match 'S') { $status  += "R" }   # Read
    $status += "O"                                # Old (already stored)
    if ($flags -match 'R') { $xstatus += "A" }   # Answered
    if ($flags -match 'F') { $xstatus += "F" }   # Flagged
    if ($flags -match 'D') { $xstatus += "T" }   # Draft
    if ($flags -match 'T') { $xstatus += "D" }   # Deleted

    $out = "Status: $status`r`n"
    if ($xstatus) { $out += "X-Status: $xstatus`r`n" }
    return $out
}

# استخراج آدرس فرستنده برای خط جداکنندهٔ "From "
function Get-EnvelopeSender {
    param([string]$HeaderBlock)
    if ($HeaderBlock -match '(?im)^Return-Path:\s*<([^>]+)>') { return $Matches[1] }
    if ($HeaderBlock -match '(?im)^From:.*<([^>]+)>')          { return $Matches[1] }
    if ($HeaderBlock -match '(?im)^From:\s*([^\s<>]+@[^\s<>]+)') { return $Matches[1] }
    return "MAILER-DAEMON"
}

# تاریخ برای خط جداکننده (فرمت asctime انگلیسی)
function Get-EnvelopeDate {
    param([string]$HeaderBlock, [datetime]$Fallback)
    $dt = $Fallback
    if ($HeaderBlock -match '(?im)^Date:\s*(.+)$') {
        $raw = $Matches[1].Trim()
        [datetime]$parsed = [datetime]::MinValue
        if ([datetime]::TryParse($raw, [ref]$parsed)) { $dt = $parsed }
    }
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    return $dt.ToString("ddd MMM dd HH:mm:ss yyyy", $inv)
}

# نام پوشهٔ خروجی از نام پوشهٔ Maildir
#   .Sent        -> Sent
#   .Sent.2024   -> Sent.2024
function Get-FolderLabel {
    param([string]$DirName)
    return $DirName.TrimStart('.')
}

# ---------------------------------------------------------------
#  تبدیل یک پوشه به یک فایل mbox
# ---------------------------------------------------------------
function Convert-OneFolder {
    param(
        [string]$FolderPath,   # پوشه‌ای که cur/new دارد
        [string]$OutFile
    )

    $msgFiles = @()
    foreach ($sub in @("cur","new")) {
        $p = Join-Path $FolderPath $sub
        if (Test-Path $p) {
            $msgFiles += Get-ChildItem -Path $p -File -Force -ErrorAction SilentlyContinue
        }
    }
    if ($msgFiles.Count -eq 0) { return 0 }

    # مرتب‌سازی بر اساس زمان برای ترتیب طبیعی
    $msgFiles = $msgFiles | Sort-Object LastWriteTime

    $enc    = New-Object System.Text.UTF8Encoding($false)
    $stream = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create,
                                     [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    $writer = New-Object System.IO.StreamWriter($stream, $enc)
    $writer.NewLine = "`r`n"

    $count = 0
    foreach ($f in $msgFiles) {
        try {
            # پیام‌ها را به‌صورت متن با انکودینگ حفظ‌شونده می‌خوانیم.
            # Latin1 هر بایت را ۱:۱ نگه می‌دارد، پس UTF-8 و هر انکودینگ
            # دیگری بدون خرابی عبور می‌کند.
            $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
            $text  = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
        } catch {
            Write-Warn2 "  رد شد (خواندن ناموفق): $($f.Name)"
            continue
        }
        if ([string]::IsNullOrWhiteSpace($text)) { continue }

        # جدا کردن هدر از بدنه
        $sepIdx = $text.IndexOf("`r`n`r`n")
        $sepLen = 4
        if ($sepIdx -lt 0) {
            $sepIdx = $text.IndexOf("`n`n")
            $sepLen = 2
        }
        if ($sepIdx -lt 0) {
            $headerBlock = $text
            $bodyBlock   = ""
        } else {
            $headerBlock = $text.Substring(0, $sepIdx)
            $bodyBlock   = $text.Substring($sepIdx + $sepLen)
        }

        $sender = Get-EnvelopeSender -HeaderBlock $headerBlock
        $date   = Get-EnvelopeDate  -HeaderBlock $headerBlock -Fallback $f.LastWriteTime

        # حذف هدرهای Status قبلی تا تکراری نشوند
        $headerLines = $headerBlock -split "`r`n|`n" |
                       Where-Object { $_ -notmatch '^(Status|X-Status):' }
        $headerBlock = ($headerLines -join "`r`n")

        # خط جداکنندهٔ mbox
        $writer.Write("From $sender  $date`r`n")

        # هدرها + وضعیت پیام
        $writer.Write($headerBlock)
        if (-not $headerBlock.EndsWith("`r`n")) { $writer.Write("`r`n") }
        $writer.Write((Get-StatusHeaders -FileName $f.Name))
        $writer.Write("`r`n")

        # بدنه، با escape کردن خطوطی که با From شروع می‌شوند
        if ($bodyBlock.Length -gt 0) {
            # حذف CR/LF انتهایی تا خط خالی تکراری تولید نشود
            $bodyBlock = $bodyBlock -replace '(\r?\n)+$', ''
            $bodyLines = $bodyBlock -split "`r`n|`n"
            foreach ($line in $bodyLines) {
                # هر CR باقی‌مانده در انتهای خط را پاک کن (فایل‌های با
                # پایان‌خط مخلوط، که در بکاپ‌های قدیمی زیاد دیده می‌شود)
                $line = $line.TrimEnd("`r")
                if ($line -match '^>*From ') { $writer.Write(">") }
                $writer.Write($line)
                $writer.Write("`r`n")
            }
        }
        # خط خالی بین پیام‌ها (الزام فرمت mbox)
        $writer.Write("`r`n")
        $count++
    }

    $writer.Flush()
    $writer.Close()
    $stream.Close()
    return $count
}

# ---------------------------------------------------------------
#  اجرای اصلی
# ---------------------------------------------------------------
$totalMsgs   = 0
$totalBoxes  = 0

foreach ($mb in $maildirs) {
    $label = "$($mb.User)@$($mb.Domain)"
    Write-Host "--- $label ---" -ForegroundColor White

    $outDir = Join-Path $Destination ("{0}_{1}" -f $mb.User, ($mb.Domain -replace '\.','_'))
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    # INBOX (ریشهٔ Maildir)
    $n = Convert-OneFolder -FolderPath $mb.Path -OutFile (Join-Path $outDir "INBOX.mbox")
    if ($n -gt 0) {
        Write-Host ("    {0,-22} {1,6} پیام" -f "INBOX", $n)
        $totalMsgs += $n
    } else {
        Remove-Item (Join-Path $outDir "INBOX.mbox") -ErrorAction SilentlyContinue
    }

    # زیرپوشه‌ها (.Sent، .Trash، ...)
    $subFolders = Get-ChildItem -Path $mb.Path -Directory -Force -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -like ".*" -and $_.Name -notin @('.','..') }

    foreach ($sf in $subFolders) {
        $lbl  = Get-FolderLabel -DirName $sf.Name
        if ([string]::IsNullOrWhiteSpace($lbl)) { continue }
        $safe = ($lbl -replace '[\\/:*?"<>|]','_')
        $out  = Join-Path $outDir "$safe.mbox"
        $n = Convert-OneFolder -FolderPath $sf.FullName -OutFile $out
        if ($n -gt 0) {
            Write-Host ("    {0,-22} {1,6} پیام" -f $lbl, $n)
            $totalMsgs += $n
        } else {
            Remove-Item $out -ErrorAction SilentlyContinue
        }
    }

    $totalBoxes++
    Write-Host ""
}

# پاک کردن فایل‌های موقت استخراج‌شده
if ($TempExtract -and (Test-Path $TempExtract)) {
    Write-Info "پاک‌سازی فایل‌های موقت..."
    Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "==========================================" -ForegroundColor White
Write-Ok "$totalBoxes mailbox و مجموعاً $totalMsgs پیام تبدیل شد."
Write-Info "خروجی در: $Destination"
Write-Host ""
Write-Host "مرحلهٔ بعد در Thunderbird:" -ForegroundColor White
Write-Host "  ۱) روی Local Folders راست‌کلیک کنید"
Write-Host "  ۲) ImportExportTools NG  ->  Import mbox file"
Write-Host "  ۳) گزینهٔ 'Import directly one or more mbox files' را بزنید"
Write-Host "  ۴) فایل‌های .mbox را از پوشهٔ بالا انتخاب کنید"
Write-Host ""
