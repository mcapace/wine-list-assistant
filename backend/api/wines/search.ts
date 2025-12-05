import type { VercelRequest, VercelResponse } from '@vercel/node';
import { algoliaSearch } from '../../lib/algolia';
import { success, badRequest, serverError } from '../../lib/response';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { q, limit, color, country, min_score, vintage, fuzzy } = req.query;

    if (!q || typeof q !== 'string') {
      const response = badRequest('Query parameter "q" is required');
      return res.status(400).json(JSON.parse(await response.text()));
    }

    const searchLimit = Math.min(parseInt(limit as string) || 10, 50);

    const results = await algoliaSearch.search(q, {
      limit: searchLimit,
      filters: {
        color: color as string | undefined,
        country: country as string | undefined,
        min_score: min_score ? parseInt(min_score as string) : undefined,
        vintage: vintage ? parseInt(vintage as string) : undefined,
      },
    });

    const response = success({
      results: results.map(r => ({
        wine: r.wine,
        match_confidence: r.match_confidence,
        match_type: r.match_type,
      })),
      total_count: results.length,
      query_normalized: q.toLowerCase().trim(),
    });

    return res.status(200).json(JSON.parse(await response.text()));
  } catch (err) {
    console.error('Search error:', err);
    const response = serverError('Search failed');
    return res.status(500).json(JSON.parse(await response.text()));
  }
}
