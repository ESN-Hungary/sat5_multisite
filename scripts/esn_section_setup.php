<?php
/**
 * ESN Hungary SECTION SITE setup script.
 * Run after drush site:install on each of the 13 section sites.
 * vendor/bin/drush --uri=https://SECTION.esn.hu php:script scripts/esn_section_setup.php
 */

$node_storage      = \Drupal::entityTypeManager()->getStorage('node');
$menu_storage      = \Drupal::entityTypeManager()->getStorage('menu_link_content');
$paragraph_storage = \Drupal::entityTypeManager()->getStorage('paragraph');

function make_paragraph($paragraph_storage, $body) {
  $p = $paragraph_storage->create([
    'type'       => 'text',
    'field_text' => ['value' => $body, 'format' => 'full_html'],
  ]);
  $p->save();
  return ['target_id' => $p->id(), 'target_revision_id' => $p->getRevisionId()];
}

// ── 1. Enable modules ──────────────────────────────────────────────────────
$modules = [
  'externalauth', 'openid_connect', 'satellite_user', 'satellite_api',
  'eu_cookie_compliance', 'webform', 'webform_ui', 'captcha', 'turnstile',
];
foreach ($modules as $module) {
  if (!\Drupal::moduleHandler()->moduleExists($module)) {
    \Drupal::service('module_installer')->install([$module]);
    echo "✓ Enabled $module\n";
  } else {
    echo "→ $module already enabled\n";
  }
}

// ── 2. Disable filter_html on Full HTML ────────────────────────────────────
$format = \Drupal\filter\Entity\FilterFormat::load('full_html');
$format->filters('filter_html')->setConfiguration(['status' => FALSE]);
$format->save();
echo "✓ Full HTML filter_html disabled\n";

// ── 3. Create Contact Us webform with Turnstile ────────────────────────────
if (!\Drupal\webform\Entity\Webform::load('contact_us')) {
  $webform = \Drupal\webform\Entity\Webform::create([
    'id' => 'contact_us', 'title' => 'Contact Us', 'status' => 'open',
  ]);
  $webform->setElements([
    'full_name' => ['#type' => 'textfield', '#title' => 'Full Name', '#required' => TRUE],
    'email'     => ['#type' => 'email',     '#title' => 'Email',     '#required' => TRUE],
    'message'   => ['#type' => 'textarea',  '#title' => 'Message',   '#required' => TRUE, '#rows' => 5],
    'gdpr_text' => [
      '#type'   => 'webform_markup',
      '#markup' => '<p><small>This section of ESN Hungary will store the data submitted by you only for the purpose of processing your message.</small></p>',
    ],
    'data_processing_agreement' => [
      '#type'    => 'checkboxes',
      '#title'   => 'Do you agree to the data processing terms?',
      '#options' => ['yes' => 'Yes, I agree!'],
      '#required' => TRUE,
    ],
    'captcha' => [
      '#type'         => 'captcha',
      '#captcha_type' => 'turnstile/Turnstile',
    ],
  ]);
  $webform->save();
  echo "✓ Contact Us webform created (with Turnstile)\n";
} else {
  echo "→ Contact Us webform already exists\n";
}

// ── 4. Create pages ────────────────────────────────────────────────────────
// Home is left empty — each section fills in their own content via the admin UI
$pages = [
  'home'           => ['title' => 'Home',          'body' => ''],
  'about-us'       => ['title' => 'About Us',       'body' => '<p>Welcome to our ESN section. We are part of the Erasmus Student Network, the largest student organisation in Europe. Update this page with your section information.</p>'],
  'partners'       => ['title' => 'Partners',       'body' => '<p>We are proud to work with our partners to support international students. Update this page with your section partners.</p>'],
  'privacy-policy' => ['title' => 'Privacy Policy', 'body' => '<p>This section of ESN Hungary follows the ESN Hungary privacy policy. For details please visit <a href="https://new-hungary.esn.hu/privacy-policy">ESN Hungary Privacy Policy</a> or contact your local section committee.</p>'],
];

foreach ($pages as $alias => $page) {
  $existing = \Drupal::entityQuery('node')
    ->condition('type', 'basic_page')
    ->condition('title', $page['title'])
    ->accessCheck(FALSE)
    ->execute();

  if (empty($existing)) {
    $field_body = [];
    if (!empty($page['body'])) {
      $field_body[] = make_paragraph($paragraph_storage, $page['body']);
    }
    $node = $node_storage->create([
      'type'       => 'basic_page',
      'title'      => $page['title'],
      'field_body' => $field_body,
      'status'     => 1,
      'uid'        => 1,
      'path'       => ['alias' => '/' . $alias],
    ]);
    $node->save();
    echo "✓ Created page: " . $page['title'] . "\n";
  } else {
    echo "→ Page already exists: " . $page['title'] . "\n";
  }
}

// ── 5. Menu items ──────────────────────────────────────────────────────────
$menu_items = [
  ['title' => 'Home',     'uri' => 'internal:/',                'weight' => 0],
  ['title' => 'About Us', 'uri' => 'internal:/about-us',        'weight' => 1],
  ['title' => 'News',     'uri' => 'internal:/news',            'weight' => 2],
  ['title' => 'Partners', 'uri' => 'internal:/partners',        'weight' => 3],
  ['title' => 'Contact',  'uri' => 'internal:/form/contact-us', 'weight' => 4],
];

foreach ($menu_items as $item) {
  $existing = \Drupal::entityQuery('menu_link_content')
    ->condition('title', $item['title'])
    ->condition('menu_name', 'main')
    ->accessCheck(FALSE)
    ->execute();
  if (empty($existing)) {
    $menu_storage->create([
      'title' => $item['title'], 'link' => ['uri' => $item['uri']],
      'menu_name' => 'main', 'weight' => $item['weight'], 'expanded' => FALSE,
    ])->save();
    echo "✓ Created menu item: " . $item['title'] . "\n";
  } else {
    echo "→ Menu item already exists: " . $item['title'] . "\n";
  }
}

// ── 6. Site settings ───────────────────────────────────────────────────────
\Drupal::configFactory()->getEditable('system.site')
  ->set('page.front', '/home')->save(TRUE);
echo "✓ Front page set to /home\n";

\Drupal::configFactory()->getEditable('system.date')
  ->set('timezone.default', 'Europe/Budapest')->save(TRUE);
echo "✓ Timezone set to Europe/Budapest\n";

\Drupal::configFactory()->getEditable('eu_cookie_compliance.settings')
  ->set('popup_link', '/privacy-policy')
  ->set('popup_agree_button_message', 'Accept')
  ->set('popup_disagree_button_message', 'No thanks')
  ->set('popup_info', '<p>We use cookies on this site to enhance your user experience.<br>By clicking the Accept button, you agree to us doing so.<br><a href="/privacy-policy">More info</a></p>')
  ->save(TRUE);
echo "✓ EU Cookie Compliance configured\n";

drupal_flush_all_caches();
echo "✓ Cache cleared\n";
echo "\n✅ Section setup complete! Edit About Us and Home page content via the admin UI.\n";
