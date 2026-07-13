#!/bin/bash
##############################################################################
# ESN Hungary — PRODUCTION Codebase Setup
# Run as: sudo bash /home/webmaster/scripts/01_setup_codebase.sh
##############################################################################
set -e

SCRIPTS_DIR="/home/webmaster/scripts"
MAIN_USER="esn-hungary"
MAIN_HOME="/home/esn-hungary"
MAIN_ROOT="$MAIN_HOME/htdocs/new-hungary.esn.hu"

echo "================================================"
echo " ESN Hungary — Step 1: Setup Codebase"
echo "================================================"

# ── STEP 1 — composer.json ────────────────────────────────────────────────
echo ""
echo "[1/8] Creating composer.json..."

sudo -u $MAIN_USER bash -c "cat > '$MAIN_ROOT/composer.json'" << 'EOF'
{
  "name": "esn/satellite-project",
  "description": "ESN Hungary Multisite — 14 sites",
  "type": "project",
  "license": "GPL-3.0-or-later",
  "repositories": [
    { "type": "composer", "url": "https://packages.drupal.org/8" },
    { "type": "composer", "url": "https://packages.esn.org" }
  ],
  "require": {
    "php": "^8.0",
    "esn/satellite-profile": "^5.1",
    "drupal/eu_cookie_compliance": "^1.29",
    "drupal/webform": "^6.2",
    "drupal/captcha": "^2.0",
    "drupal/turnstile": "^1.1"
  },
  "conflict": { "drupal/drupal": "*" },
  "minimum-stability": "alpha",
  "prefer-stable": true,
  "config": {
    "sort-packages": true,
    "allow-plugins": {
      "composer/installers": true,
      "cweagans/composer-patches": true,
      "drupal/core-composer-scaffold": true,
      "mglaman/composer-drupal-lenient": true
    }
  },
  "scripts": {
    "setup-sites": [
      "mkdir -p web/sites/new-hungary.esn.hu/files",
      "mkdir -p web/sites/new-bme.esn.hu/files",
      "mkdir -p web/sites/new-corvinus.esn.hu/files",
      "mkdir -p web/sites/new-debrecen.esn.hu/files",
      "mkdir -p web/sites/new-elte.esn.hu/files",
      "mkdir -p web/sites/new-eszterhazy.esn.hu/files",
      "mkdir -p web/sites/new-ibs.esn.hu/files",
      "mkdir -p web/sites/mate.esn.hu/files",
      "mkdir -p web/sites/new-miskolc.esn.hu/files",
      "mkdir -p web/sites/new-obuda.esn.hu/files",
      "mkdir -p web/sites/new-pecs.esn.hu/files",
      "mkdir -p web/sites/semmelweis.esn.hu/files",
      "mkdir -p web/sites/new-szeged.esn.hu/files",
      "mkdir -p web/sites/lups.esn.hu/files",
      "mkdir -p config/hungary/sync",
      "mkdir -p config/bme/sync",
      "mkdir -p config/corvinus/sync",
      "mkdir -p config/debrecen/sync",
      "mkdir -p config/elte/sync",
      "mkdir -p config/eszterhazy/sync",
      "mkdir -p config/ibs/sync",
      "mkdir -p config/mate/sync",
      "mkdir -p config/miskolc/sync",
      "mkdir -p config/obuda/sync",
      "mkdir -p config/pecs/sync",
      "mkdir -p config/semmelweis/sync",
      "mkdir -p config/szeged/sync",
      "mkdir -p config/lups/sync"
    ]
  },
  "extra": {
    "drupal-scaffold": {
      "locations": { "web-root": "web/" },
      "file-mapping": {
        "[web-root]/sites/sites.php":                            "scaffold/sites.php",
        "[web-root]/sites/new-hungary.esn.hu/settings.php":     "scaffold/new-hungary.settings.php",
        "[web-root]/sites/new-bme.esn.hu/settings.php":         "scaffold/new-bme.settings.php",
        "[web-root]/sites/new-corvinus.esn.hu/settings.php":    "scaffold/new-corvinus.settings.php",
        "[web-root]/sites/new-debrecen.esn.hu/settings.php":    "scaffold/new-debrecen.settings.php",
        "[web-root]/sites/new-elte.esn.hu/settings.php":        "scaffold/new-elte.settings.php",
        "[web-root]/sites/new-eszterhazy.esn.hu/settings.php":  "scaffold/new-eszterhazy.settings.php",
        "[web-root]/sites/new-ibs.esn.hu/settings.php":         "scaffold/new-ibs.settings.php",
        "[web-root]/sites/mate.esn.hu/settings.php":            "scaffold/mate.settings.php",
        "[web-root]/sites/new-miskolc.esn.hu/settings.php":     "scaffold/new-miskolc.settings.php",
        "[web-root]/sites/new-obuda.esn.hu/settings.php":       "scaffold/new-obuda.settings.php",
        "[web-root]/sites/new-pecs.esn.hu/settings.php":        "scaffold/new-pecs.settings.php",
        "[web-root]/sites/semmelweis.esn.hu/settings.php":      "scaffold/semmelweis.settings.php",
        "[web-root]/sites/new-szeged.esn.hu/settings.php":      "scaffold/new-szeged.settings.php",
        "[web-root]/sites/lups.esn.hu/settings.php":            "scaffold/lups.settings.php"
      }
    },
    "installer-paths": {
      "web/core":                       ["type:drupal-core"],
      "web/libraries/{$name}":          ["type:drupal-library"],
      "web/modules/contrib/{$name}":    ["type:drupal-module"],
      "web/profiles/contrib/satellite": ["esn/satellite-profile"],
      "web/profiles/contrib/{$name}":   ["type:drupal-profile"],
      "web/themes/contrib/{$name}":     ["type:drupal-theme"],
      "drush/Commands/contrib/{$name}": ["type:drupal-drush"],
      "web/modules/custom/{$name}":     ["type:drupal-custom-module"],
      "web/profiles/custom/{$name}":    ["type:drupal-custom-profile"],
      "web/themes/custom/{$name}":      ["type:drupal-custom-theme"]
    }
  }
}
EOF
echo "✓ composer.json created"

