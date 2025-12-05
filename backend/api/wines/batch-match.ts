import type { VercelRequest, VercelResponse } from '@vercel/node';
import { algoliaSearch } from '../../lib/algolia';
import { success, badRequest, serverError } from '../../lib/response';
import type { BatchMatchResult } from '../../types';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { queries, options } = req.body as {
      queries: string[];
      options?: { fuzzy?: boolean; confidence_threshold?: number };
    };

    if (!queries || !Array.isArray(queries) || queries.length === 0) {
      const response = badRequest('queries array is required');
      return res.status(400).json(JSON.parse(await response.text()));
    }

    if (queries.length > 100) {
      const response = badRequest('Maximum 100 queries per request');
      return res.status(400).json(JSON.parse(await response.text()));
    }

    const confidenceThreshold = options?.confidence_threshold ?? 0.7;

    // Process all queries in parallel
    const matchPromises = queries.map(async (query): Promise<BatchMatchResult> => {
      try {
        const results = await algoliaSearch.search(query, { limit: 1 });
        const bestMatch = results[0];

        if (bestMatch && bestMatch.match_confidence >= confidenceThreshold) {
          return {
            query,
            matched: true,
            wine: bestMatch.wine,
            confidence: bestMatch.match_confidence,
          };
        }

        return {
          query,
          matched: false,
          wine: null,
          confidence: bestMatch?.match_confidence ?? 0,
        };
      } catch {
        return {
          query,
          matched: false,
          wine: null,
          confidence: 0,
        };
      }
    });

    const matches = await Promise.all(matchPromises);
    const matchedCount = matches.filter(m => m.matched).length;

    const response = success({
      matches,
      match_rate: matchedCount / queries.length,
      processing_time_ms: 0, // Would measure actual time
    });

    return res.status(200).json(JSON.parse(await response.text()));
  } catch (err) {
    console.error('Batch match error:', err);
    const response = serverError('Batch matching failed');
    return res.status(500).json(JSON.parse(await response.text()));
  }
}
