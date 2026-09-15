# عیب‌یابی

## کانتینر بالا نمی‌آید

```powershell
docker compose logs dovecot --tail=100
```

| پیام | علت | راه‌حل |
|---|---|---|
| `bind: address already in use` | پورت ۱۴۳/۹۹۳ اشغال است | در `.env` پورت‌ها را عوض کنید و `start.bat` را دوباره اجرا کنید |
| `Fatal: Error in configuration file` | خطای تایپی در conf | خط اشاره‌شده در لاگ را اصلاح کنید |
| `chown: Operation not permitted` | مشکل مجوز WSL | پوشهٔ پروژه را داخل درایو ویندوز (نه شبکه) بگذارید |

## ورود ناموفق (Authentication failed)

```powershell
docker exec mas-dovecot doveadm auth test info@komajsaba.com
```

- مطمئن شوید نام کاربری **آدرس کامل ایمیل** است، نه فقط `info`.
- فایل `docker/dovecot/users` نباید BOM یا پایان خط CRLF داشته باشد. اسکریپت‌های پروژه این را رعایت می‌کنند؛ اگر دستی ویرایش کردید با VS Code حالت **LF** ذخیره کنید.
- بعد از تغییر فایل کاربران: `docker exec mas-dovecot doveadm reload`

## پوشه‌ها خالی به نظر می‌رسند

```powershell
docker exec mas-dovecot doveadm mailbox list -u info@komajsaba.com
docker exec mas-dovecot doveadm force-resync -u info@komajsaba.com "*"
```

علت رایج: ایندکس‌های قدیمی Dovecot از سرور مبدأ. اسکریپت Import آن‌ها را حذف می‌کند، ولی اگر دستی کپی کرده‌اید:

```powershell
Get-ChildItem mail\ -Recurse -Include dovecot.index*,dovecot-uidlist,dovecot.mailbox.log | Remove-Item -Force
```

## پوشه‌ها در Thunderbird دیده نمی‌شوند

راست‌کلیک روی حساب → **Subscribe…** → تیک زدن پوشه‌ها.
یا فایل `subscriptions` را بررسی کنید:

```
mail\<domain>\<user>\Maildir\subscriptions
```

هر خط باید مثل `INBOX.Sent` باشد.

## کندی روی آرشیوهای خیلی بزرگ

- ایندکس‌ها را یک بار از پیش بسازید: `docker exec mas-dovecot doveadm index -A "*"`
- در Docker Desktop → Settings → Resources، حافظه را حداقل ۴ گیگ بدهید.
- پوشهٔ `mail/` را روی SSD بگذارید، نه HDD یا درایو شبکه.

## نام فایل‌های Maildir بعد از کپی در ویندوز خراب می‌شود

نام فایل‌های Maildir شامل `:` است (مثل `1234.M567:2,S`). NTFS با آن مشکل دارد اگر از ابزار اشتباه استفاده شود.

- ✅ `robocopy` (که اسکریپت استفاده می‌کند) و `tar` ویندوز درست عمل می‌کنند.
- ❌ کپی از داخل بعضی برنامه‌های آرشیو قدیمی ممکن است `:` را حذف کند.

اگر فلگ‌ها از بین رفت (همه چیز unread شد)، ایمیل‌ها سالم‌اند و فقط وضعیت خوانده‌شده از دست رفته است.


## خطای «The argument ... does not exist» هنگام اجرای اسکریپت

نمونهٔ خطا:

```
PS C:\Users\iMAN> powershell -File scripts\Import-DirectAdminBackup.ps1 ...
The argument 'scripts\Import-DirectAdminBackup.ps1' to the -File parameter
does not exist.
```

**علت:** شما در پوشهٔ پروژه نیستید. به ابتدای خط فرمان نگاه کنید:
`PS C:\Users\iMAN>` یعنی در پوشهٔ کاربری هستید، نه جایی که پروژه است.
مسیر `scripts\...` یک مسیر **نسبی** است و فقط از داخل پوشهٔ پروژه معنی
دارد.

### راه‌حل

اول با `cd` به پوشهٔ پروژه بروید:

```powershell
cd D:\maildir-archive-server
```

اگر پروژه روی درایو دیگری است، از سوییچ `/d` استفاده کنید (در CMD):

```
cd /d D:\maildir-archive-server
```

بررسی کنید که درست آمده‌اید:

```powershell
dir scripts\*.ps1
```

باید فهرست اسکریپت‌ها را ببینید. حالا دستور را اجرا کنید.

