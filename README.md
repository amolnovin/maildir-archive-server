# 📬 Maildir Archive Server

سرور آرشیو ایمیل محلی مبتنی بر **Docker + Dovecot** برای استفادهٔ مستقیم از بکاپ‌های **Maildir** دایرکت‌ادمین — **بدون تبدیل به mbox**.

بکاپ را داخل پروژه import می‌کنید، Docker را بالا می‌آورید و همهٔ ایمیل‌ها از طریق **Thunderbird / Outlook / موبایل / وب‌میل** با پروتکل IMAP قابل دسترسی می‌شوند.

> این پروژه پاسخ عملی به مشکل «ImportExportTools NG فقط mbox دارد و Maildir ندارد» است: به‌جای تبدیل فرمت، خودِ Maildir را با یک سرور IMAP واقعی سرو می‌کنیم. هیچ ایمیلی بازنویسی یا تبدیل نمی‌شود.

---

# 👉 [از اینجا شروع کنید — راهنمای کامل گام‌به‌گام](docs/START-HERE.md)

اگر بار اول است که این پروژه را استفاده می‌کنید، فقط روی لینک بالا کلیک
کنید. آنجا از صفر تا خواندن ایمیل‌ها در Thunderbird توضیح داده شده است.

**خلاصهٔ خیلی کوتاه:**

| وضعیت سیستم شما | چه کار کنید |
|---|---|
| Docker کار نمی‌کند یا مجازی‌سازی ندارید | دابل‌کلیک روی `convert-to-mbox.bat` |
| Docker سالم است | دابل‌کلیک روی `start.bat` |

---

## چرا این روش؟

| روش | مشکل |
|---|---|
| تبدیل Maildir → mbox | کند، حجیم، احتمال خرابی فلگ‌ها و انکودینگ، از دست رفتن ساختار پوشه‌ها |
| آپلود دوباره روی هاست | نیاز به هاست فعال، ترافیک، هزینه، ریسک روی سرور زنده |
| **Dovecot لوکال روی Maildir** | ✅ صفر تبدیل، ✅ سریع، ✅ دقیقاً همان چیزی که در بکاپ است، ✅ آفلاین |

---

## ریپازیتوری

<https://github.com/amolnovin/maildir-archive-server>

```powershell
git clone https://github.com/amolnovin/maildir-archive-server.git
```

برای فرستادن تغییرات: `git-push.bat`
راهنمای کامل: [`docs/GIT-WORKFLOW.md`](docs/GIT-WORKFLOW.md)

---

## اگر Docker روی سیستم شما کار نمی‌کند

اگر خطای **«Virtualization support not detected»** می‌گیرید، مجازی‌سازی در
BIOS خاموش است یا CPU پشتیبانی نمی‌کند. در آن حالت **هیچ** ابزار کانتینری
(Docker، Podman، Rancher، WSL2) کار نمی‌کند.

راه‌حل بدون هیچ مجازی‌سازی — تبدیل مستقیم بکاپ به mbox و خواندن در
Thunderbird:

```powershell
.\convert-to-mbox.bat
```

راهنمای کامل: [`docs/NO-VIRTUALIZATION.md`](docs/NO-VIRTUALIZATION.md)

---

## وضعیت تست

اجزای حیاتی این پروژه روی **Dovecot 2.4.1 واقعی** اجرا و تست شده‌اند:
ورود IMAP/IMAPS/STARTTLS/POP3، خط لولهٔ کامل import یک بکاپ دایرکت‌ادمین،
backup/restore، خروجی mbox و پنل وب. جزئیات و فهرست باگ‌های رفع‌شده در
[`docs/TESTING.md`](docs/TESTING.md).

---

## پیش‌نیازها

