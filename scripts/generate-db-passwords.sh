#!/bin/bash
#
# generate-db-passwords.sh
#
# Recovery helper for when the scaffold/*.settings.php files contain
# PLACEHOLDER DB passwords. For each of the 14 sites it:
#   - generates a fresh strong password (160-bit, hex)
#   - writes it into scaffold/<site>.settings.php (as the esn-hungary user)
#   - adds an ALTER USER statement to a private SQL file
#
# It does NOT connect to MySQL and never prints a password. You run the
# generated SQL file yourself with the CloudPanel master credentials, then
# run run-scaffold.sh to push the scaffold files into the live settings.php.
#
# Safety:
#   - read-only checks on all 14 files first; nothing changes if any fails
#   - timestamped backup of scaffold/ before any edit
#   - every edit is verified by re-reading the file; on any failure the
#     backup is restored and the SQL file is deleted
#
# Usage (as webmaster):
#   bash generate-db-passwords.sh

set -euo pipefail
if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: run this as webmaster WITHOUT sudo (it calls sudo itself where needed)." >&2
  exit 1
fi

CODEBASE="${CODEBASE:-/home/esn-hungary/htdocs/new-hungary.esn.hu}"
OUT="${OUT:-/home/webmaster/alter-users.sql}"
DRUPAL_USER="${DRUPAL_USER:-esn-hungary}"
EXPECTED=14

command -v php >/dev/null     || { echo "ERROR: php CLI not found" >&2; exit 1; }
command -v openssl >/dev/null || { echo "ERROR: openssl not found" >&2; exit 1; }

umask 077
cd "$CODEBASE"

shopt -s nullglob
FILES=(scaffold/*.settings.php)
if [ "${#FILES[@]}" -ne "$EXPECTED" ]; then
  echo "ERROR: expected $EXPECTED scaffold settings files, found ${#FILES[@]}" >&2
  exit 1
fi

# --- PHP helpers (contain no secrets, so they are made world-readable so
#     that the esn-hungary user can run the rewrite helper) ---------------
PHP_READ=$(mktemp)
PHP_REWRITE=$(mktemp)
BACKUP=""
cleanup() { rm -f "$PHP_READ" "$PHP_REWRITE"; }
trap cleanup EXIT

cat > "$PHP_READ" <<'PHP'
<?php
// Prints "username<TAB>password" for the default DB in a settings file.
$app_root = '/';
$site_path = 'sites/x';
$settings = [];
$config = [];
$databases = [];
@include $argv[1];
$d = $databases['default']['default'] ?? [];
if (empty($d['username']) || !isset($d['password'])) {
  fwrite(STDERR, "no DB credentials found\n");
  exit(1);
}
echo $d['username'], "\t", $d['password'], "\n";
PHP

cat > "$PHP_REWRITE" <<'PHP'
<?php
// usage: php rewrite.php FILE [check]
// Replaces the value of the single 'password' => '...' line in FILE with
// the new password read from STDIN. With "check", only verifies that
// exactly one such line exists and changes nothing.
$file = $argv[1];
$check = ($argv[2] ?? '') === 'check';
$src = @file_get_contents($file);
if ($src === false) { fwrite(STDERR, "cannot read $file\n"); exit(3); }
$re = '/([\'"]password[\'"]\s*=>\s*)([\'"])[^\'"]*\2/';
$n = preg_match_all($re, $src);
if ($n !== 1) { fwrite(STDERR, "expected exactly 1 password line, found $n\n"); exit(4); }
if ($check) { exit(0); }
$new = trim(stream_get_contents(STDIN));
if (!preg_match('/^[A-Za-z0-9]{32,}$/', $new)) { fwrite(STDERR, "bad password input\n"); exit(2); }
$out = preg_replace($re, '${1}${2}' . $new . '${2}', $src, 1);
$tmp = $file . '.tmp';
if (file_put_contents($tmp, $out) === false) { exit(5); }
chmod($tmp, fileperms($file) & 0777);
if (!rename($tmp, $file)) { exit(6); }
PHP

chmod 644 "$PHP_READ" "$PHP_REWRITE"

run_as_drupal_user() { sudo -u "$DRUPAL_USER" "$@"; }

fail() {
  echo "ERROR: $1" >&2
  rm -f "$OUT"
  if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
    echo "Restoring scaffold/ from $BACKUP ..." >&2
    run_as_drupal_user cp -a "$BACKUP"/. scaffold/
    echo "Restored." >&2
  else
    echo "Nothing was changed." >&2
  fi
  exit 1
}

# --- Phase 1: read-only checks ------------------------------------------
echo "Phase 1: checking all $EXPECTED scaffold files (read-only)..."
for F in "${FILES[@]}"; do
  LINE=$(php "$PHP_READ" "$F") || fail "$F: could not read DB credentials"
  DBUSER="${LINE%%$'\t'*}"
  [[ "$DBUSER" == *DbUser ]] || fail "$F: unexpected DB user name '$DBUSER'"
  php "$PHP_REWRITE" "$F" check || fail "$F: password line check failed"
done
echo "  all files OK"

# --- Phase 2: backup ----------------------------------------------------
BACKUP="scaffold.bak-$(date +%Y%m%d-%H%M%S)"
echo "Phase 2: backing up scaffold/ to $BACKUP ..."
run_as_drupal_user cp -a scaffold "$BACKUP"
BACKUP="$CODEBASE/$BACKUP"

# --- Phase 3: generate, write, verify -----------------------------------
echo "Phase 3: generating passwords and updating scaffold files..."
: > "$OUT"
for F in "${FILES[@]}"; do
  LINE=$(php "$PHP_READ" "$F") || fail "$F: could not read DB credentials"
  DBUSER="${LINE%%$'\t'*}"
  NEW=$(openssl rand -hex 20)

  printf '%s' "$NEW" | run_as_drupal_user php "$PHP_REWRITE" "$F" \
    || fail "$F: could not write new password"

  CHECK=$(php "$PHP_READ" "$F") || fail "$F: file unreadable after edit"
  [ "${CHECK#*$'\t'}" = "$NEW" ] || fail "$F: verification failed after edit"

  printf "ALTER USER '%s'@'%%' IDENTIFIED BY '%s';\n" "$DBUSER" "$NEW" >> "$OUT"
  printf '  %-36s %s\n' "$F" "$DBUSER"
done

LEFT=$(grep -n -i -E 'change_me|changeme|placeholder|your_' scaffold/*.settings.php | cut -d: -f1,2 || true)

echo
echo "OK: updated 14 scaffold files; wrote $OUT (mode $(stat -c %a "$OUT"), $(wc -l < "$OUT") statements)."
echo "Backup of the previous scaffold files: $BACKUP"
if [ -n "$LEFT" ]; then
  echo
  echo "NOTE: other placeholder-looking lines remain (file:line) - review them:"
  echo "$LEFT" | sed 's/^/  /'
fi
echo
echo "Next:"
echo "  1. sudo clpctl db:show:master-credentials   (copy the connect command)"
echo "  2. run that connect command with the file piped in:"
echo "       <connect command> < $OUT"
echo "  3. shred -u $OUT"
echo "  4. sudo bash /home/webmaster/scripts/run-scaffold.sh"
