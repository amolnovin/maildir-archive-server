# وقتی مجازی‌سازی در دسترس نیست

اگر خطای زیر را می‌بینید:

```
Virtualization support not detected
```

این خطا **سخت‌افزاری/BIOS** است، نه مشکل Docker.

---

## ⚠️ اول یک واقعیت مهم

بدون مجازی‌سازی، **هیچ گزینهٔ کانتینری روی ویندوز کار نمی‌کند**:

| گزینه | نیاز به مجازی‌سازی؟ |
|---|---|
| Docker Desktop | ✅ بله (WSL2 یا Hyper-V) |
| Docker Engine در WSL | ✅ بله (خود WSL2) |
| Podman Desktop | ✅ بله (WSL2) |
| Rancher Desktop | ✅ بله (WSL2) |
| Colima / Lima | ✅ بله |
| Multipass | ✅ بله |

پس «جایگزین Docker» مشکل را حل نمی‌کند. یا باید مجازی‌سازی را فعال کنید،
یا از راهی استفاده کنید که اصلاً کانتینر نمی‌خواهد.

---

## راه ۱: فعال کردن مجازی‌سازی (اگر ممکن است)

### گام ۱ — بررسی پشتیبانی CPU

در PowerShell:

```powershell
Get-CimInstance Win32_Processor | Select-Object Name, VirtualizationFirmwareEnabled
systeminfo | findstr /i "Hyper-V"
```

یا ساده‌تر: **Task Manager → Performance → CPU** و به خط
«Virtualization» نگاه کنید.

سه حالت ممکن است:

| وضعیت | معنی |
|---|---|
| `Virtualization: Enabled` | فعال است — مشکل جای دیگری است (پایین را ببینید) |
| `Virtualization: Disabled` | در BIOS خاموش است — گام ۲ |
| اصلاً نمایش داده نمی‌شود | CPU پشتیبانی نمی‌کند یا Hyper-V آن را گرفته |

### گام ۲ — فعال کردن در BIOS/UEFI

ساده‌ترین راه ورود به BIOS در ویندوز ۱۰/۱۱:

**Settings → System → Recovery → Advanced startup → Restart now**
سپس: **Troubleshoot → Advanced options → UEFI Firmware Settings → Restart**

داخل BIOS دنبال یکی از این‌ها بگردید (نامش بسته به برند فرق می‌کند):

- Intel: **Intel Virtualization Technology** یا **Intel VT-x**
- AMD: **SVM Mode** یا **AMD-V**
- معمولاً در تب **Advanced**، **Configuration** یا **CPU Configuration**

فعالش کنید، **Save & Exit** بزنید و بگذارید ویندوز بالا بیاید.

### گام ۳ — فعال کردن ویژگی‌های ویندوز

