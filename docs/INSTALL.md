# راهنمای نصب گام‌به‌گام

## ۱. نصب Docker Desktop

1. از [docker.com](https://www.docker.com/products/docker-desktop/) دانلود و نصب کنید.
2. در حین نصب گزینهٔ **Use WSL 2 based engine** را فعال بگذارید.
3. بعد از نصب یک بار ویندوز را restart کنید.
4. Docker Desktop را باز کنید و صبر کنید تا آیکن آن سبز شود.

بررسی:

```powershell
docker version
docker compose version
```

## ۲. آماده‌سازی پروژه

پوشهٔ پروژه را در مسیری بدون فاصله و بدون کاراکتر فارسی قرار دهید، مثلاً:

```
D:\mail-archive\maildir-archive-server\
```

سپس:

```powershell
cd D:\mail-archive\maildir-archive-server
copy .env.example .env
```

اگر پورت ۱۴۳ یا ۹۹۳ روی سیستم شما اشغال است (مثلاً Exchange یا آنتی‌ویروس)، در `.env` تغییرشان دهید:

```
IMAP_PORT=1143
IMAPS_PORT=1993
```

بررسی اشغال بودن پورت:

```powershell
netstat -ano | findstr ":143"
```

## ۳. اجرای اولیه

```powershell
.\start.bat
```

اولین اجرا چند دقیقه طول می‌کشد چون image ساخته می‌شود. در پایان باید ببینید:

```
[OK] سرور بالا آمد.
```

بررسی سلامت:

```powershell
docker compose ps
docker compose logs dovecot --tail=40
```

## ۴. اجازهٔ اجرای اسکریپت‌های PowerShell

اگر خطای *running scripts is disabled* گرفتید:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

یا هر بار با پارامتر bypass اجرا کنید:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Add-User.ps1 -Email info@komajsaba.com
```

## ۵. Import بکاپ

### الف) بکاپ فشرده

```powershell
scripts\Import-DirectAdminBackup.ps1 -Source "D:\backups\user.admin.komaj.tar.gz" -CreateAccounts -DefaultPassword "Archive2026!"
```

### ب) بکاپ از قبل extract شده

```powershell
scripts\Import-DirectAdminBackup.ps1 -Source "D:\backups\extracted" -CreateAccounts
```

### ج) فقط پوشهٔ Maildir یک کاربر

اگر فقط یک `Maildir` دارید، آن را دستی در مسیر زیر بگذارید:

```
mail\komajsaba.com\info\Maildir\
```

و سپس:

```powershell
scripts\Add-User.ps1 -Email info@komajsaba.com -Password "Archive2026!"
```

## ۶. بازسازی ایندکس (برای آرشیوهای بزرگ)

```powershell
docker exec mas-dovecot doveadm index -A "*"
docker exec mas-dovecot doveadm force-resync -A "*"
```

## ۷. اتصال کلاینت

به `docs/THUNDERBIRD-OUTLOOK.md` مراجعه کنید.
