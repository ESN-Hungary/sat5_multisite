#!/bin/bash
##############################################################################
# ESN Hungary — PRODUCTION Install Sites Script
# Run as: sudo bash /home/webmaster/scripts/03_install_sites.sh
##############################################################################
set -e

MAIN_USER="esn-hungary"
MAIN_HOME="/home/esn-hungary"
MAIN_ROOT="$MAIN_HOME/htdocs/new-hungary.esn.hu"
DRUSH="$MAIN_ROOT/vendor/bin/drush"

# ── Admin credentials per site ─────────────────────────────────────────────
PASS_HUNGARY="webmaster@2026"
PASS_BME="webmaster@2026"
PASS_CORVINUS="webmaster@2026"
PASS_DEBRECEN="webmaster@2026"
PASS_ELTE="webmaster@2026"
PASS_ESZTERHAZY="webmaster@2026"
PASS_IBS="webmaster@2026"
PASS_LUPS="webmaster@2026"
PASS_MATE="webmaster@2026"
PASS_MISKOLC="webmaster@2026"
PASS_OBUDA="webmaster@2026"
PASS_PECS="webmaster@2026"
PASS_SEMMELWEIS="webmaster@2026"
PASS_SZEGED="webmaster@2026"

echo "================================================"
echo " ESN Hungary — Step 3: Install All 14 Sites"
echo "================================================"

fix_acl() {
  local DOMAIN=$1
  local FILES="$MAIN_ROOT/web/sites/$DOMAIN/files"
  chmod -R 777 "$FILES"
  setfacl -R -m u:$MAIN_USER:rwx "$FILES"
  setfacl -R -d -m u:$MAIN_USER:rwx "$FILES"
  mkdir -p "$FILES/styles"
  chmod -R 777 "$FILES/styles"
  setfacl -R -m u:$MAIN_USER:rwx "$FILES/styles"
  setfacl -R -d -m u:$MAIN_USER:rwx "$FILES/styles"
  echo "  ✓ ACL fixed for $DOMAIN"
}

install_site() {
  local DOMAIN=$1
  local SITE_NAME=$2
  local ADMIN_USER=$3
  local ADMIN_PASS=$4
  local SETUP_SCRIPT=$5
  echo ""
  echo "──────────────────────────────────────────────"
  echo " Installing: $DOMAIN"
  echo " Admin user: $ADMIN_USER"
  echo "──────────────────────────────────────────────"
  sudo -u $MAIN_USER $DRUSH --uri=https://$DOMAIN site:install satellite \
    --account-name="$ADMIN_USER" \
    --account-mail="$ADMIN_USER@esn.hu" \
    --account-pass="$ADMIN_PASS" \
    --site-name="$SITE_NAME" \
    --yes
  sudo -u $MAIN_USER $DRUSH --uri=https://$DOMAIN \
    php:script "$MAIN_ROOT/scripts/$SETUP_SCRIPT"
  fix_acl "$DOMAIN"
  echo "✓ $DOMAIN installed (admin: $ADMIN_USER)"
}

# ── Main site ─────────────────────────────────────────────────────────────
install_site "new-hungary.esn.hu"    "ESN Hungary"             "hungary_admin"    "$PASS_HUNGARY"    "esn_hungary_setup.php"

# ── 13 Section sites ──────────────────────────────────────────────────────
install_site "new-bme.esn.hu"        "ESN BME Budapest"        "bme_admin"        "$PASS_BME"        "esn_section_setup.php"
install_site "new-corvinus.esn.hu"   "ESN Corvinus Budapest"   "corvinus_admin"   "$PASS_CORVINUS"   "esn_section_setup.php"
install_site "new-debrecen.esn.hu"   "ESN Debrecen"            "debrecen_admin"   "$PASS_DEBRECEN"   "esn_section_setup.php"
install_site "new-elte.esn.hu"       "ESN ELTE Budapest"       "elte_admin"       "$PASS_ELTE"       "esn_section_setup.php"
install_site "new-eszterhazy.esn.hu" "ESN Eszterhazy Eger"     "eszterhazy_admin" "$PASS_ESZTERHAZY" "esn_section_setup.php"
install_site "new-ibs.esn.hu"        "ESN IBS Budapest"        "ibs_admin"        "$PASS_IBS"        "esn_section_setup.php"
install_site "lups.esn.hu"           "ESN LUPS Budapest"       "lups_admin"       "$PASS_LUPS"       "esn_section_setup.php"
install_site "mate.esn.hu"           "ESN MATE Godollo"        "mate_admin"       "$PASS_MATE"       "esn_section_setup.php"
install_site "new-miskolc.esn.hu"    "ESN Miskolc"             "miskolc_admin"    "$PASS_MISKOLC"    "esn_section_setup.php"
install_site "new-obuda.esn.hu"      "ESN Obuda Budapest"      "obuda_admin"      "$PASS_OBUDA"      "esn_section_setup.php"
install_site "new-pecs.esn.hu"       "ESN Pecs"                "pecs_admin"       "$PASS_PECS"       "esn_section_setup.php"
install_site "semmelweis.esn.hu"     "ESN Semmelweis Budapest" "semmelweis_admin" "$PASS_SEMMELWEIS" "esn_section_setup.php"
install_site "new-szeged.esn.hu"     "ESN Szeged"              "szeged_admin"     "$PASS_SZEGED"     "esn_section_setup.php"

# ── Verify all sites ──────────────────────────────────────────────────────
echo ""
echo "================================================"
echo " Verifying all 14 sites..."
echo "================================================"
for DOMAIN in new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu lups.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu; do
  echo -n "  https://$DOMAIN → "
  curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN"
  echo ""
done

echo ""
echo "================================================"
echo " All 14 sites installed!"
echo " Admin credentials summary:"
echo "   new-hungary.esn.hu    → hungary_admin"
echo "   new-bme.esn.hu        → bme_admin"
echo "   new-corvinus.esn.hu   → corvinus_admin"
echo "   new-debrecen.esn.hu   → debrecen_admin"
echo "   new-elte.esn.hu       → elte_admin"
echo "   new-eszterhazy.esn.hu → eszterhazy_admin"
echo "   new-ibs.esn.hu        → ibs_admin"
echo "   lups.esn.hu           → lups_admin"
echo "   mate.esn.hu           → mate_admin"
echo "   new-miskolc.esn.hu    → miskolc_admin"
echo "   new-obuda.esn.hu      → obuda_admin"
echo "   new-pecs.esn.hu       → pecs_admin"
echo "   semmelweis.esn.hu     → semmelweis_admin"
echo "   new-szeged.esn.hu     → szeged_admin"
echo " Next steps:"
echo " 1. Set Turnstile keys on each site"
echo " 2. Upload homepage photos on new-hungary.esn.hu"
echo " 3. Each section: update About Us and Home page"
echo "================================================"