> 💡 راه ساده‌تر: در File Explorer وارد پوشهٔ پروژه شوید، در نوار آدرس
> کلمهٔ `powershell` را تایپ کنید و Enter بزنید. PowerShell دقیقاً در
> همان پوشه باز می‌شود.

### یا مسیر کامل بدهید

```powershell
powershell -ExecutionPolicy Bypass -File "D:\maildir-archive-server\scripts\Convert-MaildirToMbox.ps1" -Source "D:\mail\backup.tar.gz"
```

---

## Import-DirectAdminBackup می‌گوید کانتینر اجرا نیست

این اسکریپت **فقط برای حالت Docker** است. اگر Docker روی سیستم شما کار
نمی‌کند (مثلاً مجازی‌سازی ندارید)، از مبدل mbox استفاده کنید که هیچ
پیش‌نیازی ندارد:

```
convert-to-mbox.bat
```

این فایل هم `.tar.gz` و هم پوشهٔ اکسترکت‌شده را قبول می‌کند و خروجی‌اش
مستقیماً در Thunderbird قابل import است.

## سرویس Docker با کد ۱۰۷۷ متوقف است (رایج‌ترین حالت)

نشانه در خروجی `check-docker.bat` یا `start-log.txt`:

```
SERVICE_NAME: com.docker.service
        STATE              : 1  STOPPED
        WIN32_EXIT_CODE    : 1077  (0x435)
```

**معنی کد ۱۰۷۷:** `ERROR_SERVICE_NEVER_STARTED` — یعنی «از آخرین بوت
ویندوز، اصلاً هیچ تلاشی برای اجرای این سرویس انجام نشده است».

نکتهٔ مهم: سرویس تلاش نکرده و شکست نخورده؛ بلکه **اصلاً start نشده**.
معمولاً به این دلیل که نوع راه‌اندازی آن روی Manual است و Docker Desktop
دسترسی لازم برای استارت کردنش را نداشته است.

### راه‌حل خودکار (توصیه‌شده)

روی فایل زیر **راست‌کلیک** کنید و **Run as administrator** را بزنید:

```
fix-docker.bat
```

این اسکریپت شش کار انجام می‌دهد:

۱. وضعیت فعلی سرویس را نشان می‌دهد
۲. نوع راه‌اندازی را به **Automatic** تغییر می‌دهد
۳. سرویس را start می‌کند
۴. کاربر شما را به گروه **docker-users** اضافه می‌کند
۵. بک‌اند WSL را ریست می‌کند (`wsl --shutdown`)
۶. Docker Desktop را اجرا می‌کند

> اسکریپت خودش درخواست دسترسی Administrator می‌کند (UAC)، ولی اگر
> راست‌کلیک → Run as administrator بزنید مطمئن‌تر است.

### راه‌حل دستی

اگر ترجیح می‌دهید دستی انجام دهید، **PowerShell را با دسترسی
Administrator** باز کنید:

```powershell
sc.exe config com.docker.service start= auto
sc.exe start com.docker.service
net localgroup docker-users "$env:USERNAME" /add
wsl --shutdown
```

> دقت کنید: در PowerShell حتماً `sc.exe` بنویسید، نه `sc` — چون `sc` در
> PowerShell نام مستعار `Set-Content` است.

سپس Docker Desktop را باز کنید.

### بعد از اجرا

۱. صبر کنید تا Docker Desktop بنویسد «Engine running».

۲. **از ویندوز خارج شوید و دوباره وارد شوید** (sign out / sign in).
   این برای اعمال شدن عضویت در گروه `docker-users` لازم است.

۳. در یک ترمینال **جدید** تست کنید:
   ```powershell
   docker run --rm hello-world
   ```

۴. اگر پیام خوش‌آمد چاپ شد، `start.bat` را اجرا کنید.

### اگر باز هم سرویس بالا نیامد

- **مجازی‌سازی:** Task Manager → Performance → CPU → مقدار
  «Virtualization» باید **Enabled** باشد. اگر Disabled است، باید در
  BIOS/UEFI فعالش کنید (معمولاً با نام Intel VT-x یا AMD-V یا SVM).

- **تعمیر نصب:** Settings → Apps → Docker Desktop → Modify → **Repair**،
  سپس ری‌استارت.

- **بررسی لاگ ویندوز:** `Win+R` → `eventvwr.msc` → Windows Logs →
  Application، و دنبال خطاهای `com.docker.service` بگردید.

## خطای «Docker Desktop is unable to start» هنگام دانلود image

نمونهٔ خطا:

```
unable to get image 'php:8.3-cli-alpine':
Error response from daemon: Docker Desktop is unable to start
```

