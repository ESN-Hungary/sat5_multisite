<?php
/**
 * ESN Hungary MAIN SITE setup script.
 * Run after drush site:install on new-hungary.esn.hu ONLY.
 * vendor/bin/drush --uri=https://new-hungary.esn.hu php:script scripts/esn_hungary_setup.php
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
      '#markup' => '<p><small>ESN Hungary will store the data submitted by you only for the purpose of processing your message.</small></p>',
    ],
    'data_processing_agreement' => [
      '#type'    => 'checkboxes',
      '#title'   => 'Do you agree to the data processing terms?',
      '#options' => ['yes' => 'Yes, I agree!'],
      '#required' => TRUE,
    ],
    'captcha' => [
      '#type'           => 'captcha',
      '#captcha_type'   => 'turnstile/Turnstile',
    ],
  ]);
  $webform->save();
  echo "✓ Contact Us webform created (with Turnstile)\n";
} else {
  echo "→ Contact Us webform already exists\n";
}

// ── 4. Homepage HTML ───────────────────────────────────────────────────────
// NOTE: After setup, go to Content → Home → Edit and upload real photos.
// Replace YOUR_MAIN_PHOTO / YOUR_ABOUT_PHOTO / YOUR_MAP_PHOTO with real image URLs.
$home_html = <<<'HOME_HTML'
<style>
@import url('https://fonts.googleapis.com/css2?family=Francois+One&family=Lato:wght@400;700;900&display=swap');
:root{
  --cyan:#00AEEF;--cyan-dark:#0090C5;--red:#CE2939;--green:#7AC143;
  --text:#111;--muted:#666;--line:#ebebeb;--soft:#f9f9f9;
  --shadow:0 8px 32px rgba(0,0,0,.07);--r:20px;
}
.hu *{box-sizing:border-box;}
.hu h1,.hu h2,.hu h3,.hu h4{font-family:"Francois One",Arial,sans-serif;font-weight:400;letter-spacing:-.5px;margin:0 0 14px;line-height:1.05;color:var(--text);}
.hu p{font-family:"Lato",Arial,sans-serif;color:var(--muted);margin:0 0 14px;line-height:1.7;font-size:1rem;}
.hu a{text-decoration:none;}
.hu img{max-width:100%;display:block;}
.hu-strip{height:5px;background:linear-gradient(90deg,var(--red) 33%,#fff 33%,#fff 66%,var(--green) 66%);}
.hu-hero{background:#fff;padding:5rem 2rem 4rem;}
.hu-hero-grid{display:grid;grid-template-columns:1fr 1fr;gap:5rem;align-items:center;max-width:1100px;margin:0 auto;}
.hu-eyebrow{display:block;font-family:"Lato",Arial,sans-serif;font-size:.72rem;font-weight:900;text-transform:uppercase;letter-spacing:.2em;color:var(--red);margin-bottom:14px;}
.hu-hero h1{font-size:clamp(2.6rem,5vw,4.8rem);margin-bottom:1.2rem;}
.hu-hero h1 em{font-style:normal;color:var(--cyan);}
.hu-hero p{font-size:1.1rem;max-width:440px;margin-bottom:2rem;}
.hu-actions{display:flex;gap:12px;flex-wrap:wrap;}
.hu-btn{display:inline-flex;align-items:center;height:48px;padding:0 24px;border-radius:999px;font-family:"Lato",Arial,sans-serif;font-weight:700;font-size:.92rem;text-decoration:none;border:2px solid transparent;transition:.2s;}
.hu-btn-red{background:var(--red);color:#fff;}
.hu-btn-red:hover{background:#b01e2d;}
.hu-btn-outline{background:#fff;color:var(--text);border-color:var(--line);}
.hu-btn-outline:hover{border-color:#bbb;}
.hu-btn-cyan{background:var(--cyan);color:#fff;}
.hu-btn-cyan:hover{background:var(--cyan-dark);}
.hu-hero-visual{display:grid;grid-template-columns:1fr 1fr;grid-template-rows:1fr 1fr;gap:12px;height:440px;}
.hu-ph{border-radius:var(--r);background:#e4eaf0;background-size:cover;background-position:center;}
.hu-ph-main{grid-row:1/span 2;border-radius:24px;}
.hu-stats{border-top:1px solid var(--line);border-bottom:1px solid var(--line);}
.hu-stats-grid{display:grid;grid-template-columns:repeat(4,1fr);max-width:1100px;margin:0 auto;}
.hu-stat{padding:2rem 1rem;text-align:center;border-right:1px solid var(--line);}
.hu-stat:last-child{border:none;}
.hu-stat-n{font-family:"Francois One",Arial,sans-serif;font-size:2.6rem;color:var(--cyan);letter-spacing:-1px;display:block;margin-bottom:4px;}
.hu-stat-l{font-family:"Lato",Arial,sans-serif;font-size:.72rem;color:var(--muted);text-transform:uppercase;letter-spacing:.1em;font-weight:700;}
.hu-about{padding:6rem 2rem;background:#fff;}
.hu-about-grid{display:grid;grid-template-columns:1fr 1fr;gap:6rem;align-items:center;max-width:1100px;margin:0 auto;}
.hu-about-img{border-radius:24px;background:#e4eaf0;height:400px;position:relative;box-shadow:var(--shadow);background-size:cover;background-position:center;}
.hu-about-badge{position:absolute;bottom:-18px;right:-18px;background:#fff;border:1px solid var(--line);border-radius:16px;padding:1rem 1.4rem;font-family:"Lato",Arial,sans-serif;font-size:.88rem;font-weight:700;color:var(--text);box-shadow:var(--shadow);line-height:1.6;text-align:center;}
.hu-about h2{font-size:clamp(1.9rem,3vw,3rem);}
.hu-about h2 em{font-style:normal;color:var(--red);}
.hu-pills{display:flex;flex-wrap:wrap;gap:8px;margin-top:1.2rem;}
.hu-pill{padding:7px 16px;border-radius:999px;font-family:"Lato",Arial,sans-serif;font-size:.82rem;font-weight:700;}
.hu-pill-c{background:rgba(0,174,239,.1);color:var(--cyan);}
.hu-pill-r{background:rgba(206,41,57,.08);color:var(--red);}
.hu-pill-g{background:rgba(122,193,67,.1);color:#4a8a10;}
.hu-map{padding:6rem 2rem;background:var(--soft);}
.hu-map-inner{max-width:1100px;margin:0 auto;}
.hu-map-header{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:3rem;}
.hu-map-header h2{font-size:clamp(1.9rem,3vw,3rem);margin:0;}
.hu-map-header h2 em{font-style:normal;color:var(--cyan);}
.hu-map-grid{display:grid;grid-template-columns:1.3fr 1fr;gap:3rem;align-items:start;}
.hu-map-img{border-radius:24px;background:#dce6f0;height:460px;box-shadow:var(--shadow);position:relative;overflow:hidden;background-size:cover;background-position:center;}
.hu-map-img-label{position:absolute;top:16px;left:16px;background:rgba(255,255,255,.95);border-radius:999px;padding:7px 16px;font-family:"Lato",Arial,sans-serif;font-size:.78rem;font-weight:700;color:var(--text);}
.hu-sec-list{display:grid;grid-template-columns:1fr 1fr;gap:10px;}
.hu-sec-link{border:1px solid var(--line);border-radius:12px;padding:12px 14px;background:#fff;display:flex;align-items:center;gap:10px;text-decoration:none;transition:.15s;}
.hu-sec-link:hover{border-color:var(--cyan);box-shadow:0 4px 16px rgba(0,174,239,.1);}
.hu-sec-dot{width:8px;height:8px;border-radius:50%;background:var(--cyan);flex-shrink:0;}
.hu-sec-name{font-family:"Lato",Arial,sans-serif;font-size:.88rem;font-weight:700;color:var(--text);display:block;}
.hu-sec-city{font-size:.75rem;color:var(--muted);display:block;}
.hu-cta{padding:6rem 2rem;background:#fff;border-top:1px solid var(--line);text-align:center;}
.hu-cta-inner{max-width:640px;margin:0 auto;}
.hu-cta h2{font-size:clamp(1.9rem,3vw,3rem);margin-bottom:1rem;}
.hu-cta h2 em{font-style:normal;color:var(--red);}
.hu-cta p{font-size:1.05rem;margin-bottom:2rem;}
.hu-cta-actions{display:flex;gap:12px;justify-content:center;flex-wrap:wrap;}
@media(max-width:960px){
  .hu-hero-grid,.hu-about-grid,.hu-map-grid{grid-template-columns:1fr;gap:2.5rem;}
  .hu-hero-visual{height:280px;}
  .hu-stats-grid{grid-template-columns:1fr 1fr;}
  .hu-map-header{flex-direction:column;align-items:flex-start;gap:1rem;}
  .hu-about-badge{right:0;bottom:-14px;}
}
@media(max-width:600px){
  .hu-hero-visual{grid-template-columns:1fr;height:auto;}
  .hu-ph-main{grid-row:auto;height:200px;}
  .hu-ph{height:140px;}
  .hu-sec-list{grid-template-columns:1fr;}
  .hu-stats-grid{grid-template-columns:1fr 1fr;}
}
</style>
<div class="hu">
<div class="hu-strip"></div>
<section class="hu-hero">
  <div class="hu-hero-grid">
    <div>
      <span class="hu-eyebrow">Erasmus Student Network Hungary</span>
      <h1>Students<br>Helping<br><em>Students</em></h1>
      <p>ESN Hungary supports international students throughout their Erasmus journey — from arrival to departure and everything in between.</p>
      <div class="hu-actions">
        <a class="hu-btn hu-btn-red" href="/about-us">Learn About Us</a>
        <a class="hu-btn hu-btn-outline" href="/partners">Our Partners</a>
      </div>
    </div>
    <div class="hu-hero-visual">
      <div class="hu-ph hu-ph-main" style="background-image:url('YOUR_MAIN_PHOTO');"></div>
      <div class="hu-ph" style="background-image:url('YOUR_TOP_PHOTO');"></div>
      <div class="hu-ph" style="background-image:url('YOUR_BOTTOM_PHOTO');"></div>
    </div>
  </div>
</section>
<div class="hu-stats">
  <div class="hu-stats-grid">
    <div class="hu-stat"><span class="hu-stat-n">13</span><span class="hu-stat-l">Local Sections</span></div>
    <div class="hu-stat"><span class="hu-stat-n">500+</span><span class="hu-stat-l">Volunteers</span></div>
    <div class="hu-stat"><span class="hu-stat-n">1000+</span><span class="hu-stat-l">Students Helped</span></div>
    <div class="hu-stat"><span class="hu-stat-n">30+</span><span class="hu-stat-l">Events Per Year</span></div>
  </div>
</div>
<section class="hu-about">
  <div class="hu-about-grid">
    <div style="position:relative;">
      <div class="hu-about-img" style="background-image:url('YOUR_ABOUT_PHOTO');"></div>
      <div class="hu-about-badge">🇭🇺 ESN Hungary<br>Est. 1992</div>
    </div>
    <div>
      <span class="hu-eyebrow">About ESN Hungary</span>
      <h2>We Make <em>Erasmus</em> Better</h2>
      <p>ESN Hungary is the national Erasmus Student Network, connecting international students with local volunteers across Hungary's finest universities.</p>
      <p>We organise cultural events, city tours, language exchanges and national projects that turn a semester abroad into a lifetime memory.</p>
      <div class="hu-pills">
        <span class="hu-pill hu-pill-c">Cultural Events</span>
        <span class="hu-pill hu-pill-r">National Projects</span>
        <span class="hu-pill hu-pill-g">Language Exchange</span>
        <span class="hu-pill hu-pill-c">City Tours</span>
        <span class="hu-pill hu-pill-r">Buddy System</span>
      </div>
    </div>
  </div>
</section>
<section class="hu-map">
  <div class="hu-map-inner">
    <div class="hu-map-header">
      <div>
        <span class="hu-eyebrow">Our Network</span>
        <h2>Find Your <em>Section</em></h2>
      </div>
      <a class="hu-btn hu-btn-outline" href="/about-us">About ESN Hungary</a>
    </div>
    <div class="hu-map-grid">
      <div style="position:relative;">
        <div class="hu-map-img" style="background-image:url('YOUR_MAP_PHOTO');">
          <div class="hu-map-img-label">🗺️ Hungary — 13 Sections</div>
        </div>
      </div>
      <div class="hu-sec-list">
        <a class="hu-sec-link" href="https://new-bme.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN BME</span><span class="hu-sec-city">Budapest</span></div></a>
        <a class="hu-sec-link" href="https://new-corvinus.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Corvinus</span><span class="hu-sec-city">Budapest</span></div></a>
        <a class="hu-sec-link" href="https://new-debrecen.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Debrecen</span><span class="hu-sec-city">Debrecen</span></div></a>
        <a class="hu-sec-link" href="https://new-elte.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN ELTE</span><span class="hu-sec-city">Budapest</span></div></a>
        <a class="hu-sec-link" href="https://new-eszterhazy.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Eszterházy</span><span class="hu-sec-city">Eger</span></div></a>
        <a class="hu-sec-link" href="https://new-ibs.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN IBS</span><span class="hu-sec-city">Budapest</span></div></a>
        <a class="hu-sec-link" href="https://lups.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN LUPS</span><span class="hu-sec-city">Budapest</span></div></a>
        <a class="hu-sec-link" href="https://mate.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN MATE</span><span class="hu-sec-city">Gödöllő</span></div></a>
        <a class="hu-sec-link" href="https://new-miskolc.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Miskolc</span><span class="hu-sec-city">Miskolc</span></div></a>
        <a class="hu-sec-link" href="https://new-obuda.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Óbuda</span><span class="hu-sec-city">Budapest</span></div></a>
        <a class="hu-sec-link" href="https://new-pecs.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Pécs</span><span class="hu-sec-city">Pécs</span></div></a>
        <a class="hu-sec-link" href="https://semmelweis.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Semmelweis</span><span class="hu-sec-city">Budapest</span></div></a>
        <a class="hu-sec-link" href="https://new-szeged.esn.hu"><div class="hu-sec-dot"></div><div><span class="hu-sec-name">ESN Szeged</span><span class="hu-sec-city">Szeged</span></div></a>
      </div>
    </div>
  </div>
</section>
<section class="hu-cta">
  <div class="hu-cta-inner">
    <span class="hu-eyebrow">Join the Network</span>
    <h2>Ready to Get <em>Involved?</em></h2>
    <p>Whether you are an Erasmus student looking for support or a local student wanting to volunteer — ESN Hungary has a place for you.</p>
    <div class="hu-cta-actions">
      <a class="hu-btn hu-btn-cyan" href="/form/contact-us">Contact Us</a>
      <a class="hu-btn hu-btn-outline" href="/about-us">Learn More</a>
    </div>
  </div>
</section>
</div>
HOME_HTML;

$about_us_body = '<h2>About ESN</h2>
<p><strong>Erasmus Student Network (ESN) is one of the biggest student associations in Europe</strong>. It was born on the 16th October 1989 and legally registered in 1990 for supporting and developing student exchange.</p>
<p>We are present in more than 1000 Higher Education Institutions from 42 countries. The network is constantly developing and expanding. We have around 15,000 active members that are in many sections supported by so-called buddies mainly taking care of international students. Thus, ESN involves around 40,000 young people offering its services to around 350,000 international students every year.</p>
<p>ESN is working in Higher Education (HE):</p>
<ul>
<li>offering services to <strong>350,000 students</strong></li>
<li><strong>15,000</strong> active members (<strong>40,000</strong> with the buddies included)</li>
<li>mainly on a <strong>volunteer</strong> basis</li>
<li>with an average annual growth rate of <strong>12%</strong> since 2005</li>
</ul>
<p>ESN is operating on three levels: local, national, and international.</p>
<p>ESN works for the creation of a more mobile and flexible education environment by supporting and developing the student exchange from different levels and providing an intercultural experience also to those students who cannot access a period abroad.</p>
<h2>Aims &amp; Principles</h2>
<p>In synthesis, ESN:</p>
<ul>
<li>works in the interest of international students</li>
<li>works to improve the social and practical integration of international students</li>
<li>represents the needs and rights of international students on the local, national, and international level</li>
<li>provides relevant information about mobility programmes</li>
<li>motivates students to study abroad</li>
<li>works with the reintegration of homecoming students</li>
<li>contributes to the improvement and accessibility of student mobility</li>
<li>cares about its members</li>
<li>values volunteering and active citizenship</li>
</ul>
<h2>Who are we for?</h2>
<h3>Homecoming students</h3>
<p>The students who are returning from an exchange are being supported in the reintegration process in their home countries by keeping contact with an international environment. Many local sections are set up by former exchange students, often because they have had good experiences from their exchange period or because they felt a lack of help during their exchange.</p>
<h3>Exchange students</h3>
<p>The main focus of ESN is placed on current exchange students, who often face problems in their new environments. Therefore, ESN offers help in the academic, social and practical integration process. This is mainly done through activities in the local sections, which include cultural and social events such as trips to various places within the country, film nights, language projects, international food festivals and last, but not least, parties.</p>
<h2>ESN Hungary</h2>
<p>Erasmus Student Network Hungary is one of the National Organisations of the Erasmus Student Network.</p>
<p>ESN Hungary has local sections in 13 Hungarian Higher Education Institutions with around 400 volunteers who represent and support Erasmus and International Students coming to study in Hungary.</p>
<p>The main aim of ESN Hungary is to support international students with orientation and integration in Hungary, provide guidance and support to Erasmus society committees, encourage and promote the Erasmus programme to potential students from Hungary, and represent Hungary and its member universities at the international level of ESN.</p>
<h2>Our Sections</h2>
<ul>
<li><strong>ESN BME</strong> — Budapest University of Technology and Economics</li>
<li><strong>ESN Corvinus</strong> — Corvinus University of Budapest</li>
<li><strong>ESN Debrecen</strong> — University of Debrecen</li>
<li><strong>ESN ELTE</strong> — Eötvös Loránd University, Budapest</li>
<li><strong>ESN Eszterházy</strong> — Eszterházy Károly Catholic University, Eger</li>
<li><strong>ESN IBS</strong> — International Business School, Budapest</li>
<li><strong>ESN LUPS</strong> — Budapest</li>
<li><strong>ESN MATE</strong> — Hungarian University of Agriculture and Life Sciences, Gödöllő</li>
<li><strong>ESN Miskolc</strong> — University of Miskolc</li>
<li><strong>ESN Óbuda</strong> — Óbuda University, Budapest</li>
<li><strong>ESN Pécs</strong> — University of Pécs</li>
<li><strong>ESN Semmelweis</strong> — Semmelweis University, Budapest</li>
<li><strong>ESN Szeged</strong> — University of Szeged</li>
</ul>';

$privacy_body = '<h2>Privacy Policy</h2>
<p>When you use our services, you are trusting us with your information. We understand this is a big responsibility and we work hard to protect your information and put you in control.</p>
<p>By visiting our websites, applying for an opportunity/product/project or otherwise providing us with your personal information, you consent to your personal information being collected, used and disclosed as set out in this Privacy Policy.</p>
<h2>1. About Us</h2>
<p>In this Privacy Policy, references to "ESN Hungary", "ESN", "we", "us" or "our" are to Magyarországi Nemzetközi Hallgatókért Egyesület, registered in Debrecen, Hungary, Simonffy u. 4-6. Fsz. 41., 4025, entered into the National Court Register under number: 13-02-0007322, Tax ID: 18944273-1-13.</p>
<p>If you have any questions about your personal information, please contact us via <a href="mailto:webmaster@esn.hu">webmaster@esn.hu</a>.</p>
<h2>2. Collection of Information</h2>
<p>When you access our website, respond to surveys, register to participate in an event organized by ESN Hungary, or order ESNcard - we may collect, store and use certain of your personal information in line with this Privacy Policy.</p>
<p>We may also collect data relating to your visits to our websites that cannot identify you but records your use of our platform.</p>
<h2>3. Use of Information</h2>
<p>We use the information you provide to process your requests, respond to your enquiries, provide you with information about events and activities, and improve our services.</p>
<p>We will not sell, distribute or lease your personal information to third parties unless we have your permission or are required by law to do so.</p>
<h2>4. Your Rights</h2>
<p>Under GDPR you have the following rights:</p>
<ul>
<li>Right of subject access</li>
<li>Right to rectification</li>
<li>Right to erasure ("right to be forgotten")</li>
<li>Right to restriction of processing</li>
<li>Right to object</li>
<li>Right to data portability</li>
</ul>
<p>You can exercise any of these rights by e-mailing us at <a href="mailto:webmaster@esn.hu">webmaster@esn.hu</a>.</p>
<h2>5. Cookies</h2>
<p>Our websites use cookies. Cookies are small files stored on your computer hard drive which are used to identify your browsing sessions and to remember some of your preferences. We use cookies to:</p>
<ul>
<li>Analyse our web traffic</li>
<li>Identify you when you return to our website</li>
<li>Store information about your preferences</li>
</ul>
<p>You can choose to accept or decline cookies. If you decline cookies some features of the website may not function correctly.</p>
<h2>6. Third Party Links</h2>
<p>Our website may contain links to other websites of interest. Once you have used these links to leave our site, you should note that we do not have any control over that other website.</p>
<h2>7. Contact</h2>
<p>Magyarországi Nemzetközi Hallgatókért Egyesület (MNHE)<br>
e-mail: <a href="mailto:communication@esn.hu">communication@esn.hu</a></p>';

// ── 5. Create pages ────────────────────────────────────────────────────────
$pages = [
  'home'           => ['title' => 'Home',          'body' => $home_html],
  'about-us'       => ['title' => 'About Us',       'body' => $about_us_body],
  'partners'       => ['title' => 'Partners',       'body' => '<p>We are proud to work with our partners to support international students in Hungary. Partner information coming soon.</p>'],
  'privacy-policy' => ['title' => 'Privacy Policy', 'body' => $privacy_body],
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

// ── 6. Menu items ──────────────────────────────────────────────────────────
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

// ── 7. Site settings ───────────────────────────────────────────────────────
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
echo "\n✅ ESN Hungary MAIN SITE setup complete!\n";
echo "⚠️  Remember to upload photos and replace YOUR_MAIN_PHOTO / YOUR_ABOUT_PHOTO / YOUR_MAP_PHOTO in the Home page.\n";
