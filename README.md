# ESN Hungary Drupal 10 Multisite — Complete Setup & Operations Guide

> ⚠️ **Critical rules — read before touching anything:**
> - **Never click "Update" in the Drupal admin UI** — it corrupts the codebase
> - **Never upgrade Radix beyond 5.x** — Satellite theme requires exactly `^5.0`
> - **Never edit `web/sites/*/settings.php` directly** — always edit `scaffold/*.settings.php` then run `composer drupal:scaffold`
> - **All updates via terminal only** using `composer update`

---

## How to Log In for Drupal/Composer Work

All Drupal and Composer commands assume you are logged in as `esn-hungary` and inside the codebase root. Do this first every time:

```bash
ssh webmaster@@20.82.118.251
sudo su - esn-hungary
cd /home/esn-hungary/htdocs/new-hungary.esn.hu
```

From here, commands like `composer update` and `vendor/bin/drush ...` work directly without any prefix.

For system-level tasks (nginx, PHP-FPM, MySQL, file permissions) you need to be `webmaster` with sudo. Exit the esn-hungary session first:

```bash
exit   # back to webmaster
sudo systemctl reload nginx   # example system command
```

---

## Table of Contents

1. [Architecture](#architecture)
2. [Server & Infrastructure](#server--infrastructure)
3. [All 14 Sites](#all-14-sites)
4. [Scripts Reference](#scripts-reference)
5. [PHASE 1 — DNS (Cloudflare)](#phase-1--dns-cloudflare)
6. [PHASE 2 — CloudPanel Setup](#phase-2--cloudpanel-setup)
7. [PHASE 3 — Run the Scripts](#phase-3--run-the-scripts)
8. [PHASE 4 — SSL Certificates](#phase-4--ssl-certificates)
9. [PHASE 5 — Post-Install Tasks](#phase-5--post-install-tasks)
10. [Scaffold System](#scaffold-system)
11. [How to Update Drupal Safely](#how-to-update-drupal-safely)
12. [Adding a New Domain to an Existing Site](#adding-a-new-domain-to-an-existing-site)
13. [Useful Terminal Commands](#useful-terminal-commands)
14. [Troubleshooting](#troubleshooting)
15. [Verification Checklist](#verification-checklist)

---

## Architecture

One Drupal 10 codebase serves all 14 sites. Every section site's nginx `root` points to the same `web/` folder. Each site has its own database, `settings.php`, files directory, and private directory.

```
/home/esn-hungary/htdocs/new-hungary.esn.hu/
  web/
    sites/
      new-hungary.esn.hu/    ← settings.php + files/
      new-bme.esn.hu/        ← settings.php + files/
      ... (one folder per site)
      sites.php              ← maps domains to site folders
  scaffold/                  ← SOURCE FILES — edit these, never web/sites/
    sites.php
    new-hungary.settings.php
    new-bme.settings.php
    ... (one per site)
  scripts/
    esn_hungary_setup.php    ← main site content setup
    esn_section_setup.php    ← section site content setup
    create_halloween_page.php
  config/
    hungary/sync/
    bme/sync/
    ... (one per site)
  vendor/
  composer.json
  composer.lock
```

---

## Server & Infrastructure

| Item | Value |
|------|-------|
| Cloud | Microsoft Azure |
| OS | Ubuntu 24 |
| Panel | CloudPanel (dashboard at dashboard.esn.hu) |
| PHP | 8.3 |
| Database | Percona MySQL 8.4 |
| SSH user | `webmaster` |
| Scripts | `/home/webmaster/scripts/` |
| Main codebase user | `esn-hungary` |
| Main codebase path | `/home/esn-hungary/htdocs/new-hungary.esn.hu/` |
| DNS | Cloudflare |

**Find the VM public IP:**
```bash
curl -s https://api.ipify.org
```

---

## All 14 Sites

| Domain | CloudPanel User | Database | DB User | Admin Username |
|--------|-----------------|----------|---------|----------------|
| new-hungary.esn.hu | esn-hungary | HungaryDb | HungaryDbUser | hungary_admin |
| new-bme.esn.hu | esn-new-bme | BmeDb | BmeDbUser | bme_admin |
| new-corvinus.esn.hu | esn-new-corvinus | CorvinusDb | CorvinusDbUser | corvinus_admin |
| new-debrecen.esn.hu | esn-new-debrecen | DebrecenDb | DebrecenDbUser | debrecen_admin |
| new-elte.esn.hu | esn-new-elte | ElteDb | ElteDbUser | elte_admin |
| new-eszterhazy.esn.hu | esn-new-eszterhazy | EszterhazyDb | EszterhazyDbUser | eszterhazy_admin |
| new-ibs.esn.hu | esn-new-ibs | IbsDb | IbsDbUser | ibs_admin |
| mate.esn.hu | esn-mate | MateDb | MateDbUser | mate_admin |
| new-miskolc.esn.hu | esn-new-miskolc | MiskolcDb | MiskolcDbUser | miskolc_admin |
| new-obuda.esn.hu | esn-new-obuda | ObudaDb | ObudaDbUser | obuda_admin |
| new-pecs.esn.hu | esn-new-pecs | PecsDb | PecsDbUser | pecs_admin |
| semmelweis.esn.hu | esn-semmelweis | SemmelweisDb | SemmelweisDbUser | semmelweis_admin |
| new-szeged.esn.hu | esn-new-szeged | SzegedDb | SzegedDbUser | szeged_admin |
| lups.esn.hu | esn-lups | LupsDb | LupsDbUser | lups_admin |

---

## Scripts Reference

All scripts live at `/home/webmaster/scripts/`.

| File | Purpose |
|------|---------|
| `01_setup_codebase.sh` | Creates composer.json + scaffold files for all 14 sites, runs composer install, installs flag-icons, fixes Satellite template bugs |
| `02_fix_server.sh` | Fixes nginx root for all 13 sections, permissions, private dirs, MySQL auth |
| `03_install_sites.sh` | Installs all 14 Drupal sites, runs setup scripts, fixes ACL. Edit this file and fill in the admin passwords before running. |
| `esn_hungary_setup.php` | Main site: homepage HTML, About Us, Privacy Policy, Contact Us webform with Turnstile |
| `esn_section_setup.php` | Sections: placeholder pages, Contact Us webform with Turnstile |
| `create_halloween_page.php` | Halloween in Transylvania page (run manually when needed on any site) |

---

## PHASE 1 — DNS (Cloudflare)

All domains point to the Azure VM public IP. DNS is managed in Cloudflare.

Add an A record for each subdomain pointing to the VM IP. Keep proxy set to **DNS only (grey cloud)** initially so SSL certificates can be issued, then switch to proxy (orange cloud) afterwards if needed.

Subdomains needed: `new-hungary`, `new-bme`, `new-corvinus`, `new-debrecen`, `new-elte`, `new-eszterhazy`, `new-ibs`, `mate`, `new-miskolc`, `new-obuda`, `new-pecs`, `semmelweis`, `new-szeged`, `lups`

**Check if DNS is resolving to the correct IP:**
```bash
dig new-hungary.esn.hu +short
# Should return your VM's public IP, not a Cloudflare IP (104.21.x.x or 172.67.x.x)
```

---

## PHASE 2 — CloudPanel Setup

### 2.1 Create Sites

For the **main site**:
```
CloudPanel → Add Site
Domain:   new-hungary.esn.hu
User:     esn-hungary
PHP:      8.3
```

For **each of the 13 section sites**:
```
CloudPanel → Add Site
Domain:   new-bme.esn.hu
User:     esn-new-bme
PHP:      8.3
```

> ⚠️ Do NOT change the nginx root in CloudPanel UI. The `02_fix_server.sh` script fixes it via command line.

### 2.2 Create Databases

Each database is created under its own site in CloudPanel:
```
CloudPanel → Sites → esn-new-bme → Databases → Add Database
Database:  BmeDb
Username:  BmeDbUser
Password:  (use a strong password)
```

Repeat for all 14 sites using exact names from the table above.

After creating all databases, update the scaffold settings files with the real passwords:
```bash
# As webmaster:
sudo nano /home/esn-hungary/htdocs/new-hungary.esn.hu/scaffold/new-hungary.settings.php
# Replace PLACEHOLDER with the real DB password. Repeat for all 14 files.

# Then push to web/sites/
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-hungary.esn.hu/settings.php
# (repeat chmod for each site's settings.php)
sudo -u esn-hungary bash -c 'cd /home/esn-hungary/htdocs/new-hungary.esn.hu && composer drupal:scaffold'
```

---

## PHASE 3 — Run the Scripts

```bash
# As webmaster:

# Step 1: Codebase setup (5-10 min)
sudo bash /home/webmaster/scripts/01_setup_codebase.sh

# Step 2: Fix server (nginx, permissions, MySQL auth, private dirs)
sudo bash /home/webmaster/scripts/02_fix_server.sh

# Step 3: Edit 03_install_sites.sh — fill in the admin passwords for each site
sudo nano /home/webmaster/scripts/03_install_sites.sh

# Then install all 14 sites (30-45 min)
sudo bash /home/webmaster/scripts/03_install_sites.sh
```

---

## PHASE 4 — SSL Certificates

### Option A — Let's Encrypt (only works when Cloudflare proxy is OFF / grey cloud)
```
CloudPanel → Sites → DOMAIN → SSL/TLS → New Let's Encrypt Certificate → Create and Install
```

### Option B — Self-signed (works with Cloudflare proxy ON)

CloudPanel issues these automatically as a fallback when Let's Encrypt fails. They work fine with Cloudflare proxy since Cloudflare shows its own trusted cert to visitors.

**Generate a wildcard self-signed cert manually if needed (as webmaster):**
```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /tmp/esn-origin.key \
  -out /tmp/esn-origin.crt \
  -subj "/C=HU/O=ESN Hungary/CN=*.esn.hu" \
  -addext "subjectAltName=DNS:*.esn.hu,DNS:esn.hu"

cat /tmp/esn-origin.crt
cat /tmp/esn-origin.key
```

Then in CloudPanel: SSL/TLS → Custom Certificate → paste cert and key. Same cert for all sites.

### Option C — Cloudflare Origin Certificate (best long-term solution)
```
Cloudflare → esn.hu → SSL/TLS → Origin Server → Create Certificate
Add: *.esn.hu and esn.hu → RSA → 15 years → Create
Download the .pem and .key files
```
Install in CloudPanel → SSL/TLS → Custom Certificate for each site (same cert and key for all).
Set Cloudflare SSL mode to **Full** (not Flexible, not Full Strict).

**Check certificate expiry for all installed certs (as webmaster):**
```bash
for cert in /etc/nginx/ssl-certificates/*.crt; do
  echo "── $(basename $cert)"
  openssl x509 -in "$cert" -noout -issuer -dates 2>/dev/null | grep -E "issuer|notAfter"
done
```

---

## PHASE 5 — Post-Install Tasks

### 5.1 Configure Turnstile CAPTCHA

Get keys from `dash.cloudflare.com → Turnstile → Add site` (one per domain).

In Drupal admin on each site:
```
Configuration → People → CAPTCHA settings → Turnstile tab
Site key:   paste from Cloudflare
Secret key: paste from Cloudflare
Save
```

### 5.2 Upload Homepage Photos (main site only)

The homepage has photo placeholders. Upload images via Drupal media, then:
```
Content → Home → Edit → click the text paragraph → Source button
```
Replace in the HTML:
- `YOUR_MAIN_PHOTO` — tall hero photo (left column)
- `YOUR_TOP_PHOTO` — top right photo
- `YOUR_BOTTOM_PHOTO` — bottom right photo
- `YOUR_ABOUT_PHOTO` — about section photo
- `YOUR_MAP_PHOTO` — map of Hungary with section pins

### 5.3 Add Email Notifications for Contact Form

On each site:
```
Structure → Webforms → Contact Us → Settings → Emails/Handlers → Add handler → Email
To:      section@esn.hu
Subject: New message from [webform-submission:values:full_name]
Save
```

### 5.4 Configure SMTP (email sending)

```bash
# Logged in as esn-hungary in codebase root:
composer require drupal/smtp
vendor/bin/drush --uri=https://new-hungary.esn.hu en smtp -y
```

Then configure at `Configuration → System → SMTP Authentication Support`.

### 5.5 OpenID Connect (ESN Accounts login)

Three sites need OAuth credentials — email `it-support@esn.org`:
- `mate.esn.hu`
- `semmelweis.esn.hu`
- `lups.esn.hu`

Once received (as webmaster):
```bash
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/mate.esn.hu/settings.php
sudo nano /home/esn-hungary/htdocs/new-hungary.esn.hu/scaffold/mate.settings.php
# Update:
# $config['openid_connect.client.esn_accounts']['settings']['client_id']     = 'YOUR_ID';
# $config['openid_connect.client.esn_accounts']['settings']['client_secret'] = 'YOUR_SECRET';
sudo -u esn-hungary bash -c 'cd /home/esn-hungary/htdocs/new-hungary.esn.hu && composer drupal:scaffold'
```

Then clear cache (as esn-hungary):
```bash
vendor/bin/drush --uri=https://mate.esn.hu cr
```

### 5.6 Section Content

Each section logs in as their admin user and updates pages via the admin UI. For Home and Halloween pages that use custom HTML, see **Editing Full HTML Pages** in the Troubleshooting section.

---

## Scaffold System

### How it works

```
scaffold/new-bme.settings.php  →  composer drupal:scaffold  →  web/sites/new-bme.esn.hu/settings.php
```

Always edit the scaffold source, never `web/sites/*/settings.php` directly.

### Update a settings file

```bash
# As webmaster — make settings.php temporarily writable:
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-bme.esn.hu/settings.php
sudo nano /home/esn-hungary/htdocs/new-hungary.esn.hu/scaffold/new-bme.settings.php

# Then as esn-hungary in codebase root:
composer drupal:scaffold
vendor/bin/drush --uri=https://new-bme.esn.hu cr
```

### Update sites.php

```bash
# As webmaster:
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/sites.php
sudo nano /home/esn-hungary/htdocs/new-hungary.esn.hu/scaffold/sites.php

# As esn-hungary in codebase root:
composer drupal:scaffold
```

### Settings file structure

```php
$databases['default']['default'] = [
  'driver' => 'mysql', 'database' => 'BmeDb',
  'username' => 'BmeDbUser', 'password' => 'YOUR_PASSWORD',
  'host' => '127.0.0.1', 'port' => '3306', 'prefix' => '',
];
$settings['hash_salt']             = 'UNIQUE_RANDOM_STRING';
$settings['file_public_path']      = 'sites/new-bme.esn.hu/files';
$settings['file_private_path']     = '/home/esn-hungary/private/bme';
$settings['config_sync_directory'] = '../config/bme/sync';
$settings['trusted_host_patterns'] = ['^new-bme\\.esn\\.hu$'];
$settings['state_cache']           = TRUE;
$config['openid_connect.client.esn_accounts']['settings']['client_id']     = '';
$config['openid_connect.client.esn_accounts']['settings']['client_secret'] = '';
```

---

## How to Update Drupal Safely

> ⚠️ NEVER use the admin UI updater. It partially downloads files and corrupts the codebase.

All commands below assume you are logged in as `esn-hungary` inside the codebase root.

### Update everything (core + all modules)

```bash
composer update
```

### Run database updates on all sites

```bash
for DOMAIN in new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu lups.esn.hu; do
  echo "Updating $DOMAIN..."
  vendor/bin/drush --uri=https://$DOMAIN updatedb --yes
  vendor/bin/drush --uri=https://$DOMAIN cr
done
```

### Update a single module

```bash
composer update drupal/MODULE_NAME
```

### Install a new module

```bash
composer require drupal/MODULE_NAME
vendor/bin/drush --uri=https://new-hungary.esn.hu en MODULE_NAME -y
```

### ⚠️ Radix must stay at version 5.x

The Satellite profile requires `drupal/radix ^5.0`. Radix 6.x breaks every page with a 503 error. Ignore the "unsupported release" warning in the admin UI — do not update Radix.

If accidentally upgraded:
```bash
# As webmaster:
rm -rf /home/esn-hungary/htdocs/new-hungary.esn.hu/web/themes/contrib/radix

# As esn-hungary in codebase root:
composer require "drupal/radix:^5.0"
vendor/bin/drush --uri=https://new-hungary.esn.hu cr
```

---

## Adding a New Domain to an Existing Site

When a section moves from a temp domain (e.g. `new-bme.esn.hu`) to a final domain (e.g. `bme.esn.hu`):

**Step 1 — DNS:** Add A record in Cloudflare for the new subdomain pointing to the VM IP.

**Step 2 — CloudPanel → Sites → esn-new-bme → Vhost**

Add the new domain to the `server_name` line:
```nginx
server_name new-bme.esn.hu bme.esn.hu;
```
Save.

**Step 3 — Make files writable (as webmaster):**
```bash
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/sites.php
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-bme.esn.hu/settings.php
```

**Step 4 — Update scaffold/sites.php (as webmaster):**
```bash
sudo nano /home/esn-hungary/htdocs/new-hungary.esn.hu/scaffold/sites.php
# Add: $sites['bme.esn.hu'] = 'new-bme.esn.hu';
```

**Step 5 — Update trusted_host_patterns (as webmaster):**
```bash
sudo nano /home/esn-hungary/htdocs/new-hungary.esn.hu/scaffold/new-bme.settings.php
# Change: $settings['trusted_host_patterns'] = ['^new-bme\\.esn\\.hu$', '^bme\\.esn\\.hu$'];
```

**Step 6 — Push and clear cache (as esn-hungary in codebase root):**
```bash
composer drupal:scaffold
vendor/bin/drush --uri=https://new-bme.esn.hu cr
```

**Step 7 — SSL:** Issue certificate in CloudPanel for the new domain.

**Step 8 — Test:**
```bash
curl -s -o /dev/null -w "%{http_code}" https://bme.esn.hu
```

---

## Useful Terminal Commands

> All Drupal/Composer commands assume you are logged in as `esn-hungary` and inside `/home/esn-hungary/htdocs/new-hungary.esn.hu/`. System commands (nginx, permissions, MySQL) require `webmaster` with sudo.

### Login shortcut

```bash
ssh webmaster@YOUR_AZURE_IP
sudo su - esn-hungary
cd /home/esn-hungary/htdocs/new-hungary.esn.hu
```

### Drush — Cache

```bash
# Clear cache on one site
vendor/bin/drush --uri=https://new-hungary.esn.hu cr

# Clear cache on all sites
for DOMAIN in new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu lups.esn.hu; do
  vendor/bin/drush --uri=https://$DOMAIN cr
done

# Manually delete compiled cache files (as webmaster if permission denied)
sudo rm -rf /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-hungary.esn.hu/files/php
```

### Drush — Modules

```bash
# Enable a module
vendor/bin/drush --uri=https://new-hungary.esn.hu en MODULE_NAME -y

# Disable a module
vendor/bin/drush --uri=https://new-hungary.esn.hu pmu MODULE_NAME -y

# List enabled modules
vendor/bin/drush --uri=https://new-hungary.esn.hu pml --status=enabled

# Search enabled modules
vendor/bin/drush --uri=https://new-hungary.esn.hu pml --status=enabled | grep MODULE_NAME

# Remove a module from DB that is missing from disk
vendor/bin/drush --uri=https://new-hungary.esn.hu php:eval "
\Drupal::configFactory()->getEditable('core.extension')
  ->clear('module.MODULE_NAME')
  ->save();
echo 'Done';
"
```

### Drush — Database Updates

```bash
# Check for and run pending updates
vendor/bin/drush --uri=https://new-hungary.esn.hu updatedb --yes
```

### Drush — Site Status

```bash
# Full site status
vendor/bin/drush --uri=https://new-hungary.esn.hu status

# Check Drupal version on all sites
for DOMAIN in new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu lups.esn.hu; do
  echo -n "$DOMAIN → "
  vendor/bin/drush --uri=https://$DOMAIN status --field=drupal-version 2>/dev/null
done
```

### Drush — Run PHP

```bash
# Run arbitrary PHP on a site
vendor/bin/drush --uri=https://new-hungary.esn.hu php:eval "echo 'hello';"

# Run a PHP script file
vendor/bin/drush --uri=https://new-hungary.esn.hu php:script scripts/esn_hungary_setup.php

# Disable Full HTML filter_html (run if Full HTML pages lose CSS)
vendor/bin/drush --uri=https://new-hungary.esn.hu php:eval "
\$format = \Drupal\filter\Entity\FilterFormat::load('full_html');
\$format->filters('filter_html')->setConfiguration(['status' => FALSE]);
\$format->save();
echo 'Done';
"
```

### Drush — Users

```bash
# Reset admin password
vendor/bin/drush --uri=https://new-hungary.esn.hu user:password hungary_admin 'NEW_PASSWORD'

# Generate one-time login link
vendor/bin/drush --uri=https://new-hungary.esn.hu uli --name=hungary_admin
```

### Composer

```bash
# Install from lock file
composer install

# Update all packages
composer update

# Update one package
composer update drupal/MODULE_NAME

# Add a new package
composer require drupal/MODULE_NAME

# Reinstall a corrupted package
composer reinstall drupal/core-recommended

# Push scaffold settings
composer drupal:scaffold

# Check installed version of a package
composer show drupal/radix
```

### File Permissions (as webmaster)

```bash
# Make a settings.php temporarily writable
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-bme.esn.hu/settings.php

# Make sites.php temporarily writable
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/sites.php

# Reset all settings.php to read-only
sudo find /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites -name "settings.php" -exec chmod 644 {} \;

# Fix files directory permissions
sudo chmod -R 777 /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-bme.esn.hu/files

# Fix ACL on files directory
sudo setfacl -R -m u:esn-hungary:rwx /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-bme.esn.hu/files
sudo setfacl -R -d -m u:esn-hungary:rwx /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-bme.esn.hu/files

# Make codebase world-readable (needed when section sites can't serve files)
sudo find /home/esn-hungary/htdocs/new-hungary.esn.hu -type d -exec chmod o+rx {} \;
sudo find /home/esn-hungary/htdocs/new-hungary.esn.hu -type f -exec chmod o+r {} \;

# Fix ownership of entire codebase
sudo chown -R esn-hungary:esn-hungary /home/esn-hungary/htdocs/new-hungary.esn.hu

# Fix section user home dir permissions
sudo chmod o+rx /home/esn-new-bme /home/esn-new-bme/htdocs
```

### Finding Things (as webmaster)

```bash
# Find root-owned files in codebase (should be none)
find /home/esn-hungary/htdocs/new-hungary.esn.hu -user root | head -20

# Find all settings.php files
find /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites -name "settings.php"

# Check nginx root for a site
grep "root " /etc/nginx/sites-enabled/new-hungary.esn.hu.conf | head -1

# Check all nginx roots at once
for conf in /etc/nginx/sites-enabled/*.conf; do
  echo "── $(basename $conf)"
  grep "root " "$conf" | head -1
done

# Check PHP-FPM pool for a site
grep "listen" /etc/php/8.3/fpm/pool.d/new-hungary.esn.hu.conf

# List scaffold files
ls /home/esn-hungary/htdocs/new-hungary.esn.hu/scaffold/
```

### Logs (as webmaster)

```bash
# PHP error log for main site
sudo tail -20 /home/esn-hungary/logs/php/error.log

# PHP error log for a section site
sudo tail -20 /home/esn-new-bme/logs/php/error.log

# Follow PHP errors live
sudo tail -f /home/esn-hungary/logs/php/error.log

# nginx error log
sudo tail -20 /var/log/nginx/error.log

# PHP-FPM log
sudo tail -20 /var/log/php8.3-fpm.log
```

### nginx (as webmaster)

```bash
# Test nginx config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# Fix nginx root for a section site
sudo sed -i 's|root .*;|root /home/esn-hungary/htdocs/new-hungary.esn.hu/web;|' \
  /etc/nginx/sites-enabled/new-bme.esn.hu.conf
sudo systemctl reload nginx

# View a site's nginx config
cat /etc/nginx/sites-enabled/new-hungary.esn.hu.conf
```

### PHP-FPM (as webmaster)

```bash
# Check status
sudo systemctl status php8.3-fpm

# Restart
sudo systemctl restart php8.3-fpm

# Check workers running for a site
ps aux | grep "php-fpm" | grep "esn-hungary"

# List all pool configs
ls /etc/php/8.3/fpm/pool.d/
```

### MySQL (as webmaster)

```bash
# Open MySQL as root
mysql -h'127.0.0.1' -P'3306' -u'root' -p -A

# Show master credentials
clpctl db:show:master-credentials

# Fix MySQL auth for a DB user (run inside MySQL prompt)
ALTER USER 'BmeDbUser'@'%' IDENTIFIED WITH mysql_native_password BY 'PASSWORD';
FLUSH PRIVILEGES;

# Check all users
SELECT user, host, plugin FROM mysql.user;
```

### HTTP Status Checks

```bash
# Check one site
curl -s -o /dev/null -w "%{http_code}" https://new-hungary.esn.hu

# Check all 14 sites at once
for DOMAIN in new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu lups.esn.hu; do
  echo -n "$DOMAIN → "
  curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN"
  echo ""
done

# Check DNS resolution
dig new-hungary.esn.hu +short
```

---

## Troubleshooting

### "The website encountered an unexpected error"
```bash
sudo tail -20 /home/esn-hungary/logs/php/error.log
```

### "@radix/form/input.twig is not defined" → 503
Radix was upgraded to v6. Fix (as webmaster then esn-hungary):
```bash
sudo rm -rf /home/esn-hungary/htdocs/new-hungary.esn.hu/web/themes/contrib/radix

# As esn-hungary in codebase root:
composer require "drupal/radix:^5.0"
vendor/bin/drush --uri=https://new-hungary.esn.hu cr
```

### 503 — No PHP-FPM workers
```bash
# As webmaster:
ps aux | grep "php-fpm" | grep "esn-hungary"
sudo systemctl restart php8.3-fpm
curl -s -o /dev/null -w "%{http_code}" https://new-hungary.esn.hu
```

### "core.services.yml is not valid" — caused by UI updater
```bash
# As esn-hungary in codebase root:
composer reinstall drupal/core-recommended
vendor/bin/drush --uri=https://new-hungary.esn.hu cr
```

If still broken:
```bash
# Delete compiled cache manually (as webmaster):
sudo rm -rf /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-hungary.esn.hu/files/php
sudo rm -rf /tmp/update-extraction-*

# Full update (as esn-hungary in codebase root):
composer update
vendor/bin/drush --uri=https://new-hungary.esn.hu updatedb --yes
vendor/bin/drush --uri=https://new-hungary.esn.hu cr
```

### "Missing or invalid module" on updatedb
```bash
# As esn-hungary in codebase root:
vendor/bin/drush --uri=https://new-hungary.esn.hu php:eval "
\Drupal::configFactory()->getEditable('core.extension')
  ->clear('module.MODULE_NAME')
  ->save();
echo 'Done';
"
```

### Full HTML pages losing CSS after edit
The format was changed to Basic HTML. Re-run the filter fix:
```bash
# As esn-hungary in codebase root:
vendor/bin/drush --uri=https://new-hungary.esn.hu php:eval "
\$format = \Drupal\filter\Entity\FilterFormat::load('full_html');
\$format->filters('filter_html')->setConfiguration(['status' => FALSE]);
\$format->save();
echo 'Done';
"
```

### Editing Full HTML pages — correct workflow
Always follow this exact order or content gets wiped:
1. Open the paragraph for editing
2. **FIRST** — change format dropdown to **Full HTML**
3. Click OK on the warning popup
4. **THEN** — click Source button
5. Paste HTML
6. Save

Never change the format after content is already in the field.

### Section site showing wrong nginx root
```bash
# As webmaster:
grep "root " /etc/nginx/sites-enabled/new-bme.esn.hu.conf
sudo sed -i 's|root .*;|root /home/esn-hungary/htdocs/new-hungary.esn.hu/web;|' \
  /etc/nginx/sites-enabled/new-bme.esn.hu.conf
sudo systemctl reload nginx
```

### settings.php not updating after scaffold
```bash
# As webmaster — make it writable first:
sudo chmod u+w /home/esn-hungary/htdocs/new-hungary.esn.hu/web/sites/new-bme.esn.hu/settings.php

# As esn-hungary in codebase root:
composer drupal:scaffold
vendor/bin/drush --uri=https://new-bme.esn.hu cr
```

### SSL 525 error (Cloudflare can't handshake with origin)
Install a self-signed or Cloudflare Origin cert via CloudPanel → SSL/TLS → Custom Certificate. Make sure Cloudflare SSL mode is set to **Full**.

### Let's Encrypt validation fails
Cloudflare proxy is intercepting the ACME challenge. Use self-signed cert (CloudPanel fallback) or Cloudflare Origin Certificate instead.

---

## Verification Checklist

```bash
# All sites returning 200
for DOMAIN in new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu lups.esn.hu; do
  echo -n "$DOMAIN → "
  curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN"
  echo ""
done

# All sites on correct Drupal version (run as esn-hungary in codebase root)
for DOMAIN in new-hungary.esn.hu new-bme.esn.hu new-corvinus.esn.hu new-debrecen.esn.hu new-elte.esn.hu new-eszterhazy.esn.hu new-ibs.esn.hu mate.esn.hu new-miskolc.esn.hu new-obuda.esn.hu new-pecs.esn.hu semmelweis.esn.hu new-szeged.esn.hu lups.esn.hu; do
  echo -n "$DOMAIN → "
  vendor/bin/drush --uri=https://$DOMAIN status --field=drupal-version 2>/dev/null
done
```

**Manual checks in browser:**
```
✅ https://new-hungary.esn.hu/               → Homepage with flag strip and all 13 section links
✅ https://new-hungary.esn.hu/about-us       → Full ESN Hungary content with section list
✅ https://new-hungary.esn.hu/form/contact-us → Contact form with Turnstile CAPTCHA
✅ https://new-hungary.esn.hu/privacy-policy  → Full privacy policy
✅ https://new-hungary.esn.hu/admin/reports/status → 0 errors
✅ https://new-bme.esn.hu/                   → Section home page loads
✅ https://new-bme.esn.hu/form/contact-us    → Contact form with Turnstile
✅ https://new-bme.esn.hu/admin/reports/status → 0 errors
(repeat section checks for all 13 sections)
```