**این خطا ربطی به پورت یا به این پروژه ندارد.** یعنی سرویس Docker Desktop
پاسخ می‌دهد ولی موتور واقعی (backend) که داخل WSL2 اجرا می‌شود خراب است،
پس نمی‌تواند image دانلود کند.

> نکتهٔ فنی: در این حالت `docker info` ممکن است **exit code صفر** برگرداند
> ولی بخش `Server:` آن خطا داشته باشد. به همین دلیل اسکریپت‌های این پروژه
> فقط به exit code اکتفا نمی‌کنند و وجود رشتهٔ `Server Version` را بررسی
> می‌کنند.

### راه‌حل به ترتیب

**۱. ری‌استارت کامل موتور**

- روی آیکن نهنگ در tray راست‌کلیک → **Quit Docker Desktop** (فقط بستن پنجره کافی نیست).
- در PowerShell:
  ```powershell
  wsl --shutdown
  ```
- Docker Desktop را دوباره باز کنید و صبر کنید تا بنویسد «Engine running».

**۲. بررسی تنظیمات**

- Settings → General → گزینهٔ **«Use the WSL 2 based engine»** باید روشن باشد.
- Settings → Resources → **WSL integration** → توزیع خود را فعال کنید.

**۳. بازسازی ماشین WSL مربوط به Docker**

اگر باز هم کار نکرد:

```powershell
wsl --unregister docker-desktop
```

سپس Docker Desktop را باز کنید تا خودش دوباره بسازد.

> ⚠️ این کار همهٔ image‌ها و کانتینرهای لوکال را حذف می‌کند، اما
> **پوشهٔ `mail\` و ایمیل‌های شما دست‌نخورده می‌مانند** چون روی دیسک
> ویندوز ذخیره شده‌اند، نه داخل Docker.

**۴. آخرین راه‌حل**

Docker Desktop → آیکن حشره (Troubleshoot) → **Reset to factory defaults**.

**۵. تأیید**

```powershell
docker run --rm hello-world
```

اگر پیام خوش‌آمدگویی چاپ شد، موتور سالم است و می‌توانید `start.bat` را
اجرا کنید.

### اگر مشکل ادامه داشت

گاهی نسخهٔ خاصی از Docker Desktop با نسخهٔ WSL ناسازگار است. این را امتحان کنید:

```powershell
wsl --update
wsl --version
```

و در صورت لزوم Docker Desktop را به آخرین نسخه به‌روزرسانی کنید.

## سرویس Docker متوقف است و WSL نصب نیست (شایع‌ترین علت)

اگر `check-docker.bat` این دو نشانه را با هم داد:

```
[5] Docker Desktop service status:
        STATE              : 1  STOPPED

[7] WSL distributions:
    Usage: wsl.exe [Argument]      <-- به‌جای فهرست توزیع‌ها، راهنما چاپ شد
