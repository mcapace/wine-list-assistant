/**
 * Seed script for Wine List Assistant
 *
 * Usage:
 *   1. Set environment variables (SUPABASE_URL, SUPABASE_SERVICE_KEY, ALGOLIA_*)
 *   2. Place your Top 100 JSON file at ../data/top100-2024.json
 *   3. Run: npx tsx scripts/seed.ts
 */

import { createClient } from '@supabase/supabase-js';
import algoliasearch from 'algoliasearch';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

// Types
interface WineInput {
  producer: string;
  name: string;
  vintage: number | null;
  region: string;
  sub_region?: string;
  appellation?: string;
  country: string;
  color: 'red' | 'white' | 'rose' | 'sparkling' | 'dessert' | 'fortified';
  grape_varieties?: { name: string; percentage?: number }[];
  alcohol?: number;
  score: number;
  tasting_note: string;
  reviewer_initials: string;
  reviewer_name?: string;
  review_date: string;
  issue_date?: string;
  drink_window_start?: number;
  drink_window_end?: number;
  release_price?: number;
}

// Initialize clients
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY!;
const algoliaAppId = process.env.ALGOLIA_APP_ID!;
const algoliaApiKey = process.env.ALGOLIA_API_KEY!;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY');
  process.exit(1);
}

if (!algoliaAppId || !algoliaApiKey) {
  console.error('Missing ALGOLIA_APP_ID or ALGOLIA_API_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);
const algolia = algoliasearch(algoliaAppId, algoliaApiKey);
const wineIndex = algolia.initIndex('wines');

async function seed() {
  console.log('🍷 Wine List Assistant - Database Seeder\n');

  // Load wine data
  const dataPath = join(__dirname, '../data/top100-2024.json');

  if (!existsSync(dataPath)) {
    console.log('📁 No data file found at:', dataPath);
    console.log('   Please create this file with your Top 100 wines JSON.');
    console.log('\n   Expected format:');
    console.log('   [');
    console.log('     {');
    console.log('       "producer": "Opus One",');
    console.log('       "name": "Opus One",');
    console.log('       "vintage": 2021,');
    console.log('       "region": "Napa Valley",');
    console.log('       "country": "USA",');
    console.log('       "color": "red",');
    console.log('       "score": 98,');
    console.log('       "tasting_note": "...",');
    console.log('       "reviewer_initials": "JL",');
    console.log('       "review_date": "2024-01-15",');
    console.log('       "drink_window_start": 2026,');
    console.log('       "drink_window_end": 2050,');
    console.log('       "release_price": 450');
    console.log('     },');
    console.log('     ...');
    console.log('   ]');
    process.exit(1);
  }

  const rawData = readFileSync(dataPath, 'utf-8');
  const wines: WineInput[] = JSON.parse(rawData);

  console.log(`📊 Found ${wines.length} wines to import\n`);

  // Clear existing data (optional - comment out if you want to append)
  console.log('🗑️  Clearing existing data...');
  await supabase.from('saved_wines').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('reviews').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('wines').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await wineIndex.clearObjects();

  console.log('✅ Cleared\n');

  // Insert wines and reviews
  console.log('📥 Inserting wines...');

  const algoliaRecords: any[] = [];
  let successCount = 0;
  let errorCount = 0;

  for (const wine of wines) {
    try {
      // Insert wine
      const { data: insertedWine, error: wineError } = await supabase
        .from('wines')
        .insert({
          producer: wine.producer,
          name: wine.name,
          vintage: wine.vintage,
          region: wine.region,
          sub_region: wine.sub_region || null,
          appellation: wine.appellation || null,
          country: wine.country,
          color: wine.color,
          grape_varieties: wine.grape_varieties || [],
          alcohol: wine.alcohol || null,
        })
        .select()
        .single();

      if (wineError) {
        console.error(`   ❌ Error inserting ${wine.producer} ${wine.name}:`, wineError.message);
        errorCount++;
        continue;
      }

      // Insert review
      const { error: reviewError } = await supabase
        .from('reviews')
        .insert({
          wine_id: insertedWine.id,
          score: wine.score,
          tasting_note: wine.tasting_note,
          reviewer_initials: wine.reviewer_initials,
          reviewer_name: wine.reviewer_name || null,
          review_date: wine.review_date,
          issue_date: wine.issue_date || null,
          drink_window_start: wine.drink_window_start || null,
          drink_window_end: wine.drink_window_end || null,
          release_price: wine.release_price || null,
        });

      if (reviewError) {
        console.error(`   ❌ Error inserting review for ${wine.producer} ${wine.name}:`, reviewError.message);
      }

      // Prepare Algolia record
      const fullName = wine.vintage
        ? `${wine.producer} ${wine.name} ${wine.vintage}`
        : `${wine.producer} ${wine.name}`;

      algoliaRecords.push({
        objectID: insertedWine.id,
        producer: wine.producer,
        name: wine.name,
        full_name: fullName,
        vintage: wine.vintage,
        region: wine.region,
        sub_region: wine.sub_region,
        country: wine.country,
        color: wine.color,
        grape_varieties: (wine.grape_varieties || []).map(g => g.name),
        score: wine.score,
        tasting_note: wine.tasting_note,
        reviewer_initials: wine.reviewer_initials,
        reviewer_name: wine.reviewer_name,
        review_date: wine.review_date,
        drink_window_start: wine.drink_window_start,
        drink_window_end: wine.drink_window_end,
        release_price: wine.release_price,
        producer_normalized: normalizeText(wine.producer),
        name_normalized: normalizeText(wine.name),
        searchable_text: normalizeText(fullName),
      });

      successCount++;
      process.stdout.write(`   ✅ ${successCount}/${wines.length} wines imported\r`);
    } catch (err) {
      console.error(`   ❌ Error processing ${wine.producer} ${wine.name}:`, err);
      errorCount++;
    }
  }

  console.log(`\n\n📊 Database import complete: ${successCount} success, ${errorCount} errors\n`);

  // Index in Algolia
  if (algoliaRecords.length > 0) {
    console.log('🔍 Indexing in Algolia...');
    await wineIndex.saveObjects(algoliaRecords);
    console.log(`   ✅ Indexed ${algoliaRecords.length} wines\n`);

    // Configure Algolia settings
    console.log('⚙️  Configuring Algolia search settings...');
    await wineIndex.setSettings({
      searchableAttributes: [
        'full_name',
        'producer',
        'name',
        'producer_normalized',
        'name_normalized',
        'searchable_text',
        'region',
        'grape_varieties',
      ],
      attributesForFaceting: [
        'filterOnly(color)',
        'filterOnly(country)',
        'filterOnly(vintage)',
        'searchable(region)',
        'score',
      ],
      customRanking: ['desc(score)'],
      typoTolerance: true,
      minWordSizefor1Typo: 3,
      minWordSizefor2Typos: 6,
    });
    console.log('   ✅ Settings configured\n');
  }

  console.log('🎉 Seeding complete!');
  console.log(`   - ${successCount} wines in database`);
  console.log(`   - ${algoliaRecords.length} wines indexed for search`);
}

function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// Run
seed().catch(console.error);
