#!/bin/bash
#
# run-scaffold.sh
#
# Full scaffold cycle for the ESN Hungary Drupal multisite:
#   1. chmod u+w on every site directory under web/sites/*
#      (they're normally locked to 555 as a hardening measure, but
#       composer needs directory write access to delete+recreate
#       settings.php during scaffolding)
#   2. composer drupal:scaffold
#   3. fix vendor/ permissions (composer update/scaffold can leave
#      files as rw-rw---- which section-site PHP-FPM workers can't read)
#   4. drush cr on all 14 sites
#   5. chmod u-w on every site directory again (always — even on failure)
#
# This script runs the composer/drush steps as the esn-hungary user
# itself, so you can invoke it directly as webmaster (or root) without
# manually `sudo su - esn-hungary` first. It re-execs itself under
# esn-hungary via sudo -u when needed.
#
# Usage (as webmaster):
#   sudo bash run-scaffold.sh
#
# (sudo is required either way — for the directory chmod steps, which
#  must happen regardless of which user runs composer.)

set -uo pipefail

CODEBASE="/home/esn-hungary/htdocs/new-hungary.esn.hu"
SITES_DIR="$CODEBASE/web/sites"
DRUPAL_USER="esn-hungary"

DOMAINS=(
  new-hungary.esn.hu
  new-bme.esn.hu
  new-corvinus.esn.hu
  new-debrecen.esn.hu
  new-elte.esn.hu
  new-eszterhazy.esn.hu
  new-ibs.esn.hu
  mate.esn.hu
  new-miskolc.esn.hu
  new-obuda.esn.hu
  new-pecs.esn.hu
  semmelweis.esn.hu
  new-szeged.esn.hu
  lups.esn.hu
)

# Run a command as the esn-hungary user, regardless of which user
# invoked this script. This is the one place composer/drush calls
# should ever be made from.
run_as_drupal_user() {
  sudo -u "$DRUPAL_USER" bash -c "$1"
}

unlock_dirs() {
  echo "==> Unlocking site directories (chmod u+w)..."
  for DOMAIN in "${DOMAINS[@]}"; do
    DIR="$SITES_DIR/$DOMAIN"
    if [ -d "$DIR" ]; then
      sudo chmod u+w "$DIR"
    else
      echo "    WARNING: $DIR does not exist, skipping"
    fi
  done
}

relock_dirs() {
  echo "==> Relocking site directories (chmod u-w)..."
  for DOMAIN in "${DOMAINS[@]}"; do
    DIR="$SITES_DIR/$DOMAIN"
    if [ -d "$DIR" ]; then
      sudo chmod u-w "$DIR"
    fi
  done
}

fix_vendor_permissions() {
  echo "==> Fixing vendor/ permissions..."
  sudo find "$CODEBASE/vendor" -type f -exec chmod o+r {} \;
  sudo find "$CODEBASE/vendor" -type d -exec chmod o+rx {} \;
}

clear_all_caches() {
  echo "==> Clearing cache on all sites..."
  for DOMAIN in "${DOMAINS[@]}"; do
    echo "    - $DOMAIN"
    run_as_drupal_user "cd $CODEBASE && vendor/bin/drush --uri=https://$DOMAIN cr"
  done
}

# Always relock directories, no matter how the script exits.
trap relock_dirs EXIT

unlock_dirs

echo "==> Running composer drupal:scaffold as $DRUPAL_USER..."
if run_as_drupal_user "cd $CODEBASE && composer drupal:scaffold"; then
  echo "==> Scaffold completed successfully."
  SCAFFOLD_STATUS=0
else
  echo "==> ERROR: composer drupal:scaffold failed."
  echo "    Directories will still be relocked. Fix the error above and re-run."
  SCAFFOLD_STATUS=1
fi

if [ $SCAFFOLD_STATUS -eq 0 ]; then
  fix_vendor_permissions
  clear_all_caches
  echo "==> Done. Scaffold, vendor permissions, and cache clear all completed."
else
  echo "==> Skipping vendor permission fix and cache clear due to scaffold failure."
fi

exit $SCAFFOLD_STATUS