# 🚀 از اینجا شروع کنید — راهنمای کامل

این سند شما را از صفر تا خواندن ایمیل‌های بکاپ در Thunderbird می‌برد.

---

## فهرست

1. [این پروژه چه کاری می‌کند؟](#۱-این-پروژه-چه-کاری-میکند)
2. [کدام مسیر مال شماست؟](#۲-کدام-مسیر-مال-شماست)
3. [مسیر A — بدون Docker (ساده و سریع)](#مسیر-a--بدون-docker)
4. [مسیر B — با Docker (کامل، با IMAP)](#مسیر-b--با-docker)
5. [هر فایل چه کاری می‌کند؟](#۵-هر-فایل-چه-کاری-میکند)
6. [کارهای روزمره](#۶-کارهای-روزمره)
7. [مشکل دارید؟](#۷-مشکل-دارید)

---

## ۱. این پروژه چه کاری می‌کند؟

شما یک **بکاپ ایمیل از دایرکت‌ادمین** دارید که با فرمت **Maildir** ذخیره
شده است. مشکل اینجاست که Thunderbird و افزونهٔ ImportExportTools NG فقط
فرمت **mbox** را می‌شناسند و Maildir را قبول نمی‌کنند.

این پروژه دو راه‌حل می‌دهد:

| مسیر | چطور کار می‌کند | نیاز |
|---|---|---|
| **A** | Maildir را به mbox تبدیل می‌کند | فقط ویندوز |
| **B** | یک سرور IMAP واقعی روی Maildir بالا می‌آورد | Docker + مجازی‌سازی |

**در هر دو حالت، فایل‌های بکاپ اصلی شما دست‌نخورده باقی می‌مانند.**

---

## ۲. کدام مسیر مال شماست؟

این را در **PowerShell** اجرا کنید:

```powershell
systeminfo | findstr /i "Hyper-V"
```

یا ساده‌تر: **Task Manager** را باز کنید → تب **Performance** → روی
**CPU** کلیک کنید → به خط **Virtualization** نگاه کنید.

| نتیجه | مسیر پیشنهادی |
|---|---|
| `Virtualization: Enabled` | **مسیر B** (کامل‌تر) — ولی مسیر A هم کار می‌کند |
| `Virtualization: Disabled` | اول [فعالش کنید](NO-VIRTUALIZATION.md)، وگرنه **مسیر A** |
| اصلاً نمایش داده نمی‌شود | **مسیر A** — تنها گزینه |

> 💡 **اگر عجله دارید یا فقط می‌خواهید ایمیل‌ها را بخوانید، مسیر A را
> انتخاب کنید.** حدود ۵ دقیقه طول می‌کشد و هیچ پیش‌نیازی ندارد.

---

# مسیر A — بدون Docker

**نیاز:** فقط ویندوز. PowerShell از قبل نصب است.
**نتیجه:** فایل‌های `.mbox` که در Thunderbird باز می‌شوند.
**زمان:** حدود ۵ دقیقه.

## گام A1 — پروژه را دانلود کنید

اگر Git دارید:

```powershell
cd /d D:\
git clone https://github.com/amolnovin/maildir-archive-server.git
cd maildir-archive-server
```

اگر Git ندارید: به صفحهٔ
<https://github.com/amolnovin/maildir-archive-server> بروید، دکمهٔ سبز
**Code** → **Download ZIP** را بزنید و در جایی مثل
`D:\maildir-archive-server` اکسترکت کنید.

> ⚠️ مسیر را جایی بگذارید که **فاصله و حرف فارسی نداشته باشد**.
> `D:\maildir-archive-server` خوب است، `D:\بکاپ ایمیل\` مشکل‌ساز می‌شود.

## گام A2 — بکاپ را آماده کنید

**لازم نیست بکاپ را دستی اکسترکت کنید.** اسکریپت فایل فشرده را مستقیم
قبول می‌کند:

- `.tar.gz` (فرمت معمول دایرکت‌ادمین)
- `.tgz` ، `.tar` ، `.tar.zst` ، `.zip`

پس می‌توانید همان فایلی را که از هاست دانلود کرده‌اید بدهید:

```
D:\mail\backup-Feb-09-2026-1.tar.gz
```

اگر ترجیح می‌دهید دستی اکسترکت کنید، ساختار باید این شکل باشد:

```
D:\backup\extracted\
    imap\
        komajsaba.com\
            info\
                Maildir\
                    cur\      ← ایمیل‌های خوانده‌شده
                    new\      ← ایمیل‌های خوانده‌نشده
                    .Sent\    ← ارسال‌شده‌ها
                    .Trash\
```

اگر پوشهٔ `imap` را دیدید، درست پیش رفته‌اید.

## گام A3 — تبدیل کنید

روی این فایل **دابل‌کلیک** کنید:

```
convert-to-mbox.bat
```

مسیر بکاپ را می‌پرسد. دو راه دارید:

- مسیر را تایپ یا paste کنید، مثلاً `D:\mail\backup-Feb-09-2026-1.tar.gz`
- یا **فایل را بکشید و روی پنجرهٔ CMD رها کنید** (ساده‌تر)

هم فایل `.tar.gz` و هم پوشهٔ اکسترکت‌شده قبول است.

سپس Enter بزنید. برای بکاپ‌های بزرگ ممکن است چند دقیقه طول بکشد.

خروجی در پوشهٔ `mbox-export` ساخته می‌شود:

```
mbox-export\
    info_komajsaba_com\
        INBOX.mbox
        Sent.mbox
        Trash.mbox
        Archive.2024.mbox
    sales_komajsaba_com\
        ...
```

## گام A4 — در Thunderbird وارد کنید

۱. Thunderbird را باز کنید.

۲. اگر افزونهٔ **ImportExportTools NG** را ندارید:
   منوی ☰ → **Add-ons and Themes** → جستجوی `ImportExportTools NG` →
   **Add to Thunderbird**.

۳. در ستون سمت راست روی **Local Folders** راست‌کلیک کنید.

۴. **ImportExportTools NG** → **Import mbox file**

۵. گزینهٔ **«Import directly one or more mbox files»** را انتخاب کنید.

۶. به پوشهٔ `mbox-export\...` بروید و فایل‌های `.mbox` را انتخاب کنید
   (می‌توانید همه را با Ctrl+A انتخاب کنید).

۷. OK بزنید. حالا ایمیل‌ها زیر Local Folders ظاهر می‌شوند.

## ✅ تمام

حالا می‌توانید همهٔ ایمیل‌ها را بخوانید، جستجو کنید و پیوست‌ها را باز کنید.

**چه چیزهایی حفظ شده است:**

- متن کامل و پیوست‌ها
- موضوع‌های فارسی
- وضعیت خوانده‌شده / خوانده‌نشده
- علامت ستاره و پاسخ‌داده‌شده
- ساختار پوشه‌ها

---

# مسیر B — با Docker

**نیاز:** Docker Desktop + مجازی‌سازی فعال.
**نتیجه:** سرور IMAP واقعی — قابل اتصال از Thunderbird، Outlook و موبایل.
**زمان:** ۱۵ تا ۳۰ دقیقه (بار اول).

## گام B1 — پیش‌نیازها

**۱. مجازی‌سازی** باید فعال باشد. (بخش ۲ بالا را ببینید.)

**۲. WSL2** را نصب کنید. در **PowerShell با دسترسی Administrator**:

```powershell
wsl --install
```

سپس **ویندوز را ری‌استارت کنید**.

**۳. Docker Desktop** را نصب کنید:
<https://www.docker.com/products/docker-desktop/>

بعد از نصب، Docker Desktop را باز کنید و صبر کنید تا در گوشهٔ پایین-چپ
بنویسد **«Engine running»**.

**۴. بررسی کنید:**

```powershell
docker run --rm hello-world
```

اگر پیام خوش‌آمد چاپ شد، آماده‌اید.

> اگر اینجا خطا گرفتید، روی `check-docker.bat` دابل‌کلیک کنید تا مشکل را
> تشخیص دهد. برای خطای «سرویس متوقف است» روی `fix-docker.bat`
> **راست‌کلیک → Run as administrator** بزنید.

## گام B2 — سرور را بالا بیاورید

روی این فایل دابل‌کلیک کنید:

```
start.bat
```

بار اول چند دقیقه طول می‌کشد چون image ساخته می‌شود. در پایان باید ببینید:

```
[OK] Server is up.
  IMAP        : localhost:143  (STARTTLS)
  Web Panel   : http://localhost:8080
```

## گام B3 — دامنه را بسازید

در **PowerShell**، داخل پوشهٔ پروژه:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Add-Domain.ps1 -Domain komajsaba.com
```

## گام B4 — بکاپ را وارد کنید

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Import-DirectAdminBackup.ps1 `
    -Source "D:\backup\user.admin.komajsaba.tar.gz" `
    -CreateAccounts -DefaultPassword "Archive2026!"
```

این دستور:
- بکاپ را اکسترکت می‌کند (فایل `tar.gz` را مستقیم قبول می‌کند)
- همهٔ mailboxها را پیدا و کپی می‌کند
- برای هرکدام یک اکانت با رمز داده‌شده می‌سازد

> 💡 اول با `-WhatIfOnly` امتحان کنید تا فقط ببینید داخل بکاپ چیست:
> ```powershell
> powershell -ExecutionPolicy Bypass -File scripts\Import-DirectAdminBackup.ps1 -Source "D:\backup\x.tar.gz" -WhatIfOnly
> ```

## گام B5 — نتیجه را ببینید

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Get-Mailboxes.ps1
```

یا در مرورگر: <http://localhost:8080>

## گام B6 — Thunderbird را وصل کنید

**Account Settings** → **Account Actions** → **Add Mail Account** →
**Configure manually**

| فیلد | مقدار |
|---|---|
| Protocol | IMAP |
| Server | `localhost` |
| Port | `143` |
| Connection security | `STARTTLS` |
| Authentication | Normal password |
| Username | آدرس کامل ایمیل، مثلاً `info@komajsaba.com` |
| Password | همان رمزی که در گام B4 دادید |
| Outgoing (SMTP) | ندارد — این سرور فقط آرشیو است |

اگر هشدار گواهی دید، **Confirm Security Exception** را بزنید.

جزئیات بیشتر و تنظیمات Outlook: [`THUNDERBIRD-OUTLOOK.md`](THUNDERBIRD-OUTLOOK.md)

---

## ۵. هر فایل چه کاری می‌کند؟

### فایل‌هایی که روی آن‌ها دابل‌کلیک می‌کنید

| فایل | کار |
|---|---|
| `convert-to-mbox.bat` | ⭐ **مسیر A** — تبدیل Maildir به mbox، بدون Docker |
| `start.bat` | **مسیر B** — راه‌اندازی سرور |
| `stop.bat` | توقف سرور (ایمیل‌ها پاک نمی‌شوند) |
| `logs.bat` | نمایش لاگ زندهٔ کانتینرها |
| `check-docker.bat` | 🔍 عیب‌یابی Docker — وقتی چیزی کار نمی‌کند |
| `fix-docker.bat` | 🔧 تعمیر سرویس Docker (**Run as administrator**) |
| `start-debug.bat` | اجرا + ذخیرهٔ لاگ کامل در `start-log.txt` |
| `git-push.bat` | فرستادن تغییرات به گیت‌هاب |

### فایل‌های حالت WSL

اگر Docker را داخل WSL نصب کرده‌اید (بدون Docker Desktop):

| فایل | کار |
|---|---|
| `install-docker-wsl.sh` | نصب Docker Engine داخل WSL |
| `start-wsl.bat` | راه‌اندازی در حالت WSL |
| `stop-wsl.bat` | توقف در حالت WSL |
| `logs-wsl.bat` | لاگ‌ها در حالت WSL |

### اسکریپت‌های مدیریتی (`scripts\`)

همه را با این الگو اجرا کنید:
`powershell -ExecutionPolicy Bypass -File scripts\<نام> <پارامترها>`

| اسکریپت | کار |
|---|---|
| `Convert-MaildirToMbox.ps1` | موتور تبدیل mbox (همان که `convert-to-mbox.bat` صدا می‌زند) |
| `Import-DirectAdminBackup.ps1` | وارد کردن بکاپ دایرکت‌ادمین |
| `Add-Domain.ps1` | افزودن دامنه |
| `Add-User.ps1` | ساخت اکانت یا تغییر رمز |
| `Remove-User.ps1` | حذف اکانت |
| `Get-Mailboxes.ps1` | گزارش حجم و تعداد پیام‌ها |
| `Backup-Archive.ps1` | بکاپ کامل آرشیو |
| `Restore-Archive.ps1` | بازگردانی بکاپ |
| `Export-Mbox.ps1` | خروجی mbox از سرور در حال اجرا |
| `Common.ps1` | توابع مشترک — مستقیم اجرا نکنید |

### پوشه‌ها

| پوشه | محتوا |
|---|---|
| `mail\` | 📧 **ایمیل‌های شما** — `<دامنه>\<کاربر>\Maildir\` |
| `mbox-export\` | خروجی مسیر A |
| `backup\` | بکاپ‌های ساخته‌شده |
| `docker\` | Dockerfile و تنظیمات Dovecot |
| `scripts\` | اسکریپت‌های PowerShell |
| `webpanel\` | پنل تحت وب |
| `docs\` | همین مستندات |
| `certs\` | گواهی SSL (خودکار ساخته می‌شود) |

### فایل‌هایی که نباید دست بزنید

| فایل | چرا |
|---|---|
| `_start-main.bat` | منطق داخلی `start.bat` |
| `.gitattributes` | پایان خط فایل‌ها را کنترل می‌کند — تغییرش پروژه را خراب می‌کند |
| `.gitignore` | جلوی آپلود شدن ایمیل‌ها و رمزها به گیت‌هاب را می‌گیرد |
| `docker-compose.yml` | تعریف سرویس‌ها |
| `.env.example` | الگوی تنظیمات — `start.bat` از رویش `.env` می‌سازد |

---

## ۶. کارهای روزمره

### افزودن دامنهٔ دوم

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Add-Domain.ps1 -Domain shekar-shekan.com
powershell -ExecutionPolicy Bypass -File scripts\Import-DirectAdminBackup.ps1 -Source "D:\backup\shekar.tar.gz" -OnlyDomain shekar-shekan.com -CreateAccounts
```

### تغییر رمز یک اکانت

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Add-User.ps1 -Email info@komajsaba.com -Password "NewPass123!"
```

### تغییر پورت (وقتی پورت اشغال است)

فایل `.env` را باز کنید:

```
IMAP_PORT=1143
IMAPS_PORT=1993
PANEL_PORT=8081
```

سپس `stop.bat` و دوباره `start.bat`.

### گرفتن بکاپ از آرشیو

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Backup-Archive.ps1
```

### وب‌میل (اختیاری)

```powershell
docker compose --profile webmail up -d
```

سپس <http://localhost:8000>

### فرستادن تغییرات به گیت‌هاب

دابل‌کلیک روی `git-push.bat` یا:

```powershell
git-push.bat "توضیح تغییر"
```

---

## ۷. مشکل دارید؟

| علامت | راه‌حل |
|---|---|
| پنجرهٔ `start.bat` سریع بسته می‌شود | `start-debug.bat` را اجرا کنید و `start-log.txt` را بخوانید |
| `Virtualization support not detected` | [`NO-VIRTUALIZATION.md`](NO-VIRTUALIZATION.md) — یا مسیر A |
| `Docker Desktop is unable to start` | [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) |
| سرویس Docker متوقف (کد ۱۰۷۷) | `fix-docker.bat` را **Run as administrator** کنید |
| پورت ۱۴۳ اشغال است | در `.env` پورت‌ها را عوض کنید |
| پوشه‌ها در Thunderbird دیده نمی‌شوند | راست‌کلیک روی حساب → **Subscribe** |
| اسکریپت PowerShell اجرا نمی‌شود | `powershell -ExecutionPolicy Bypass -File ...` |

### مستندات کامل

| سند | موضوع |
|---|---|
| [`NO-VIRTUALIZATION.md`](NO-VIRTUALIZATION.md) | وقتی مجازی‌سازی نیست + راهنمای mbox |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | همهٔ خطاهای شناخته‌شده و راه‌حلشان |
| [`INSTALL.md`](INSTALL.md) | نصب گام‌به‌گام Docker |
| [`THUNDERBIRD-OUTLOOK.md`](THUNDERBIRD-OUTLOOK.md) | تنظیمات کلاینت‌ها |
| [`DOCKER-WITHOUT-DESKTOP.md`](DOCKER-WITHOUT-DESKTOP.md) | Docker سبک داخل WSL |
| [`GIT-WORKFLOW.md`](GIT-WORKFLOW.md) | کار با گیت‌هاب |
| [`TESTING.md`](TESTING.md) | چه چیزهایی تست شده است |

---

## 🔒 چند نکتهٔ امنیتی

- این سرور برای **استفادهٔ محلی** طراحی شده. آن را روی اینترنت باز نکنید.
- فایل `docker\dovecot\users` شامل hash رمزهاست و در گیت آپلود نمی‌شود.
- پوشهٔ `mail\` هم در گیت نیست — ایمیل‌های شما خصوصی می‌مانند.
- قبل از public کردن ریپازیتوری، `git ls-files` بگیرید و مطمئن شوید
  چیز حساسی داخلش نیست.
