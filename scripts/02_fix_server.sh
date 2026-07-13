#!/bin/bash
##############################################################################
# ESN Hungary — PRODUCTION Fix Server Script
# Run as: sudo bash /home/webmaster/scripts/02_fix_server.sh
##############################################################################
set -e

MAIN_USER="esn-hungary"
MAIN_HOME="/home/esn-hungary"
MAIN_ROOT="$MAIN_HOME/htdocs/new-hungary.esn.hu"

# Section CloudPanel users and their domains
declare -A SECTION_USERS
SECTION_USERS["new-bme.esn.hu"]="esn-new-bme"
SECTION_USERS["new-corvinus.esn.hu"]="esn-new-corvinus"
SECTION_USERS["new-debrecen.esn.hu"]="esn-new-debrecen"
SECTION_USERS["new-elte.esn.hu"]="esn-new-elte"
SECTION_USERS["new-eszterhazy.esn.hu"]="esn-new-eszterhazy"
SECTION_USERS["new-ibs.esn.hu"]="esn-new-ibs"
SECTION_USERS["mate.esn.hu"]="esn-mate"
SECTION_USERS["new-miskolc.esn.hu"]="esn-new-miskolc"
SECTION_USERS["new-obuda.esn.hu"]="esn-new-obuda"
SECTION_USERS["new-pecs.esn.hu"]="esn-new-pecs"
SECTION_USERS["semmelweis.esn.hu"]="esn-semmelweis"
SECTION_USERS["new-szeged.esn.hu"]="esn-new-szeged"
SECTION_USERS["lups.esn.hu"]="esn-lups"

ALL_DOMAINS="new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu lups.esn.hu"

echo "================================================"
echo " ESN Hungary — Step 2: Fix Server"
echo "================================================"

# ── PART 1 — Fix Nginx for all section sites ──────────────────────────────
echo ""
echo "[1/4] Fixing nginx configs for all section sites..."
for DOMAIN in "${!SECTION_USERS[@]}"; do
  CONF="/etc/nginx/sites-enabled/${DOMAIN}.conf"
  if [ -f "$CONF" ]; then
    sed -i "s|root .*;|root $MAIN_ROOT/web;|" "$CONF"
    echo "  ✓ Fixed nginx root for $DOMAIN"
  else
    echo "  ⚠️  No nginx config found for $DOMAIN — create site in CloudPanel first"
  fi
done
systemctl reload nginx
echo "✓ Nginx reloaded"

# ── PART 2 — Fix permissions ───────────────────────────────────────────────
echo ""
echo "[2/4] Fixing permissions..."

# Main codebase must be world-readable (all section nginx workers need it)
chmod o+x "$MAIN_HOME"
chmod o+x "$MAIN_HOME/htdocs"
chmod o+x "$MAIN_ROOT"
find "$MAIN_ROOT" -type d -exec chmod o+rx {} \;
find "$MAIN_ROOT" -type f -exec chmod o+r {} \;
find "$MAIN_ROOT/web/sites" -name "settings.php" -exec chmod 644 {} \;
echo "  ✓ Main codebase world-readable"

# Section user home dirs need to be executable by nginx
for DOMAIN in "${!SECTION_USERS[@]}"; do
  USER="${SECTION_USERS[$DOMAIN]}"
  if id "$USER" &>/dev/null; then
    chmod o+rx "/home/$USER" 2>/dev/null || true
    chmod o+rx "/home/$USER/htdocs" 2>/dev/null || true
    echo "  ✓ /home/$USER"
  fi
done

# Install acl if needed
apt-get install -y acl > /dev/null 2>&1

# Files directories
for DOMAIN in $ALL_DOMAINS; do
  FILES_DIR="$MAIN_ROOT/web/sites/$DOMAIN/files"
  if [ -d "$FILES_DIR" ]; then
    chmod -R 777 "$FILES_DIR"
    echo "  ✓ chmod 777 $DOMAIN/files"
  fi
done

echo "✓ Permissions fixed"

# ── PART 3 — Create private directories ───────────────────────────────────
echo ""
echo "[3/4] Creating private directories..."
mkdir -p "$MAIN_HOME/private"
chmod o+rx "$MAIN_HOME/private"

for SECTION in hungary bme corvinus debrecen elte eszterhazy ibs mate miskolc obuda pecs semmelweis szeged lups; do
  mkdir -p "$MAIN_HOME/private/$SECTION"
  chmod 777 "$MAIN_HOME/private/$SECTION"
  chmod o+rx "$MAIN_HOME/private/$SECTION"
  cat > "$MAIN_HOME/private/$SECTION/.htaccess" << 'HTEOF'
<IfModule mod_authz_core.c>
  Require all denied
</IfModule>
<IfModule !mod_authz_core.c>
  Deny from all
</IfModule>
SetHandler Drupal_Security_Do_Not_Remove_See_SA_2013_003
HTEOF
  echo "  ✓ private/$SECTION"
done
chown -R $MAIN_USER:$MAIN_USER "$MAIN_HOME/private"
echo "✓ Private directories created"

# ── PART 4 — MySQL auth fix ────────────────────────────────────────────────
echo ""
echo "[4/4] MySQL authentication fix..."
echo ""
echo "MySQL root credentials:"
clpctl db:show:master-credentials
echo ""
echo "Open MySQL and run these ALTER USER commands for each site's DB user."
echo "Replace each PASSWORD with the actual password from CloudPanel."
echo ""
echo "  ALTER USER 'HungaryDbUser'@'%'    IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'BmeDbUser'@'%'        IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'CorvinusDbUser'@'%'   IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'DebrecenDbUser'@'%'   IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'ElteDbUser'@'%'       IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'EszterhazyDbUser'@'%' IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'IbsDbUser'@'%'        IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'MateDbUser'@'%'       IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'MiskolcDbUser'@'%'    IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'ObudaDbUser'@'%'      IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'PecsDbUser'@'%'       IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'SemmelweisDbUser'@'%' IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'SzegedDbUser'@'%'     IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  ALTER USER 'LupsDbUser'@'%'       IDENTIFIED WITH mysql_native_password BY 'PASSWORD';"
echo "  FLUSH PRIVILEGES;"
echo "  EXIT;"
echo ""
read -p "Press ENTER to open MySQL..."
mysql -h'127.0.0.1' -P'3306' -u'root' -p -A

echo ""
echo "Now update each scaffold settings file with the real password."
echo "For each site, run:"
echo "  sudo -u $MAIN_USER nano $MAIN_ROOT/scaffold/SITE.settings.php"
echo "  (replace PLACEHOLDER with real password)"
echo ""
echo "Then push all settings:"
echo "  sudo -u $MAIN_USER bash -c 'cd $MAIN_ROOT && composer drupal:scaffold'"
echo ""
echo "================================================"
echo " Server fixed! Next: sudo bash /home/webmaster/scripts/03_install_sites.sh"
echo "================================================"
