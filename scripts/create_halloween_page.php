<?php

/**
 * Creates the Halloween in Transylvania page.
 * Run with:
 * vendor/bin/drush --uri=https://sitemain.esn.hu php:script scripts/create_halloween_page.php
 */

$node_storage      = \Drupal::entityTypeManager()->getStorage('node');
$paragraph_storage = \Drupal::entityTypeManager()->getStorage('paragraph');

function make_text($paragraph_storage, $body) {
  $p = $paragraph_storage->create([
    'type'       => 'text',
    'field_text' => ['value' => $body, 'format' => 'full_html'],
  ]);
  $p->save();
  return ['target_id' => $p->id(), 'target_revision_id' => $p->getRevisionId()];
}

function make_text_title_link($paragraph_storage, $title, $body, $link_text = NULL, $link_url = NULL) {
  $values = [
    'type'        => 'text_with_title_and_link',
    'field_title' => $title,
    'field_text'  => ['value' => $body, 'format' => 'full_html'],
  ];
  if ($link_text && $link_url) {
    $values['field_link'] = ['uri' => $link_url, 'title' => $link_text];
  }
  $p = $paragraph_storage->create($values);
  $p->save();
  return ['target_id' => $p->id(), 'target_revision_id' => $p->getRevisionId()];
}

$field_body = [];

$field_body[] = make_text_title_link(
  $paragraph_storage,
  'Halloween in Transylvania',
  '<p><strong>The Erasmus Experience You\'ll Never Forget</strong> — a cinematic, high-energy journey through castles, medieval towns, Halloween costumes and unforgettable student memories.</p>',
  'Read the story', 'internal:#article'
);

$field_body[] = make_text($paragraph_storage,
  '<p>🏰 <strong>Castles</strong> — cinematic locations for strong visuals<br>
   🎭 <strong>Costumes</strong> — high-energy photos and party moments<br>
   🌍 <strong>Community</strong> — Erasmus friendships and shared memories<br>
   ✨ <strong>Atmosphere</strong> — mystery, travel and celebration in one</p>'
);

$field_body[] = make_text_title_link(
  $paragraph_storage,
  '01 / What Is Halloween in Transylvania?',
  '<p>Halloween in Transylvania (HIT) is a national Erasmus project that brings together international students studying in Romania for a unique Halloween adventure.</p>
   <p>Instead of celebrating Halloween in a regular club or student dorm, participants travel to Transylvania — the region famous for its castles, medieval towns, and the legendary Dracula story.</p>
   <p>The project combines exploring the region, meeting fellow Erasmus students, and celebrating Halloween in one of the most atmospheric places in Europe.</p>
   <p>More than a Halloween project, this is a story of friendship, adventure and unforgettable Erasmus memories.</p>'
);

$field_body[] = make_text($paragraph_storage,
  '<h2>02 / How It All Started</h2>
   <p><strong>01 — The Idea</strong><br>The idea behind Halloween in Transylvania was simple: create an unforgettable experience for Erasmus and international students.</p>
   <p><strong>02 — Built by ESN</strong><br>Organized by ESN, the project was designed as a national gathering combining travel, culture, and social activities.</p>
   <p><strong>03 — Why Transylvania</strong><br>Choosing Transylvania as the setting felt natural. Known worldwide for medieval towns, historic castles, and its association with the Dracula legend, the region offers the perfect atmosphere.</p>
   <p><strong>04 — A Student Tradition</strong><br>Over time, the project grew into one of the most anticipated experiences for Erasmus students.</p>'
);

$field_body[] = make_text_title_link(
  $paragraph_storage,
  '03 / What to Expect',
  '<p><strong>🏰 Explore iconic landmarks</strong><br>Castles, mountain views and Transylvanian atmosphere.</p>
   <p><strong>🏙️ Discover medieval cities</strong><br>Historic streets, architecture and strong travel visuals.</p>
   <p><strong>🎃 Celebrate Halloween</strong><br>Costumes, lights, music and unforgettable energy.</p>
   <p><strong>🌍 Meet the Erasmus Generation</strong><br>International friendships and the social spirit of Erasmus.</p>
   <p><strong>📸 Create unforgettable memories</strong><br>The kind that instantly make the page feel alive.</p>'
);

$field_body[] = make_text_title_link(
  $paragraph_storage,
  '04 / How to Join',
  '<p>If you are an Erasmus or international student, joining the project is simple. Registration is done through your local ESN section.</p>
   <p><strong>01 — Contact your local ESN section</strong><br>Stay connected with the team in your city.</p>
   <p><strong>02 — Register when spots open</strong><br>Follow announcements and complete the process on time.</p>
   <p><strong>03 — Prepare your best costume</strong><br>Then get ready for your adventure.</p>'
);

$field_body[] = make_text($paragraph_storage,
  '<h2>A Story Worth Telling</h2>
   <p>Erasmus is full of unforgettable moments. This brings all of that together in a single experience.</p>
   <p>Because celebrating Halloween in the land of Dracula, surrounded by students from all over Europe, is not just a party.</p>
   <p><strong>It\'s an Erasmus story waiting to happen. 🎃</strong></p>'
);

// Create or update the node — uses field_body (NOT field_paragraphs)
$existing = \Drupal::entityQuery('node')
  ->condition('type', 'basic_page')
  ->condition('title', 'Halloween in Transylvania')
  ->accessCheck(FALSE)
  ->execute();

if (!empty($existing)) {
  $node = $node_storage->load(reset($existing));
  echo "→ Page already exists, updating...\n";
} else {
  $node = $node_storage->create(['type' => 'basic_page', 'title' => 'Halloween in Transylvania']);
}

$node->set('field_body', $field_body);
$node->set('status', 1);
$node->set('uid', 1);
$node->set('path', ['alias' => '/halloween-in-transylvania']);
$node->save();

echo "✓ Page created: /halloween-in-transylvania\n";
echo "✓ Visit: https://sitemain.esn.hu/halloween-in-transylvania\n";

drupal_flush_all_caches();
echo "✓ Cache cleared\n";
