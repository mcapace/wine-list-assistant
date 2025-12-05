import algoliasearch from 'algoliasearch';
import type { WineWithReview, SearchResult } from '../types';

const appId = process.env.ALGOLIA_APP_ID!;
const apiKey = process.env.ALGOLIA_API_KEY!;

const client = algoliasearch(appId, apiKey);
const wineIndex = client.initIndex('wines');

// Search interface - allows swapping to Elasticsearch later
export interface SearchService {
  search(query: string, options?: SearchOptions): Promise<SearchResult[]>;
  indexWine(wine: WineWithReview): Promise<void>;
  indexWines(wines: WineWithReview[]): Promise<void>;
  deleteWine(wineId: string): Promise<void>;
}

export interface SearchOptions {
  limit?: number;
  filters?: {
    color?: string;
    country?: string;
    min_score?: number;
    vintage?: number;
  };
}

// Algolia implementation
export const algoliaSearch: SearchService = {
  async search(query: string, options: SearchOptions = {}): Promise<SearchResult[]> {
    const { limit = 10, filters } = options;

    // Build filter string
    const filterParts: string[] = [];
    if (filters?.color) filterParts.push(`color:${filters.color}`);
    if (filters?.country) filterParts.push(`country:"${filters.country}"`);
    if (filters?.min_score) filterParts.push(`score >= ${filters.min_score}`);
    if (filters?.vintage) filterParts.push(`vintage = ${filters.vintage}`);

    const results = await wineIndex.search<AlgoliaWineRecord>(query, {
      hitsPerPage: limit,
      filters: filterParts.join(' AND '),
      attributesToRetrieve: ['*'],
      typoTolerance: true,
      minWordSizefor1Typo: 3,
      minWordSizefor2Typos: 6,
    });

    return results.hits.map((hit) => ({
      wine: algoliaHitToWine(hit),
      match_confidence: calculateConfidence(query, hit),
      match_type: 'fuzzy' as const,
    }));
  },

  async indexWine(wine: WineWithReview): Promise<void> {
    await wineIndex.saveObject(wineToAlgoliaRecord(wine));
  },

  async indexWines(wines: WineWithReview[]): Promise<void> {
    const records = wines.map(wineToAlgoliaRecord);
    await wineIndex.saveObjects(records);
  },

  async deleteWine(wineId: string): Promise<void> {
    await wineIndex.deleteObject(wineId);
  },
};

// Algolia record type
interface AlgoliaWineRecord {
  objectID: string;
  producer: string;
  name: string;
  full_name: string;
  vintage: number | null;
  region: string;
  sub_region: string | null;
  country: string;
  color: string;
  grape_varieties: string[];
  score: number;
  tasting_note: string;
  reviewer_initials: string;
  reviewer_name: string | null;
  review_date: string;
  drink_window_start: number | null;
  drink_window_end: number | null;
  release_price: number | null;
  // Searchable variants
  producer_normalized: string;
  name_normalized: string;
  searchable_text: string;
}

function wineToAlgoliaRecord(wine: WineWithReview): AlgoliaWineRecord {
  const fullName = wine.vintage
    ? `${wine.producer} ${wine.name} ${wine.vintage}`
    : `${wine.producer} ${wine.name}`;

  return {
    objectID: wine.id,
    producer: wine.producer,
    name: wine.name,
    full_name: fullName,
    vintage: wine.vintage,
    region: wine.region,
    sub_region: wine.sub_region,
    country: wine.country,
    color: wine.color,
    grape_varieties: wine.grape_varieties.map(g => g.name),
    score: wine.score,
    tasting_note: wine.tasting_note,
    reviewer_initials: wine.reviewer_initials,
    reviewer_name: wine.reviewer_name,
    review_date: wine.review_date,
    drink_window_start: wine.drink_window_start,
    drink_window_end: wine.drink_window_end,
    release_price: wine.release_price,
    // Normalized for better matching
    producer_normalized: normalizeText(wine.producer),
    name_normalized: normalizeText(wine.name),
    searchable_text: normalizeText(fullName),
  };
}

function algoliaHitToWine(hit: AlgoliaWineRecord): WineWithReview {
  return {
    id: hit.objectID,
    producer: hit.producer,
    name: hit.name,
    vintage: hit.vintage,
    region: hit.region,
    sub_region: hit.sub_region,
    appellation: null,
    country: hit.country,
    color: hit.color as WineWithReview['color'],
    grape_varieties: hit.grape_varieties.map(name => ({ name, percentage: null })),
    alcohol: null,
    score: hit.score,
    tasting_note: hit.tasting_note,
    reviewer_initials: hit.reviewer_initials,
    reviewer_name: hit.reviewer_name,
    review_date: hit.review_date,
    drink_window_start: hit.drink_window_start,
    drink_window_end: hit.drink_window_end,
    release_price: hit.release_price,
  };
}

function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
    .replace(/[^a-z0-9\s]/g, ' ')    // Remove special chars
    .replace(/\s+/g, ' ')             // Normalize spaces
    .trim();
}

function calculateConfidence(query: string, hit: AlgoliaWineRecord): number {
  const normalizedQuery = normalizeText(query);
  const normalizedHit = hit.searchable_text;

  // Simple token overlap calculation
  const queryTokens = new Set(normalizedQuery.split(' '));
  const hitTokens = new Set(normalizedHit.split(' '));

  let matches = 0;
  for (const token of queryTokens) {
    if (hitTokens.has(token)) matches++;
  }

  const baseConfidence = matches / queryTokens.size;

  // Boost for vintage match
  const vintageMatch = hit.vintage && query.includes(String(hit.vintage));

  return Math.min(0.99, baseConfidence * 0.8 + (vintageMatch ? 0.15 : 0) + 0.05);
}

// Configure Algolia index settings (run once during setup)
export async function configureAlgoliaIndex(): Promise<void> {
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

  // Configure synonyms separately
  await wineIndex.saveSynonyms([
    { objectID: 'cab', type: 'synonym', synonyms: ['cabernet', 'cab', 'cabernet sauvignon', 'cs'] },
    { objectID: 'chard', type: 'synonym', synonyms: ['chardonnay', 'chard'] },
    { objectID: 'sauv', type: 'synonym', synonyms: ['sauvignon', 'sauv', 'sauvignon blanc', 'sb'] },
    { objectID: 'pn', type: 'synonym', synonyms: ['pinot noir', 'pn', 'pinot'] },
    { objectID: 'chateau', type: 'synonym', synonyms: ['chateau', 'ch', 'cht', 'château'] },
    { objectID: 'domaine', type: 'synonym', synonyms: ['domaine', 'dom', 'domaine de'] },
  ]);
}