```

یعنی **WSL نصب یا به‌روز نیست**. موتور Docker Desktop روی ویندوز داخل WSL2
اجرا می‌شود، پس بدون آن سرویس بالا نمی‌آید و `docker info` تایم‌اوت می‌دهد.

نکتهٔ تشخیصی: اگر `wsl --list --verbose` به‌جای فهرست توزیع‌ها **متن راهنما**
چاپ کند، یعنی نسخهٔ WSL شما آن‌قدر قدیمی است که این سوییچ‌ها را نمی‌شناسد.

### راه‌حل

یک **PowerShell با دسترسی Administrator** باز کنید
(روی Start راست‌کلیک → Terminal (Admin) یا PowerShell (Admin)) و به ترتیب:

```powershell
wsl --install --no-distribution
wsl --update
```

سپس **ویندوز را ری‌استارت کنید**. این مرحله اختیاری نیست.

بعد از بالا آمدن:

```powershell
wsl --status
```

باید نسخه چاپ کند، نه متن راهنما.

سپس Docker Desktop را باز کنید و صبر کنید تا پایین-چپ بنویسد
«Engine running». در پایان:

```powershell
docker info
```

باید خط `Server Version:` داشته باشد. حالا `start.bat` را اجرا کنید.

### اگر ری‌استارت هم کمک نکرد

۱. مطمئن شوید مجازی‌سازی (Virtualization) در BIOS فعال است. در Task Manager
   → Performance → CPU، مقدار «Virtualization» باید Enabled باشد.

۲. این ویژگی‌های ویندوز را فعال کنید (PowerShell با دسترسی Administrator):
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
   سپس ری‌استارت کنید.

۳. سرویس را دستی استارت کنید: `Win+R` → `services.msc` →
   «Docker Desktop Service» → راست‌کلیک → Start.

## پنجره start.bat سریع باز و بسته می‌شود

از نسخهٔ فعلی، `start.bat` خودش را داخل یک پنجرهٔ `cmd /k` جدید باز می‌کند
که **هرگز به‌طور خودکار بسته نمی‌شود**. اگر باز هم بسته شد:

### راه‌حل قطعی: از start-debug.bat استفاده کنید

```
start-debug.bat
```

این فایل همه‌چیز را در `start-log.txt` کنار پروژه ذخیره می‌کند — شامل نسخهٔ
Docker، وضعیت سرویس، وضعیت WSL و کل خروجی اجرا. حتی اگر پنجره بسته شود،
فایل لاگ باقی می‌ماند و می‌توانید آن را بخوانید یا برای پشتیبانی بفرستید.

### یا از داخل CMD اجرا کنید

۱. `Win+R` → `cmd` → Enter
۲. به پوشهٔ پروژه بروید:
   ```
   cd /d "D:\mail-archive\maildir-archive-server"
   ```
۳. اجرا کنید:
   ```
   start.bat
   ```

چون پنجره از قبل باز بوده، بعد از پایان اسکریپت باز می‌ماند.

### علت فنی

وقتی روی یک فایل `.bat` دابل‌کلیک می‌کنید، ویندوز آن را با `cmd /c` اجرا
می‌کند. اگر داخل اسکریپت خطای مهلکی رخ دهد یا دستور `exit` (بدون `/b`)
اجرا شود، کل پنجرهٔ CMD فوراً بسته می‌شود و حتی `pause` هم اجرا نمی‌شود.
به همین دلیل منطق اصلی به `_start-main.bat` منتقل شد و `start.bat` فقط یک
پوستهٔ محافظ است.

> اگر آنتی‌ویروس اجرای `.bat` را مسدود کرده باشد هم همین رفتار را می‌بینید.
> در آن صورت پوشهٔ پروژه را در Windows Defender استثنا کنید.

## خطای «Docker Desktop is not running» با اینکه docker نصب است

اگر `docker --version` جواب می‌دهد ولی `start.bat` می‌گوید Docker اجرا نیست،
این تناقض نیست. دو دستور کاملاً متفاوت‌اند:

| دستور | چه چیزی را چک می‌کند | وقتی موتور خاموش است |
|---|---|---|
| `docker --version` | فقط شمارهٔ نسخهٔ **CLI** | ✅ کار می‌کند |
| `docker version` | ارتباط با **موتور (engine)** | ❌ خطا می‌دهد |

یعنی CLI شما نصب است، اما **موتور Docker در حال اجرا نیست** و تا وقتی بالا
نیاید هیچ کانتینری اجرا نمی‌شود.

### تشخیص

```
check-docker.bat
```

این فایل هفت مورد را بررسی می‌کند و خطای واقعی Docker، وضعیت سرویس و وضعیت
WSL را نشان می‌دهد.

یا دستی:

```
docker version
```

اگر خروجی فقط بخش `Client:` داشت و خط زیر را دید، موتور خاموش است:

```
error during connect: ... open //./pipe/docker_engine:
The system cannot find the file specified.
```

خروجی سالم **باید** بخش `Server:` هم داشته باشد.

### راه‌حل به ترتیب

۱. **Docker Desktop را باز کنید** و صبر کنید تا پایین-چپ پنجره بنویسد
   «Engine running» و آیکن نهنگ ثابت شود (نه متحرک). اولین اجرا بعد از
   ری‌استart ممکن است ۱ تا ۳ دقیقه طول بکشد.

۲. اگر روی «Docker Desktop starting...» گیر کرد، معمولاً مشکل از WSL2 است:
   ```
   wsl --update
   wsl --shutdown
   ```
   سپس Docker Desktop را دوباره باز کنید.

۳. **سرویس ویندوز** را چک کنید: `Win+R` → `services.msc` →
   «Docker Desktop Service» باید Running باشد. اگر نیست، راست‌کلیک → Start.

۴. اگر WSL اصلاً نصب نیست:
   ```
   wsl --install --no-distribution
   ```
   سپس ویندوز را ری‌استارت کنید.

۵. **تأیید نهایی** — این باید بخش `Server:` چاپ کند:
   ```
   docker version
   ```
   بعد از آن `start.bat` را اجرا کنید.

> نکته: Docker Desktop را حتماً باز نگه دارید. اگر پنجره‌اش را ببندید،
> بسته به تنظیمات ممکن است موتور هم خاموش شود. برای اجرای خودکار هنگام
> بوت: Settings → General → «Start Docker Desktop when you sign in».

## خطای «'طفا' is not recognized as an internal or external command»

اگر هنگام اجرای `start.bat` پیام‌هایی مثل موارد زیر دیدید:

```
'طفا' is not recognized as an internal or external command
'.env' is not recognized as an internal or external command
'er' is not recognized as an internal or external command
docker: unknown command: docker Compose
```

**علت:** فایل‌های `.bat` نباید متن فارسی داشته باشند.

CMD ویندوز فایل batch را بایت‌به‌بایت با **کدپیج سیستم** (مثلاً 437 یا 1256)
می‌خواند، نه UTF-8. دستور `chcp 65001` هم این را حل نمی‌کند، چون خطوط پیش از
اجرای آن پارس شده‌اند. در نتیجه بایت‌های فارسی خراب می‌شوند و بعضی از آن‌ها
به‌عنوان کاراکترهای ویژهٔ CMD (`&`، `|`، `<`، `>`) تفسیر می‌شوند. کاراکتر `&`
یعنی «دستور بعدی را اجرا کن»، پس یک خط `echo` فارسی به چند «دستور» ناموجود
تکه‌تکه می‌شود.

خطاهای `docker: unknown command` و `no configuration file provided` هم پیامد
همین خرابی هستند، نه مشکل واقعی Docker.

**راه‌حل:** از نسخهٔ فعلی پروژه استفاده کنید. فایل‌های `start.bat`،
`stop.bat` و `logs.bat` اکنون کاملاً **ASCII (انگلیسی)** هستند و این مشکل را
ندارند. پیام‌های فارسی در اسکریپت‌های PowerShell قرار دارند که UTF-8 را
درست پشتیبانی می‌کنند.

> قانون کلی: در فایل‌های `.bat` فقط انگلیسی بنویسید. برای خروجی فارسی از
> PowerShell استفاده کنید.

## پوشه‌های تکراری مثل «INBOX.INBOX.Sent» در Thunderbird

علت: در فایل `subscriptions` نام پوشه‌ها با پیشوند `INBOX.` نوشته شده است.
چون در `dovecot.conf` مقدار `prefix = INBOX.` تنظیم شده، Dovecot پیشوند را
دوباره اضافه می‌کند و نتیجه `INBOX.INBOX.Sent` می‌شود.

✅ درست:
```
INBOX
Sent
Drafts
Trash
```
❌ غلط:
```
INBOX
INBOX.Sent
```
اسکریپت‌های این پروژه فایل را درست می‌سازند؛ اگر دستی ویرایش کرده‌اید اصلاحش کنید.

## خطای «Cached message size larger than expected»

نام فایل‌های Maildir شامل اندازه پیام است (`,S=520`). اگر فایل بعد از کپی
تغییر کرده باشد یا نام دستی دستکاری شده باشد، این خطا رخ می‌دهد.

راه‌حل:
```powershell
docker exec mas-dovecot doveadm force-resync -A "*"
```

## خطای نسخه: «The first setting must be dovecot_config_version»

پیکربندی این پروژه برای **Dovecot 2.4** نوشته شده است. اگر image را به
Alpine 3.20 یا پایین‌تر تغییر داده باشید، Dovecot 2.3 نصب می‌شود که نحو
متفاوتی دارد. در `docker/Dockerfile` باید `FROM alpine:3.22` بماند.

تفاوت‌های کلیدی ۲.۳ → ۲.۴ که در این پروژه اعمال شده‌اند:

| Dovecot 2.3 | Dovecot 2.4 |
|---|---|
| `mail_location = maildir:/path` | `mail_driver = maildir` + `mail_path = /path` |
| `%d` / `%n` | `%{user \| domain}` / `%{user \| username}` |
| `passdb { driver = passwd-file args = ... }` | `passdb passwd-file { passwd_file_path = ... }` |
| `ssl_cert = </path` | `ssl_server_cert_file = /path` |
| `disable_plaintext_auth = no` | `auth_allow_cleartext = yes` |
| `service_count` در service | حذف شده |

## پاک کردن کامل و شروع دوباره

```powershell
.\stop.bat
docker compose down -v --rmi local
Remove-Item mail\* -Recurse -Force
.\start.bat
```

⚠️ این کار همهٔ ایمیل‌های import شده را حذف می‌کند. اول `Backup-Archive.ps1` بگیرید.
