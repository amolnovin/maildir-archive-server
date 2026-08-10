# نصب Docker بدون Docker Desktop (سبک‌تر)

اگر Docker Desktop را حذف کرده‌اید یا نمی‌خواهید از آن استفاده کنید، می‌توانید
**Docker Engine** را مستقیماً داخل WSL2 نصب کنید. این روش:

| | Docker Desktop | Docker Engine در WSL |
|---|---|---|
| مصرف RAM | ~۲ گیگابایت | ~۳۰۰ مگابایت |
| رابط گرافیکی | دارد | ندارد (فقط خط فرمان) |
| سرویس ویندوز | دارد (منبع خطای ۱۰۷۷) | ندارد |
| لایسنس تجاری | برای شرکت‌های بزرگ پولی | رایگان (Apache 2.0) |
| سرعت بالا آمدن | کند | سریع |

---

## پیش‌نیاز: WSL2

شما قبلاً WSL را نصب کرده‌اید (`wsl --status` نسخهٔ ۲ را نشان می‌دهد). اما
برای نصب Docker به یک **توزیع لینوکس** هم نیاز دارید، نه فقط خود WSL.

بررسی کنید که توزیعی نصب است:

```powershell
wsl --list --verbose
```

اگر فهرست خالی بود یا پیام «no installed distributions» دیدید، اوبونتو را
نصب کنید:

```powershell
wsl --install -d Ubuntu
```

ویندوز از شما یک نام کاربری و رمز لینوکسی می‌خواهد. آن رمز را یادداشت کنید؛
برای `sudo` لازم است.

> اگر `wsl --list --online` هم کار نکرد، اول `wsl --update` را بزنید.

---

## نصب خودکار (توصیه‌شده)

۱. توزیع WSL خود را باز کنید. در CMD یا PowerShell:

```powershell
wsl
```

۲. به پوشهٔ پروژه بروید. درایوهای ویندوز زیر `/mnt/` هستند:

```bash
cd /mnt/d/maildir-archive-server
```

> مسیر را با محل واقعی پروژه جایگزین کنید. `D:\...` می‌شود `/mnt/d/...`

۳. اسکریپت نصب را اجرا کنید:

```bash
bash install-docker-wsl.sh
```

این اسکریپت پنج کار انجام می‌دهد:

1. **systemd** را در `/etc/wsl.conf` فعال می‌کند تا daemon خودکار بالا بیاید
2. **Docker Engine** را از `get.docker.com` نصب می‌کند
3. افزونهٔ **Docker Compose v2** را بررسی/نصب می‌کند
4. کاربر شما را به گروه **docker** اضافه می‌کند (تا `sudo` لازم نباشد)
5. سرویس Docker را استارت و فعال می‌کند

۴. بعد از پایان، WSL را ری‌استارت کنید. در **PowerShell ویندوز**:

```powershell
wsl --shutdown
```

۵. دوباره WSL را باز کنید و تست کنید:

```bash
docker run --rm hello-world
```

اگر پیام خوش‌آمد چاپ شد، کار تمام است.

---

## نصب دستی (اگر ترجیح می‌دهید)

داخل WSL:

```bash
# ۱) فعال کردن systemd
sudo tee -a /etc/wsl.conf <<'EOF'

[boot]
systemd=true
EOF

# ۲) نصب Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# ۳) اجرای docker بدون sudo
sudo usermod -aG docker $USER

# ۴) فعال کردن خودکار
sudo systemctl enable --now docker
```

سپس در PowerShell ویندوز `wsl --shutdown` و دوباره باز کردن WSL.

---

## اجرای پروژه

از این به بعد به‌جای `start.bat` از فایل‌های نسخهٔ WSL استفاده کنید:

| کار | فایل |
|---|---|
| اجرا | `start-wsl.bat` |
| توقف | `stop-wsl.bat` |
| لاگ‌ها | `logs-wsl.bat` |

این‌ها را می‌توانید مثل قبل در ویندوز دابل‌کلیک کنید.

یا مستقیماً از داخل WSL:

```bash
cd /mnt/d/maildir-archive-server
docker compose up -d --build
```

سپس `http://localhost:8080` را باز کنید.

---

## ⚠️ نکتهٔ فنی مهم: چرا compose باید داخل WSL اجرا شود؟

فایل `docker-compose.yml` از مسیرهای نسبی استفاده می‌کند:

```yaml
volumes:
  - ./mail:/srv/mail
```

