/**
 * Transform Top 100 JSON from Wine Spectator API format to seed script format
 * 
 * Usage:
 *   npx tsx scripts/transform-wines.ts
 */

import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

interface SourceWine {
  id: number;
  winery_full: string;
  wine_full: string;
  vintage: number | "NV" | string;
  note: string;
  taster_initials: string;
  color: string;
  country: string;
  region: string;
  score: number;
  price: number;
  issue_date: string;
  top100_year?: number;
  top100_rank?: number;
  label_url?: string;
  wine_type: string;
}

interface TargetWine {
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
  label_url?: string;
  top100_rank?: number;
  top100_year?: number;
}

// Convert color string to lowercase and map to valid values
function normalizeColor(color: string, wineType: string): 'red' | 'white' | 'rose' | 'sparkling' | 'dessert' | 'fortified' {
  const lower = color.toLowerCase();
  
  if (wineType === 'sparkling') return 'sparkling';
  if (wineType === 'dessert') return 'dessert';
  if (lower === 'na' || lower === 'n/a') {
    // Try to infer from wine_type
    if (wineType === 'sparkling') return 'sparkling';
    if (wineType === 'dessert') return 'dessert';
    return 'white'; // Default fallback
  }
  
  if (lower.includes('rose') || lower.includes('rosé')) return 'rose';
  if (lower.includes('red')) return 'red';
  if (lower.includes('white')) return 'white';
  if (lower.includes('sparkling')) return 'sparkling';
  if (lower.includes('dessert')) return 'dessert';
  if (lower.includes('fortified')) return 'fortified';
  
  return 'red'; // Default fallback
}

// Parse drink window from note text
function parseDrinkWindow(note: string): { start?: number; end?: number } {
  // Look for patterns like "Best from 2026 through 2040" or "Drink now through 2035"
  const patterns = [
    /(?:Best from|Drink now through|from)\s+(\d{4})\s+(?:through|to|-)\s+(\d{4})/i,
    /(?:Best from|from)\s+(\d{4})\s+through\s+(\d{4})/i,
    /Drink now through (\d{4})/i,
  ];
  
  for (const pattern of patterns) {
    const match = note.match(pattern);
    if (match) {
      if (match[2]) {
        return { start: parseInt(match[1]), end: parseInt(match[2]) };
      } else if (match[1] && pattern.source.includes('now through')) {
        // "Drink now through 2035" - start is current year or null
        return { end: parseInt(match[1]) };
      }
    }
  }
  
  // Look for single year patterns like "Best from 2027"
  const singleYearMatch = note.match(/Best from (\d{4})/i);
  if (singleYearMatch) {
    return { start: parseInt(singleYearMatch[1]) };
  }
  
  return {};
}

// Convert date from "Mar 31, 2025" to "2025-03-31"
function parseDate(dateStr: string): string | null {
  if (!dateStr || dateStr.trim() === '') return null;
  
  try {
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return null;
    
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    
    return `${year}-${month}-${day}`;
  } catch {
    return null;
  }
}

function transformWine(source: SourceWine): TargetWine {
  const drinkWindow = parseDrinkWindow(source.note);
  const reviewDate = parseDate(source.issue_date);
  
  return {
    producer: source.winery_full,
    name: source.wine_full,
    vintage: source.vintage === "NV" || source.vintage === "nv" ? null : (typeof source.vintage === 'number' ? source.vintage : parseInt(String(source.vintage)) || null),
    region: source.region,
    country: source.country,
    color: normalizeColor(source.color, source.wine_type),
    score: source.score,
    tasting_note: source.note,
    reviewer_initials: source.taster_initials,
    review_date: reviewDate || new Date().toISOString().split('T')[0], // Fallback to today if can't parse
    issue_date: reviewDate || undefined,
    drink_window_start: drinkWindow.start,
    drink_window_end: drinkWindow.end,
    release_price: source.price || undefined,
    label_url: source.label_url || undefined,
    top100_rank: source.top100_rank || undefined,
    top100_year: source.top100_year || undefined,
  };
}

// Main transformation
const inputPath = join(__dirname, '../data/Top100-2025.json');
const outputPath = join(__dirname, '../data/top100-2024.json');

console.log('🔄 Transforming wine data...\n');

try {
  const rawData = readFileSync(inputPath, 'utf-8');
  const sourceWines: SourceWine[] = JSON.parse(rawData);
  
  console.log(`📊 Found ${sourceWines.length} wines to transform\n`);
  
  const transformedWines = sourceWines.map(transformWine);
  
  // Validate required fields
  const errors: string[] = [];
  transformedWines.forEach((wine, index) => {
    if (!wine.producer) errors.push(`Wine ${index + 1}: missing producer`);
    if (!wine.name) errors.push(`Wine ${index + 1}: missing name`);
    if (!wine.region) errors.push(`Wine ${index + 1}: missing region`);
    if (!wine.country) errors.push(`Wine ${index + 1}: missing country`);
    if (!wine.score) errors.push(`Wine ${index + 1}: missing score`);
    if (!wine.tasting_note) errors.push(`Wine ${index + 1}: missing tasting_note`);
    if (!wine.reviewer_initials) errors.push(`Wine ${index + 1}: missing reviewer_initials`);
    if (!wine.review_date) errors.push(`Wine ${index + 1}: missing review_date`);
  });
  
  if (errors.length > 0) {
    console.error('❌ Validation errors:');
    errors.forEach(err => console.error(`   ${err}`));
    process.exit(1);
  }
  
  writeFileSync(outputPath, JSON.stringify(transformedWines, null, 2), 'utf-8');
  
  console.log(`✅ Transformation complete!`);
  console.log(`   - Transformed ${transformedWines.length} wines`);
  console.log(`   - Output saved to: ${outputPath}\n`);
  
  // Show sample
  console.log('📝 Sample transformed wine:');
  console.log(JSON.stringify(transformedWines[0], null, 2));
  
} catch (error) {
  console.error('❌ Error transforming data:', error);
  process.exit(1);
}