- **Docker** — یکی از این دو:
  - **Docker Desktop** — [download](https://www.docker.com/products/docker-desktop/) (ساده‌تر، ولی سنگین)
  - یا **Docker Engine داخل WSL** — سبک‌تر و بدون سرویس ویندوز.
    راهنما: [`docs/DOCKER-WITHOUT-DESKTOP.md`](docs/DOCKER-WITHOUT-DESKTOP.md)
- **WSL2** — پیش‌نیاز Docker Desktop روی ویندوز است. بدون آن موتور Docker
  بالا نمی‌آید و `start.bat` خطای timeout می‌دهد. برای نصب/به‌روزرسانی،
  در PowerShell با دسترسی **Administrator**:
  ```powershell
  wsl --install --no-distribution
  wsl --update
  ```
  سپس ویندوز را **ری‌استارت** کنید.
- **PowerShell 5.1** یا بالاتر (روی ویندوز از پیش نصب است)
- فضای دیسک تقریباً برابر با حجم بکاپ‌ها

---

## شروع سریع (۵ دقیقه)

```powershell
# ۰) اگر مطمئن نیستید Docker سالم است:
.\check-docker.bat

# ۱) اجرای سرور
.\start.bat

# ۲) افزودن دامنه
powershell -ExecutionPolicy Bypass -File scripts\Add-Domain.ps1 -Domain komajsaba.com

# ۳) Import بکاپ دایرکت‌ادمین (فایل tar.gz یا پوشهٔ extract شده)
powershell -ExecutionPolicy Bypass -File scripts\Import-DirectAdminBackup.ps1 `
    -Source "D:\backups\user.admin.komaj.tar.gz" `
    -CreateAccounts -DefaultPassword "Archive2026!"

# ۴) مشاهدهٔ نتیجه
powershell -ExecutionPolicy Bypass -File scripts\Get-Mailboxes.ps1
# یا پنل وب:  http://localhost:8080
```

سپس در Thunderbird حساب جدید بسازید:

| فیلد | مقدار |
|---|---|
| Server | `localhost` |
| Protocol | IMAP |
| Port | `143` با STARTTLS (یا `993` با SSL/TLS) |
| Username | آدرس کامل ایمیل، مثلاً `info@komajsaba.com` |
| Password | رمزی که در مرحلهٔ ۳ تعیین کردید |
| Authentication | Normal password |
| SMTP | ندارد — می‌توانید SMTP را «هیچ‌کدام» بگذارید |

> اگر گواهی self-signed هشدار داد، در Thunderbird گزینهٔ **Confirm Security Exception** را بزنید. برای دور زدن کامل هشدار، از پورت `143` با `STARTTLS` یا `Connection security: None` استفاده کنید.

---

## ساختار پروژه

```
maildir-archive-server/
├── docker-compose.yml            # Dovecot + پنل وب + Roundcube (پروفایل webmail)
├── .env.example                  # پورت‌ها و تنظیمات محیطی
├── start.bat                     # اجرای سرور (پوستهٔ محافظ)
├── _start-main.bat               # منطق واقعی راه‌اندازی
├── start-debug.bat               # اجرا + ذخیرهٔ لاگ کامل در start-log.txt
├── stop.bat / logs.bat
├── check-docker.bat              # عیب‌یابی Docker وقتی موتور بالا نمی‌آید
├── fix-docker.bat                # تعمیر خودکار سرویس Docker (Run as administrator)
├── convert-to-mbox.bat           # ⭐ تبدیل به mbox بدون Docker/مجازی‌سازی
├── git-push.bat                  # commit و push تغییرات به گیت‌هاب
├── run-script.bat                # اجرای اسکریپت‌ها بدون خطای ExecutionPolicy
├── install-docker-wsl.sh         # نصب Docker Engine داخل WSL (بدون Docker Desktop)
├── start-wsl.bat / stop-wsl.bat / logs-wsl.bat   # اجرا در حالت WSL
├── docker/
│   ├── Dockerfile                # Alpine + Dovecot
│   ├── entrypoint.sh             # ساخت خودکار گواهی SSL لوکال
│   └── dovecot/
│       ├── dovecot.conf
│       ├── users                 # کاربران (توسط اسکریپت‌ها مدیریت می‌شود)
│       └── conf.d/
│           ├── 10-auth.conf
│           ├── 10-ssl.conf
│           ├── 10-master.conf
│           └── 20-imap.conf
├── scripts/
│   ├── Common.ps1                # توابع مشترک
│   ├── Add-Domain.ps1
│   ├── Add-User.ps1
│   ├── Remove-User.ps1
│   ├── Get-Mailboxes.ps1         # حجم و تعداد پیام هر mailbox
│   ├── Import-DirectAdminBackup.ps1
│   ├── Backup-Archive.ps1
│   ├── Restore-Archive.ps1
│   └── Export-Mbox.ps1           # خروجی mbox برای Thunderbird
├── webpanel/index.php            # پنل تحت وب (فهرست، حجم، جستجو)
├── mail/                         # ← Maildirها اینجا قرار می‌گیرند
│   └── <domain>/<user>/Maildir/
├── backup/                       # خروجی بکاپ‌ها و mboxها
├── certs/                        # گواهی SSL اختیاری (mail.crt / mail.key)
└── docs/
    ├── START-HERE.md              # ⭐ راهنمای کامل از صفر
    ├── INSTALL.md
    ├── THUNDERBIRD-OUTLOOK.md
    ├── TROUBLESHOOTING.md
    ├── DOCKER-WITHOUT-DESKTOP.md
    ├── NO-VIRTUALIZATION.md
    ├── GIT-WORKFLOW.md
    └── TESTING.md
```

---

## ساختار Maildir مورد انتظار

بکاپ دایرکت‌ادمین معمولاً این شکل است:

```
backup.tar.gz
└── imap/
    └── komajsaba.com/
        ├── info/Maildir/{cur,new,tmp,.Sent,.Drafts,.Trash,...}
        └── sales/Maildir/...
```

اسکریپت Import به‌صورت خودکار پوشهٔ `imap/` را پیدا می‌کند. اگر ساختار متفاوت بود، همین‌طور پوشه‌هایی به نام `Maildir` را جست‌وجو می‌کند.

نتیجه در پروژه:

```
mail/komajsaba.com/info/Maildir/...
```

---

## دستورهای پرکاربرد

```powershell
# پیش‌نمایش بدون کپی (فقط ببین چه چیزی داخل بکاپ است)
scripts\Import-DirectAdminBackup.ps1 -Source "D:\b.tar.gz" -WhatIfOnly

# فقط یک دامنهٔ خاص
scripts\Import-DirectAdminBackup.ps1 -Source "D:\b.tar.gz" -OnlyDomain komajsaba.com

# ساخت/تغییر رمز یک اکانت
scripts\Add-User.ps1 -Email info@komajsaba.com -Password "NewPass!"

# گزارش حجم و تعداد پیام
scripts\Get-Mailboxes.ps1 -Domain komajsaba.com

# بکاپ کامل آرشیو
scripts\Backup-Archive.ps1

# بازگردانی
scripts\Restore-Archive.ps1 -ZipPath "backup\mas-full-20260806-120000.zip"

# خروجی mbox برای Thunderbird
scripts\Export-Mbox.ps1 -Email info@komajsaba.com -Mailbox "INBOX.Sent"
```

---

## افزودن دامنهٔ بعدی

```powershell
scripts\Add-Domain.ps1 -Domain shekar-shekan.com
scripts\Import-DirectAdminBackup.ps1 -Source "D:\backups\shekar.tar.gz" -OnlyDomain shekar-shekan.com -CreateAccounts
```

هیچ تغییری در پیکربندی Dovecot لازم نیست؛ چیدمان `%d/%n` چند دامنه را به‌صورت خودکار پشتیبانی می‌کند.

---

## وب‌میل (اختیاری)

```powershell
docker compose --profile webmail up -d
# http://localhost:8000
```

---

## نکات فنی مهم

- پیکربندی برای **Dovecot 2.4** نوشته شده و `Dockerfile` روی `alpine:3.22`
  پین شده است. تغییر آن به Alpine ۳.۲۰ باعث نصب Dovecot 2.3 و خطای
  پیکربندی می‌شود.
- فایل `subscriptions` نباید پیشوند `INBOX.` داشته باشد (چون
  `prefix = INBOX.` در تنظیمات فعال است). اسکریپت‌ها این را رعایت می‌کنند.
- فایل `docker/dovecot/users` باید LF و بدون BOM باشد؛ اسکریپت‌ها همین‌طور
  می‌نویسند.

---

## نکات امنیتی

- این سرور برای **استفادهٔ لوکال/آفلاین** طراحی شده است. آن را مستقیماً روی اینترنت expose نکنید.
- اگر لازم شد روی هاست اجرا شود: پورت‌ها را پشت VPN یا فایروال ببندید، `disable_plaintext_auth = yes` کنید و گواهی معتبر در `certs/` بگذارید.
- فایل `docker/dovecot/users` شامل hash رمزهاست (SHA512-CRYPT) و در `.gitignore` قرار دارد.

---

## نسخهٔ ۲ (نقشهٔ راه)

- [ ] ساخت کاربر/دامنه از داخل پنل وب (نیازمند API)
- [ ] Import با یک کلیک از پنل
- [ ] Export به PST (از طریق `readpst`/`libpst`)
- [ ] REST API برای مدیریت کاربران
- [ ] نمایه‌سازی full-text با Solr برای جستجوی بدنهٔ ایمیل‌ها

---

**نسخه:** 1.0 · **مجوز:** MIT