# ── STEP 2 — Scaffold files ───────────────────────────────────────────────
echo ""
echo "[2/8] Creating scaffold files..."
sudo -u $MAIN_USER mkdir -p "$MAIN_ROOT/scaffold"

# sites.php
sudo -u $MAIN_USER bash -c "cat > '$MAIN_ROOT/scaffold/sites.php'" << 'EOF'
<?php
$sites['new-hungary.esn.hu']   = 'new-hungary.esn.hu';
$sites['new-bme.esn.hu']       = 'new-bme.esn.hu';
$sites['new-corvinus.esn.hu']  = 'new-corvinus.esn.hu';
$sites['new-debrecen.esn.hu']  = 'new-debrecen.esn.hu';
$sites['new-elte.esn.hu']      = 'new-elte.esn.hu';
$sites['new-eszterhazy.esn.hu']= 'new-eszterhazy.esn.hu';
$sites['new-ibs.esn.hu']       = 'new-ibs.esn.hu';
$sites['mate.esn.hu']          = 'mate.esn.hu';
$sites['new-miskolc.esn.hu']   = 'new-miskolc.esn.hu';
$sites['new-obuda.esn.hu']     = 'new-obuda.esn.hu';
$sites['new-pecs.esn.hu']      = 'new-pecs.esn.hu';
$sites['semmelweis.esn.hu']    = 'semmelweis.esn.hu';
$sites['new-szeged.esn.hu']    = 'new-szeged.esn.hu';
$sites['lups.esn.hu']          = 'lups.esn.hu';
EOF

