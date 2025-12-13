// Wine Types
export interface Wine {
  id: string;
  producer: string;
  name: string;
  vintage: number | null;
  region: string;
  sub_region: string | null;
  appellation: string | null;
  country: string;
  color: WineColor;
  grape_varieties: GrapeVariety[];
  alcohol: number | null;
  label_url: string | null;
  top100_rank: number | null;
  top100_year: number | null;
}

export interface Review {
  id: string;
  wine_id: string;
  score: number;
  tasting_note: string;
  reviewer_initials: string;
  reviewer_name: string | null;
  review_date: string;
  issue_date: string | null;
  drink_window_start: number | null;
  drink_window_end: number | null;
  release_price: number | null;
  release_price_currency: string;
}

export interface WineWithReview extends Wine {
  score: number;
  tasting_note: string;
  reviewer_initials: string;
  reviewer_name: string | null;
  review_date: string;
  drink_window_start: number | null;
  drink_window_end: number | null;
  release_price: number | null;
}

export type WineColor = 'red' | 'white' | 'rose' | 'sparkling' | 'dessert' | 'fortified';

export interface GrapeVariety {
  name: string;
  percentage: number | null;
}

// Search Types
export interface SearchResult {
  wine: WineWithReview;
  match_confidence: number;
  match_type: 'exact' | 'fuzzy' | 'semantic';
}

export interface BatchMatchRequest {
  queries: string[];
  options?: {
    fuzzy?: boolean;
    confidence_threshold?: number;
  };
}

export interface BatchMatchResult {
  query: string;
  matched: boolean;
  wine: WineWithReview | null;
  confidence: number;
}

// User Types
export interface User {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  subscription_tier: SubscriptionTier;
  subscription_status: SubscriptionStatus;
  subscription_expires_at: string | null;
  created_at: string;
}

export type SubscriptionTier = 'free' | 'premium' | 'business';
export type SubscriptionStatus = 'active' | 'expired' | 'cancelled' | 'pending';

// Saved Wine Types
export interface SavedWine {
  id: string;
  user_id: string;
  wine_id: string;
  notes: string | null;
  restaurant: string | null;
  price_paid: number | null;
  date_consumed: string | null;
  personal_rating: number | null;
  created_at: string;
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
  meta?: {
    request_id: string;
    processing_time_ms: number;
  };
}

// Auth Types
export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

export interface JWTPayload {
  sub: string;  // user_id
  email: string;
  tier: SubscriptionTier;
  iat: number;
  exp: number;
}