اگر daemon داخل WSL باشد ولی `docker compose` را از **ویندوز** اجرا کنید،
مسیر `./mail` به شکل `D:\...` تفسیر می‌شود که daemon لینوکسی آن را
نمی‌شناسد و bind mount خراب می‌شود (پوشهٔ خالی سوار می‌شود و ایمیل‌ها
دیده نمی‌شوند).

به همین دلیل `start-wsl.bat` مسیر را با `wslpath` ترجمه می‌کند و
`docker compose` را **داخل WSL** اجرا می‌کند. اگر دستی کار می‌کنید،
همیشه از داخل WSL اجرا کنید.

---

## اسکریپت‌های PowerShell

اسکریپت‌های `scripts\*.ps1` از دستور `docker exec` استفاده می‌کنند. در این
حالت (daemon داخل WSL) دستور `docker` در ویندوز وجود ندارد، پس:

**راه ساده:** همان کارها را از داخل WSL انجام دهید:

```bash
# ساخت کاربر
docker exec mas-dovecot doveadm pw -s SHA512-CRYPT -p 'YourPassword'

# فهرست mailboxها
docker exec mas-dovecot doveadm mailbox list -u info@komajsaba.com

# بازسازی ایندکس
docker exec mas-dovecot doveadm force-resync -A '*'
```

**برای import بکاپ:** فایل‌ها را مستقیماً در پوشهٔ `mail\` کپی کنید:

```
mail\komajsaba.com\info\Maildir\
```

سپس رمز را با `doveadm pw` بسازید و به `docker\dovecot\users` اضافه کنید:

```
info@komajsaba.com:{SHA512-CRYPT}$6$....:5000:5000::/srv/mail/komajsaba.com/info
```

> فایل `users` باید پایان خط **LF** و بدون **BOM** باشد.

**یا:** اگر می‌خواهید اسکریپت‌های PowerShell دقیقاً مثل قبل کار کنند،
می‌توانید Docker CLI ویندوزی را هم نصب کنید (بخش بعد).

---

## اختیاری: دستور docker در خود ویندوز

اگر می‌خواهید `docker` در CMD/PowerShell هم کار کند:

۱. daemon داخل WSL را روی TCP باز کنید (فقط روی localhost):

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/tcp.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2375
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

۲. باینری Docker CLI ویندوزی را دانلود کنید از
   <https://download.docker.com/win/static/stable/x86_64/> ، فایل
   `docker.exe` را در جایی مثل `C:\docker\` قرار دهید و آن پوشه را به
   PATH اضافه کنید.

۳. در PowerShell:

```powershell
[System.Environment]::SetEnvironmentVariable('DOCKER_HOST','tcp://127.0.0.1:2375','User')
```

> ⚠️ هشدار امنیتی: پورت ۲۳۷۵ بدون رمز و بدون TLS است. حتماً روی
> `127.0.0.1` محدودش کنید (نه `0.0.0.0`)، وگرنه هر کسی در شبکه به Docker
> شما دسترسی root پیدا می‌کند.

---

## عیب‌یابی

### `Cannot connect to the Docker daemon`

```bash
sudo service docker start
# یا اگر systemd فعال است:
sudo systemctl start docker
```

اگر گفت «System has not been booted with systemd»، یعنی `/etc/wsl.conf`
اعمال نشده. محتوایش را چک کنید و از ویندوز `wsl --shutdown` بزنید.

### `permission denied while trying to connect to the Docker daemon socket`

عضویت در گروه `docker` هنوز اعمال نشده:

```powershell
wsl --shutdown
```

سپس WSL را دوباره باز کنید.

### `iptables: No chain/target/match by that name` (بیشتر در Debian)

```bash
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo service docker restart
```

### daemon بعد از هر ری‌استارت خاموش است

یعنی systemd فعال نیست. بررسی کنید:

```bash
ps -p 1 -o comm=
```

باید `systemd` چاپ کند. اگر `init` بود، `/etc/wsl.conf` را درست کنید و
`wsl --shutdown` بزنید.

### سرعت پایین

پروژه را داخل فایل‌سیستم خود WSL بگذارید (مثلاً `~/maildir-archive-server`)
نه روی `/mnt/d/`. دسترسی به درایوهای ویندوز از WSL کند است.

اما توجه: در آن صورت پوشهٔ `mail\` از ویندوز مستقیم قابل دسترسی نیست و
باید از مسیر `\\wsl$\Ubuntu\home\<user>\...` در File Explorer باز شود.