# Function to create a settings file
make_settings() {
  local FILE=$1 DOMAIN=$2 SECTION=$3 DB=$4 USER=$5 HASH=$6
  local TRUSTED=$(echo "$DOMAIN" | sed 's/\./\\./g')
  sudo -u $MAIN_USER bash -c "cat > '$MAIN_ROOT/scaffold/${FILE}.settings.php'" << EOF
<?php
\$databases['default']['default'] = [
  'driver'   => 'mysql',
  'database' => '$DB',
  'username' => '$USER',
  'password' => 'PLACEHOLDER',
  'host'     => '127.0.0.1',
  'port'     => '3306',
  'prefix'   => '',
];
\$settings['hash_salt']             = '$HASH';
\$settings['file_public_path']      = 'sites/$DOMAIN/files';
\$settings['file_private_path']     = '$MAIN_HOME/private/$SECTION';
\$settings['config_sync_directory'] = '../config/$SECTION/sync';
\$settings['trusted_host_patterns'] = ['^${TRUSTED}\$'];
\$settings['state_cache']           = TRUE;
\$config['openid_connect.client.esn_accounts']['settings']['client_id']     = '';
\$config['openid_connect.client.esn_accounts']['settings']['client_secret'] = '';
EOF
}

# Generate all 14 settings files
make_settings "new-hungary"   "new-hungary.esn.hu"   "hungary"   "HungaryDb"   "HungaryDbUser"   "$(openssl rand -base64 32)"
make_settings "new-bme"       "new-bme.esn.hu"       "bme"       "BmeDb"       "BmeDbUser"       "$(openssl rand -base64 32)"
make_settings "new-corvinus"  "new-corvinus.esn.hu"  "corvinus"  "CorvinusDb"  "CorvinusDbUser"  "$(openssl rand -base64 32)"
make_settings "new-debrecen"  "new-debrecen.esn.hu"  "debrecen"  "DebrecenDb"  "DebrecenDbUser"  "$(openssl rand -base64 32)"
make_settings "new-elte"      "new-elte.esn.hu"      "elte"      "ElteDb"      "ElteDbUser"      "$(openssl rand -base64 32)"
make_settings "new-eszterhazy" "new-eszterhazy.esn.hu" "eszterhazy" "EszterhazyDb" "EszterhazyDbUser" "$(openssl rand -base64 32)"
make_settings "new-ibs"       "new-ibs.esn.hu"       "ibs"       "IbsDb"       "IbsDbUser"       "$(openssl rand -base64 32)"
make_settings "mate"          "mate.esn.hu"          "mate"      "MateDb"      "MateDbUser"      "$(openssl rand -base64 32)"
make_settings "new-miskolc"   "new-miskolc.esn.hu"   "miskolc"   "MiskolcDb"   "MiskolcDbUser"   "$(openssl rand -base64 32)"
make_settings "new-obuda"     "new-obuda.esn.hu"     "obuda"     "ObudaDb"     "ObudaDbUser"     "$(openssl rand -base64 32)"
make_settings "new-pecs"      "new-pecs.esn.hu"      "pecs"      "PecsDb"      "PecsDbUser"      "$(openssl rand -base64 32)"
make_settings "semmelweis"    "semmelweis.esn.hu"    "semmelweis" "SemmelweisDb" "SemmelweisDbUser" "$(openssl rand -base64 32)"
make_settings "new-szeged"    "new-szeged.esn.hu"    "szeged"    "SzegedDb"    "SzegedDbUser"    "$(openssl rand -base64 32)"
make_settings "lups"          "lups.esn.hu"          "lups"      "LupsDb"      "LupsDbUser"      "$(openssl rand -base64 32)"

echo "✓ Scaffold files created (14 sites)"

# ── STEP 3 — Composer install ─────────────────────────────────────────────
echo ""
echo "[3/8] Running composer install (this takes a few minutes)..."
sudo -u $MAIN_USER bash -c "
  cd '$MAIN_ROOT'
  composer install
  composer run-script setup-sites
  find vendor/bin -type f -exec chmod +x {} \;
