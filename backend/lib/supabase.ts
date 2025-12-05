import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY!;

// Client for public operations (respects RLS)
export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Admin client for server-side operations (bypasses RLS)
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

// Database types for Supabase
export type Database = {
  public: {
    Tables: {
      wines: {
        Row: {
          id: string;
          producer: string;
          name: string;
          vintage: number | null;
          region: string;
          sub_region: string | null;
          appellation: string | null;
          country: string;
          color: string;
          grape_varieties: { name: string; percentage: number | null }[];
          alcohol: number | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['wines']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['wines']['Insert']>;
      };
      reviews: {
        Row: {
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
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['reviews']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['reviews']['Insert']>;
      };
      users: {
        Row: {
          id: string;
          email: string;
          first_name: string | null;
          last_name: string | null;
          subscription_tier: string;
          subscription_status: string;
          subscription_expires_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['users']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['users']['Insert']>;
      };
      saved_wines: {
        Row: {
          id: string;
          user_id: string;
          wine_id: string;
          notes: string | null;
          restaurant: string | null;
          price_paid: number | null;
          date_consumed: string | null;
          personal_rating: number | null;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['saved_wines']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['saved_wines']['Insert']>;
      };
    };
  };
};
