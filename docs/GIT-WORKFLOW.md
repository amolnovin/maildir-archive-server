# کار با گیت‌هاب

ریپازیتوری پروژه:
<https://github.com/amolnovin/maildir-archive-server>

از این پس همهٔ تغییرات از طریق گیت‌هاب انجام می‌شود.

---

## نصب Git روی ویندوز

اگر `git --version` در CMD جواب نمی‌دهد، از اینجا نصب کنید:
<https://git-scm.com/download/win>

در حین نصب گزینه‌های پیش‌فرض مناسب‌اند. فقط این یکی مهم است:
**«Git from the command line and also from 3rd-party software»** را انتخاب
کنید تا `git` در CMD در دسترس باشد.

---

## گرفتن پروژه روی سیستم (بار اول)

```powershell
cd /d D:\
git clone https://github.com/amolnovin/maildir-archive-server.git
cd maildir-archive-server
```

> ⚠️ اگر از قبل پوشه‌ای با فایل‌های قدیمی دارید، آن را جای دیگری ببرید یا
> نامش را عوض کنید. پوشهٔ `mail\` خودتان را حتماً نگه دارید — بکاپ‌های
> شماست و در گیت نیست.

---

## گرفتن آخرین تغییرات

```powershell
git pull origin main
```

---

## فرستادن تغییرات

ساده‌ترین راه، دابل‌کلیک روی این فایل است:

```
git-push.bat
```

پیام commit را می‌پرسد، بعد `add` و `commit` و `push` را انجام می‌دهد.

یا با پیام مستقیم:

```powershell
git-push.bat "توضیح تغییر"
```

یا دستی:

```powershell
git add -A
git commit -m "توضیح تغییر"
git push origin main
```

---

## احراز هویت

گیت‌هاب رمز عبور حساب را قبول نمی‌کند. باید از **Personal Access Token**
استفاده کنید.

در اولین push ویندوز یک پنجره باز می‌کند و می‌پرسد:

| فیلد | مقدار |
|---|---|
| Username | `amolnovin` |
| Password | **توکن** (نه رمز حساب) |

ویندوز آن را در Credential Manager ذخیره می‌کند و دیگر نمی‌پرسد.

### ساخت توکن جدید

<https://github.com/settings/tokens>

- نوع **Fine-grained token** را انتخاب کنید
- در بخش Repository access فقط همین ریپازیتوری را انتخاب کنید
- در Permissions گزینهٔ **Contents: Read and write** را بدهید

> 🔒 **مهم:** توکن مثل رمز عبور است. آن را داخل هیچ فایلی از پروژه
> نگذارید و در URL ریموت هم قرارش ندهید، وگرنه در تاریخچهٔ گیت ثبت
> می‌شود و قابل حذف نیست.
>
> اگر توکنی جایی لو رفت، فوراً از همان صفحهٔ بالا **Revoke** کنید.

### پاک کردن توکن اشتباه ذخیره‌شده

Control Panel → Credential Manager → Windows Credentials →
مدخل `git:https://github.com` را حذف کنید.

---

## چه چیزهایی در گیت ذخیره نمی‌شوند

فایل `.gitignore` این‌ها را کنار می‌گذارد:

| مورد | چرا |
|---|---|
| `mail/*` | ایمیل‌های شخصی شما — نباید عمومی شوند |
| `backup/*` | بکاپ‌ها، حجیم و خصوصی |
| `.env` | تنظیمات محلی |
| `docker/dovecot/users` | شامل hash رمز عبور اکانت‌هاست |
| `certs/*.key` و `*.crt` | کلید و گواهی SSL |
| `*.log` | لاگ‌ها |

به‌جای `users` فایل `users.example` در ریپو هست که فقط قالب را نشان
می‌دهد.

> این یعنی می‌توانید ریپو را public بگذارید بدون اینکه ایمیل یا رمزی
> فاش شود. اما قبل از public کردن، یک بار `git ls-files` بگیرید و
> مطمئن شوید چیز حساسی داخلش نیست.

---

## نکتهٔ پایان خط (CRLF / LF)

فایل `.gitattributes` این را مدیریت می‌کند و **دست نزنید**:

- فایل‌های `.bat` باید **CRLF** بمانند، وگرنه CMD درست اجرایشان نمی‌کند
- فایل‌های `.sh` و `.conf` و `docker-compose.yml` باید **LF** بمانند،
  وگرنه کانتینر لینوکسی خطای `bad interpreter` می‌دهد

اگر git هشدار `LF will be replaced by CRLF` داد، طبیعی است و
`.gitattributes` جلوی خرابی را می‌گیرد.

---

## اگر push رد شد

### `Updates were rejected because the remote contains work`

یعنی روی گیت‌هاب کامیت جدیدتری هست:

```powershell
git pull --rebase origin main
git push origin main
```

### `Authentication failed`

توکن اشتباه یا منقضی است. توکن جدید بسازید و مدخل قدیمی را از
Credential Manager پاک کنید.

### `Permission denied` یا `403`

توکن دسترسی نوشتن ندارد. در تنظیمات توکن **Contents: Read and write**
را فعال کنید.

---

## بازگشت به نسخهٔ قبلی

دیدن تاریخچه:

```powershell
git log --oneline
```

برگرداندن یک فایل به نسخهٔ قبلی:

```powershell
git checkout <commit-hash> -- path\to\file
```

لغو همهٔ تغییرات محلی (⚠️ برگشت‌ناپذیر):

```powershell
git reset --hard origin/main
```