"
echo "✓ Composer install complete"

# ── STEP 4 — Flag-icons library ───────────────────────────────────────────
echo ""
echo "[4/8] Installing flag-icons library..."
sudo -u $MAIN_USER mkdir -p "$MAIN_ROOT/web/libraries"
cd /tmp
wget -q https://github.com/lipis/flag-icons/archive/refs/tags/v7.5.0.tar.gz
tar -xzf v7.5.0.tar.gz
mv flag-icons-7.5.0 "$MAIN_ROOT/web/libraries/flag-icons"
chown -R $MAIN_USER:$MAIN_USER "$MAIN_ROOT/web/libraries/flag-icons"
rm v7.5.0.tar.gz
echo "✓ Flag-icons installed"

# ── STEP 5 — Copy setup scripts ───────────────────────────────────────────
echo ""
echo "[5/8] Copying setup scripts..."
sudo -u $MAIN_USER mkdir -p "$MAIN_ROOT/scripts"
sudo -u $MAIN_USER cp "$SCRIPTS_DIR/esn_hungary_setup.php"     "$MAIN_ROOT/scripts/"
sudo -u $MAIN_USER cp "$SCRIPTS_DIR/esn_section_setup.php"     "$MAIN_ROOT/scripts/"
sudo -u $MAIN_USER cp "$SCRIPTS_DIR/create_halloween_page.php" "$MAIN_ROOT/scripts/"
echo "✓ Scripts copied"

# ── STEP 6 — Fix satellite template bugs ──────────────────────────────────
echo ""
echo "[6/8] Fixing satellite template bugs..."
TWIG1="$MAIN_ROOT/web/profiles/contrib/satellite/themes/satellite_theme/templates/paragraph/paragraph--text-with-title-and-link--default.html.twig"
sed -i "s/{{ field_link|add_class('btn', 'btn-link') }}/{% if field_link %}{{ field_link|add_class('btn', 'btn-link') }}{% endif %}/g" "$TWIG1"
chown $MAIN_USER:$MAIN_USER "$TWIG1"

TWIG2="$MAIN_ROOT/web/profiles/contrib/satellite/themes/satellite_theme/templates/views/views-view-unformatted--spotlight--block-1.html.twig"
sed -i "s|href=\"{{ path(field_link\['#url'\].routeName, field_link\['#url'\].routeParameters) }}\"|href=\"{{ field_link\['#url'\].toString() }}\"|g" "$TWIG2"
chown $MAIN_USER:$MAIN_USER "$TWIG2"
echo "✓ Template bugs fixed"

# ── STEP 7 — Drupal scaffold ──────────────────────────────────────────────
echo ""
echo "[7/8] Running drupal scaffold..."
sudo -u $MAIN_USER bash -c "cd '$MAIN_ROOT' && composer drupal:scaffold"
echo "✓ Scaffold complete"

# ── STEP 8 — Prompt for passwords ─────────────────────────────────────────
echo ""
echo "[8/8] Password setup required..."
echo ""
echo "⚠️  Edit each scaffold settings file and replace PLACEHOLDER with the real DB password:"
echo ""
for SITE in new-hungary new-bme new-corvinus new-debrecen new-elte new-eszterhazy new-ibs mate new-miskolc new-obuda new-pecs semmelweis new-szeged lups; do
  echo "    sudo -u $MAIN_USER nano $MAIN_ROOT/scaffold/${SITE}.settings.php"
done
echo ""
echo "    Then run:"
echo "    sudo -u $MAIN_USER bash -c 'cd $MAIN_ROOT && composer drupal:scaffold'"
echo ""
echo "    Then run the next script:"
echo "    sudo bash /home/webmaster/scripts/02_fix_server.sh"
echo ""
echo "================================================"
echo " Codebase setup complete!"
echo "================================================"
