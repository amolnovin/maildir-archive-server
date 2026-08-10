<?php
/**
 * Maildir Archive Server — پنل مدیریت ساده
 * فقط خواندنی: نمایش دامنه‌ها، اکانت‌ها، حجم، تعداد پیام و جستجو در Maildir.
 */
declare(strict_types=1);

/* --- سازگاری: image رسمی php:cli-alpine افزونه mbstring را ندارد --- */
if (!function_exists('mb_internal_encoding')) {
    function mb_internal_encoding(?string $e = null) { return true; }
    function mb_strtolower(string $s): string {
        // حروف فارسی/عربی حالت بزرگ و کوچک ندارند؛ ASCII کافی است
        return strtolower($s);
    }
    function mb_strpos(string $h, string $n, int $o = 0) { return strpos($h, $n, $o); }
    function mb_substr(string $s, int $start, ?int $len = null): string {
        $chars = preg_split('//u', $s, -1, PREG_SPLIT_NO_EMPTY);
        if ($chars === false) {
            return $len === null ? substr($s, $start) : substr($s, $start, $len);
        }
        $slice = $len === null ? array_slice($chars, $start) : array_slice($chars, $start, $len);
        return implode('', $slice);
    }
}
mb_internal_encoding('UTF-8');

define('MAIL_ROOT',  getenv('MAS_MAIL_ROOT')  ?: '/srv/mail');
define('USERS_FILE', getenv('MAS_USERS_FILE') ?: '/etc/dovecot/users');

function human(int $b): string {
    $u = ['B','KB','MB','GB','TB']; $i = 0;
    while ($b >= 1024 && $i < 4) { $b /= 1024; $i++; }
    return round((float)$b, 2) . ' ' . $u[$i];
}

function dirStats(string $path): array {
    $size = 0; $count = 0;
    if (!is_dir($path)) return [0, 0];
    $it = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($path, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::LEAVES_ONLY
    );
    foreach ($it as $f) {
        if (!$f->isFile()) continue;
        $size += $f->getSize();
        $parent = basename(dirname($f->getPathname()));
        if ($parent === 'cur' || $parent === 'new') $count++;
    }
    return [$size, $count];
}

function knownAccounts(): array {
    $out = [];
    if (!is_readable(USERS_FILE)) return $out;
    foreach (file(USERS_FILE, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (str_starts_with(trim($line), '#')) continue;
        $out[] = strtolower(explode(':', $line)[0]);
    }
    return $out;
}

function listMailboxes(): array {
    $rows = [];
    if (!is_dir(MAIL_ROOT)) return $rows;
    foreach (scandir(MAIL_ROOT) ?: [] as $d) {
        if ($d[0] === '.' || !is_dir(MAIL_ROOT . "/$d")) continue;
        foreach (scandir(MAIL_ROOT . "/$d") ?: [] as $u) {
            if ($u[0] === '.' || !is_dir(MAIL_ROOT . "/$d/$u")) continue;
            $md = MAIL_ROOT . "/$d/$u/Maildir";
            [$size, $count] = dirStats($md);
            $rows[] = ['domain'=>$d, 'user'=>$u, 'email'=>"$u@$d", 'size'=>$size, 'count'=>$count, 'path'=>$md];
        }
    }
    usort($rows, fn($a,$b) => [$a['domain'],$a['user']] <=> [$b['domain'],$b['user']]);
    return $rows;
}

/** جستجوی ساده در هدرهای Subject/From فایل‌های Maildir */
function searchMail(string $q, string $emailFilter = ''): array {
    $hits = [];
    $q = mb_strtolower($q);
    foreach (listMailboxes() as $mb) {
        if ($emailFilter && $mb['email'] !== $emailFilter) continue;
        if (!is_dir($mb['path'])) continue;
        $it = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($mb['path'], FilesystemIterator::SKIP_DOTS));
        foreach ($it as $f) {
            if (!$f->isFile()) continue;
            $parent = basename(dirname($f->getPathname()));
            if ($parent !== 'cur' && $parent !== 'new') continue;
            $fh = fopen($f->getPathname(), 'r');
            if (!$fh) continue;
            $head = fread($fh, 8192) ?: '';
            fclose($fh);
            $headerPart = explode("\r\n\r\n", $head)[0];
            if (mb_strpos(mb_strtolower($headerPart), $q) === false) continue;
            preg_match('/^Subject:\s*(.+)$/mi', $headerPart, $s);
            preg_match('/^From:\s*(.+)$/mi', $headerPart, $fr);
            preg_match('/^Date:\s*(.+)$/mi', $headerPart, $dt);
            $hits[] = [
                'email'   => $mb['email'],
                'folder'  => basename(dirname(dirname($f->getPathname()))),
                'subject' => trim($s[1]  ?? '(بدون موضوع)'),
                'from'    => trim($fr[1] ?? ''),
                'date'    => trim($dt[1] ?? ''),
            ];
            if (count($hits) >= 200) return $hits;
        }
    }
    return $hits;
}