PowerShell با دسترسی **Administrator**:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
bcdedit /set hypervisorlaunchtype auto
```

سپس **ری‌استارت**.

> نکته: اگر قبلاً کسی `bcdedit /set hypervisorlaunchtype off` را اجرا کرده
> باشد (مثلاً برای اجرای VMware یا بعضی بازی‌ها)، مجازی‌سازی در ویندوز
> خاموش می‌ماند حتی اگر در BIOS روشن باشد. دستور بالا آن را برمی‌گرداند.

### اگر همه‌چیز فعال است ولی باز هم خطا می‌دهد

- **آنتی‌چیت بازی‌ها** (مثل Vanguard در Valorant) و بعضی آنتی‌ویروس‌ها
  مجازی‌سازی را قفل می‌کنند. آن‌ها را موقتاً غیرفعال/حذف کنید.
- **VMware یا VirtualBox** همزمان با Hyper-V تداخل دارند.
- ویژگی‌ها را یک بار خاموش، ری‌استارت، دوباره روشن و ری‌استارت کنید.

### اگر CPU اصلاً پشتیبانی نمی‌کند

روی سیستم‌های قدیمی یا بعضی ماشین‌های مجازی (VPS بدون nested
virtualization) هیچ راهی نیست. سراغ راه ۲ بروید.

---

## راه ۲: بدون هیچ مجازی‌سازی — تبدیل مستقیم به mbox ✅

**این روش هدف اصلی شما را برآورده می‌کند: خواندن بکاپ در Thunderbird.**

نه Docker می‌خواهد، نه WSL، نه مجازی‌سازی. فقط PowerShell که در ویندوز
از پیش نصب است.

### استفاده

روی فایل زیر دابل‌کلیک کنید:

```
convert-to-mbox.bat
```

مسیر بکاپ را می‌پرسد (یا می‌توانید پوشه را روی فایل **بکشید و رها کنید**).

یا مستقیماً در PowerShell:

```powershell
.\scripts\Convert-MaildirToMbox.ps1 -Source "D:\backup\extracted"
```

فقط یک دامنه:

```powershell
.\scripts\Convert-MaildirToMbox.ps1 -Source "D:\backup\extracted" -OnlyDomain komajsaba.com
```

### خروجی

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

### وارد کردن در Thunderbird

۱. روی **Local Folders** راست‌کلیک کنید
۲. **ImportExportTools NG → Import mbox file**
۳. گزینهٔ **Import directly one or more mbox files** را بزنید
۴. فایل‌های `.mbox` را انتخاب کنید

تمام. حالا همهٔ ایمیل‌ها در Thunderbird قابل جستجو و مطالعه‌اند.

---

## چه چیزهایی حفظ می‌شود؟

| مورد | وضعیت |
|---|---|
| متن و هدر کامل پیام | ✅ بدون تغییر |
| پیوست‌ها (attachment) | ✅ بدون تغییر |
| موضوع فارسی / UTF-8 | ✅ سالم |
| وضعیت خوانده‌شده | ✅ از فلگ Maildir به `Status:` |
| پاسخ‌داده‌شده / ستاره‌دار | ✅ به `X-Status:` |
| ساختار پوشه‌ها | ✅ هر پوشه یک فایل mbox |
| پوشه‌های تودرتو (`.Archive.2024`) | ✅ به `Archive.2024.mbox` |
| پیام‌های خوانده‌نشده در `new/` | ✅ پردازش می‌شوند |

### جزئیات فنی رعایت‌شده

- **escape کردن `From `**: اگر خطی از متن ایمیل با `From ` شروع شود،
  در فرمت mbox باید به `>From ` تبدیل شود؛ وگرنه Thunderbird آن را
  ابتدای یک پیام جدید می‌فهمد و ایمیل‌ها تکه‌تکه می‌شوند.
- **حفظ بایت‌ها**: فایل‌ها با انکودینگ ۱:۱ خوانده می‌شوند، پس UTF-8 و
  هر انکودینگ دیگری بدون خرابی عبور می‌کند.
- **پایان خط**: خروجی همه‌جا CRLF است، بدون CR سرگردان.

---

## تست‌های انجام‌شده

این مبدل با داده‌های واقعی اجرا و اعتبارسنجی شده است:

- ✅ خروجی با پارسر استاندارد `mailbox` پایتون پارس شد
- ✅ **مقایسه با خروجی Dovecot 2.4.1 واقعی** — محتوای هر سه پوشه
  یکسان بود. تنها تفاوت: Dovecot یک پیام خالی اضافی
  («FOLDER INTERNAL DATA») تولید می‌کند که خروجی ما ندارد
- ✅ ۳۳ پیام در ۳ دامنه با پوشه‌های تودرتو: هر ۳۳ تا سالم منتقل شدند
- ✅ موضوع فارسی «سلام دنیا» درست decode شد
- ✅ خط `From the desk of Ali` درست escape شد
- ✅ فلگ‌ها: خوانده‌شده `Status: RO`، خوانده‌نشده `Status: O`،
  ستاره‌دار+پاسخ‌داده `X-Status: AF`
- ✅ پیام بدون هدر `Date` هم جداکنندهٔ معتبر گرفت
- ✅ صفر بایت CR سرگردان در خروجی

**نکتهٔ جالب:** در تست اول، Dovecot به‌خاطر ناهماهنگی اندازه در نام
فایل‌ها شکست خورد و پیام‌ها را از دست داد، در حالی که این اسکریپت همه را
درست استخراج کرد. یعنی در برابر بکاپ‌های خراب مقاوم‌تر است.

---

## محدودیت‌ها

- خروجی **فقط خواندنی** است. اگر در Thunderbird ایمیلی را حذف کنید،
  فایل اصلی Maildir دست‌نخورده می‌ماند (که خوب است — بکاپ شما امن است).
- برخلاف نسخهٔ Docker، سرور IMAP ندارید. یعنی نمی‌توانید از Outlook یا
  موبایل به آن وصل شوید. برای آرشیو و جستجو در Thunderbird کافی است.
- برای mailboxهای خیلی بزرگ (چند ده گیگ) تبدیل ممکن است چند دقیقه
  طول بکشد.

---

## اگر بعداً مجازی‌سازی فعال شد

پروژه دست‌نخورده باقی مانده. کافی است `start.bat` را اجرا کنید تا نسخهٔ
کامل با IMAP بالا بیاید. هر دو روش از یک بکاپ استفاده می‌کنند و با هم
تداخلی ندارند.
