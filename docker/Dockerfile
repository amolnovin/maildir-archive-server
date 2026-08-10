# Alpine 3.22 → Dovecot 2.4.1
# ⚠️ نسخه پین شده است. Alpine 3.20 نسخه Dovecot 2.3 دارد که نحو پیکربندی
#    آن با فایل‌های این پروژه (که برای ۲.۴ نوشته شده‌اند) سازگار نیست.
FROM alpine:3.22

LABEL org.opencontainers.image.title="Maildir Archive Server - Dovecot"
LABEL org.opencontainers.image.description="Dovecot IMAP برای آرشیو مستقیم بکاپ‌های Maildir دایرکت‌ادمین"

RUN apk add --no-cache \
        dovecot \
        dovecot-pop3d \
        dovecot-lmtpd \
        dovecot-pigeonhole-plugin \
        openssl \
        tzdata \
        bash \
        ca-certificates \
    && mkdir -p /srv/mail /srv/backup /var/run/dovecot

# کاربر یکتای سیستم برای همه mailboxها (vmail)
RUN addgroup -g 5000 vmail \
    && adduser -D -u 5000 -G vmail -h /srv/mail -s /sbin/nologin vmail

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# حذف CR در صورتی که فایل روی ویندوز به CRLF تبدیل شده باشد،
# وگرنه خطای "bad interpreter: no such file or directory" می‌گیریم.
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 143 993 110 995

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["dovecot", "-F"]