$q      = trim((string)($_GET['q'] ?? ''));
$filter = trim((string)($_GET['mailbox'] ?? ''));
$rows   = listMailboxes();
$known  = knownAccounts();
$results = $q !== '' ? searchMail($q, $filter) : [];
$totalSize = array_sum(array_column($rows, 'size'));
$totalMsg  = array_sum(array_column($rows, 'count'));
?>
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Maildir Archive Server — پنل مدیریت</title>
<style>
  :root { --bg:#0f172a; --card:#1e293b; --line:#334155; --txt:#e2e8f0; --mut:#94a3b8; --acc:#38bdf8; --ok:#4ade80; --warn:#fbbf24; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--txt); font-family:Tahoma,"Segoe UI",sans-serif; font-size:14px; }
  header { background:var(--card); border-bottom:1px solid var(--line); padding:18px 24px; }
  h1 { margin:0; font-size:19px; }
  .sub { color:var(--mut); font-size:12px; margin-top:4px; }
  .wrap { max-width:1100px; margin:24px auto; padding:0 16px; }
  .cards { display:flex; gap:14px; flex-wrap:wrap; margin-bottom:22px; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:10px; padding:14px 18px; min-width:150px; flex:1; }
  .card .n { font-size:24px; font-weight:bold; color:var(--acc); }
  .card .l { color:var(--mut); font-size:12px; margin-top:2px; }
  table { width:100%; border-collapse:collapse; background:var(--card); border-radius:10px; overflow:hidden; }
  th,td { padding:10px 12px; text-align:right; border-bottom:1px solid var(--line); }
  th { background:#172033; color:var(--mut); font-weight:normal; font-size:12px; }
  tr:last-child td { border-bottom:none; }
  .badge { padding:2px 8px; border-radius:20px; font-size:11px; }
  .b-ok { background:rgba(74,222,128,.15); color:var(--ok); }
  .b-no { background:rgba(251,191,36,.15); color:var(--warn); }
  form.search { display:flex; gap:8px; margin-bottom:20px; flex-wrap:wrap; }
  input,select,button { background:#0b1220; border:1px solid var(--line); color:var(--txt); padding:9px 12px; border-radius:8px; font-family:inherit; }
  button { background:var(--acc); color:#04263a; font-weight:bold; cursor:pointer; border:none; }
  h2 { font-size:15px; margin:26px 0 10px; }
  code { background:#0b1220; padding:2px 6px; border-radius:5px; color:var(--acc); }
  .empty { color:var(--mut); padding:18px; background:var(--card); border-radius:10px; }
</style>
</head>
<body>
<header>
  <h1>📬 Maildir Archive Server</h1>
  <div class="sub">آرشیو محلی بکاپ‌های Maildir دایرکت‌ادمین — دسترسی IMAP بدون تبدیل به mbox</div>
</header>

<div class="wrap">
  <div class="cards">
    <div class="card"><div class="n"><?= count(array_unique(array_column($rows,'domain'))) ?></div><div class="l">دامنه</div></div>
    <div class="card"><div class="n"><?= count($rows) ?></div><div class="l">Mailbox</div></div>
    <div class="card"><div class="n"><?= number_format($totalMsg) ?></div><div class="l">پیام</div></div>
    <div class="card"><div class="n"><?= human($totalSize) ?></div><div class="l">حجم کل</div></div>
  </div>

  <form class="search" method="get">
    <input type="text" name="q" placeholder="جستجو در Subject / From ..." value="<?= htmlspecialchars($q) ?>" style="flex:1;min-width:220px">
    <select name="mailbox">
      <option value="">همه mailboxها</option>
      <?php foreach ($rows as $r): ?>
        <option value="<?= htmlspecialchars($r['email']) ?>" <?= $filter===$r['email']?'selected':'' ?>><?= htmlspecialchars($r['email']) ?></option>
      <?php endforeach; ?>
    </select>
    <button type="submit">جستجو</button>
  </form>

  <?php if ($q !== ''): ?>
    <h2>نتایج جستجو (<?= count($results) ?><?= count($results)>=200 ? '+' : '' ?>)</h2>
    <?php if (!$results): ?>
      <div class="empty">نتیجه‌ای پیدا نشد.</div>
    <?php else: ?>
      <table>
        <tr><th>Mailbox</th><th>پوشه</th><th>موضوع</th><th>فرستنده</th><th>تاریخ</th></tr>
        <?php foreach ($results as $h): ?>
          <tr>
            <td><?= htmlspecialchars($h['email']) ?></td>
            <td><?= htmlspecialchars($h['folder']) ?></td>
            <td><?= htmlspecialchars(mb_substr($h['subject'],0,80)) ?></td>
            <td><?= htmlspecialchars(mb_substr($h['from'],0,45)) ?></td>
            <td style="white-space:nowrap"><?= htmlspecialchars(mb_substr($h['date'],0,25)) ?></td>
          </tr>
        <?php endforeach; ?>
      </table>
    <?php endif; ?>
  <?php endif; ?>

  <h2>Mailboxها</h2>
  <?php if (!$rows): ?>
    <div class="empty">
      هنوز هیچ mailbox ای وجود ندارد. بکاپ را import کنید:<br><br>
      <code>powershell -File scripts\Import-DirectAdminBackup.ps1 -Source "C:\backup\user.tar.gz" -CreateAccounts</code>
    </div>
  <?php else: ?>
  <table>
    <tr><th>ایمیل</th><th>دامنه</th><th>پیام</th><th>حجم</th><th>اکانت IMAP</th></tr>
    <?php foreach ($rows as $r): $has = in_array($r['email'], $known, true); ?>
      <tr>
        <td><?= htmlspecialchars($r['email']) ?></td>
        <td><?= htmlspecialchars($r['domain']) ?></td>
        <td><?= number_format($r['count']) ?></td>
        <td><?= human($r['size']) ?></td>
        <td><span class="badge <?= $has?'b-ok':'b-no' ?>"><?= $has?'فعال':'بدون رمز' ?></span></td>
      </tr>
    <?php endforeach; ?>
  </table>
  <?php endif; ?>

  <h2>تنظیمات اتصال کلاینت</h2>
  <table>
    <tr><th>پارامتر</th><th>مقدار</th></tr>
    <tr><td>سرور IMAP</td><td><code>localhost</code></td></tr>
    <tr><td>پورت</td><td><code>143</code> STARTTLS &nbsp;|&nbsp; <code>993</code> SSL/TLS</td></tr>
    <tr><td>نام کاربری</td><td>آدرس کامل ایمیل</td></tr>
    <tr><td>احراز هویت</td><td>Normal password</td></tr>
    <tr><td>SMTP</td><td>ندارد — این سرور فقط آرشیو است</td></tr>
  </table>
</div>
</body>
</html>
