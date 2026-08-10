#!/bin/bash
set -e

CERT_DIR=/etc/dovecot/certs
RUNTIME_CERT_DIR=/tmp/certs

# اگر گواهی SSL وجود نداشت، یک گواهی self-signed لوکال بساز
mkdir -p "$RUNTIME_CERT_DIR"
if [ -f "$CERT_DIR/mail.crt" ] && [ -f "$CERT_DIR/mail.key" ]; then
    cp "$CERT_DIR/mail.crt" "$RUNTIME_CERT_DIR/mail.crt"
    cp "$CERT_DIR/mail.key" "$RUNTIME_CERT_DIR/mail.key"
else
    echo "[entrypoint] گواهی پیدا نشد؛ ساخت گواهی self-signed ..."
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
        -keyout "$RUNTIME_CERT_DIR/mail.key" \
        -out "$RUNTIME_CERT_DIR/mail.crt" \
        -subj "/CN=${HOSTNAME:-mail.local}" >/dev/null 2>&1
fi
chmod 600 "$RUNTIME_CERT_DIR/mail.key"

# اطمینان از وجود فایل کاربران
if [ ! -f /etc/dovecot/users ]; then
    echo "[entrypoint] هشدار: /etc/dovecot/users وجود ندارد. هیچ کاربری تعریف نشده است."
fi

# اصلاح مالکیت پوشه mail (بدون تغییر ساختار Maildir)
chown -R vmail:vmail /srv/mail 2>/dev/null || true
chown -R vmail:vmail /srv/backup 2>/dev/null || true

echo "[entrypoint] Dovecot در حال اجرا ..."
exec "$@"
