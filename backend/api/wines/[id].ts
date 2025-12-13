import type { VercelRequest, VercelResponse } from '@vercel/node';
import { supabaseAdmin } from '../../lib/supabase';
import { success, notFound, serverError } from '../../lib/response';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { id } = req.query;

    if (!id || typeof id !== 'string') {
      const response = notFound('Wine ID required');
      return res.status(404).json(JSON.parse(await response.text()));
    }

    // Fetch wine with its review
    const { data: wine, error: wineError } = await supabaseAdmin
      .from('wines')
      .select(`
        *,
        reviews (
          score,
          tasting_note,
          reviewer_initials,
          reviewer_name,
          review_date,
          issue_date,
          drink_window_start,
          drink_window_end,
          release_price,
          release_price_currency
        )
      `)
      .eq('id', id)
      .single();

    if (wineError || !wine) {
      const response = notFound('Wine not found');
      return res.status(404).json(JSON.parse(await response.text()));
    }

    // Get related vintages
    const { data: relatedVintages } = await supabaseAdmin
      .from('wines')
      .select(`
        id,
        vintage,
        reviews (score)
      `)
      .eq('producer', wine.producer)
      .eq('name', wine.name)
      .neq('id', id)
      .order('vintage', { ascending: false })
      .limit(5);

    // Flatten the wine with its review
    const review = wine.reviews?.[0] || {};
    const wineWithReview = {
      id: wine.id,
      producer: wine.producer,
      name: wine.name,
      vintage: wine.vintage,
      region: wine.region,
      sub_region: wine.sub_region,
      appellation: wine.appellation,
      country: wine.country,
      color: wine.color,
      grape_varieties: wine.grape_varieties,
      alcohol: wine.alcohol,
      label_url: wine.label_url || null,
      top100_rank: wine.top100_rank || null,
      top100_year: wine.top100_year || null,
      score: review.score,
      tasting_note: review.tasting_note,
      reviewer_initials: review.reviewer_initials,
      reviewer_name: review.reviewer_name,
      review_date: review.review_date,
      issue_date: review.issue_date,
      drink_window_start: review.drink_window_start,
      drink_window_end: review.drink_window_end,
      release_price: review.release_price,
      release_price_currency: review.release_price_currency,
    };

    const response = success({
      wine: wineWithReview,
      related_vintages: relatedVintages?.map(v => ({
        id: v.id,
        vintage: v.vintage,
        score: v.reviews?.[0]?.score,
      })) || [],
    });

    return res.status(200).json(JSON.parse(await response.text()));
  } catch (err) {
    console.error('Get wine error:', err);
    const response = serverError('Failed to fetch wine');
    return res.status(500).json(JSON.parse(await response.text()));
  }
}
