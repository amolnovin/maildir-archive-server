# اتصال Thunderbird و Outlook

## Thunderbird

1. **Account Settings → Account Actions → Add Mail Account**
2. نام و ایمیل را وارد کنید، سپس **Configure manually** را بزنید.

| فیلد | مقدار |
|---|---|
| Incoming | IMAP |
| Hostname | `localhost` |
| Port | `143` |
| Connection security | `STARTTLS` (یا `None` اگر گواهی اذیت می‌کند) |
| Authentication | Normal password |
| Username | `info@komajsaba.com` (آدرس کامل) |
| Outgoing (SMTP) | این سرور SMTP ندارد؛ می‌توانید SMTP موجود دیگری انتخاب کنید یا خالی بگذارید |

3. **Re-test** → **Done**.
4. اگر هشدار گواهی دید: **Confirm Security Exception**.

### دیدن همهٔ پوشه‌ها

اگر بعضی پوشه‌ها دیده نمی‌شوند:
**راست‌کلیک روی حساب → Subscribe…** و پوشه‌های موردنظر را تیک بزنید.

### دانلود آفلاین همهٔ ایمیل‌ها

**Account Settings → Synchronization & Storage → Keep messages in all folders for this account on this computer**

### خروجی گرفتن به mbox (اگر واقعاً لازم شد)

حالا که پوشه‌ها در Thunderbird دیده می‌شوند، **ImportExportTools NG** به‌راحتی کار می‌کند:
راست‌کلیک روی پوشه → **ImportExportTools NG → Export folder** → mbox.
(همان چیزی که قبلاً چون Maildir پشتیبانی نمی‌شد ممکن نبود.)

---

## Outlook (2016 / 2019 / 2021 / 365)

1. **File → Add Account → Advanced setup → Let me set up my account manually**
2. نوع حساب: **IMAP**

| فیلد | مقدار |
|---|---|
| Incoming server | `localhost` |
| Incoming port | `993`، Encryption: **SSL/TLS** |
| Outgoing server | `localhost`، port `25` (استفاده نخواهد شد) |
| Username | آدرس کامل ایمیل |

3. اگر به‌خاطر گواهی self-signed خطا داد، دو راه دارید:
   - **راه ساده:** پورت `143` با Encryption = **None**.
   - **راه تمیز:** فایل `certs/mail.crt` را در ویندوز به **Trusted Root Certification Authorities** اضافه کنید:
     ```powershell
     Import-Certificate -FilePath .\certs\mail.crt -CertStoreLocation Cert:\LocalMachine\Root
     ```

> Outlook در برابر سرورهای IMAP بدون SMTP سخت‌گیر است. اگر اجازهٔ ساخت حساب نداد، یک SMTP الکی (`localhost:25`) وارد کنید و ارسال ایمیل را هرگز امتحان نکنید — این سرور فقط آرشیو خواندنی است.

---

## موبایل (اختیاری)

اگر گوشی روی همان شبکهٔ Wi-Fi است، به‌جای `localhost` از IP سیستم استفاده کنید:

```powershell
ipconfig | findstr IPv4
```

سپس در فایروال ویندوز پورت ۱۴۳/۹۹۳ را برای شبکهٔ خصوصی باز کنید.
