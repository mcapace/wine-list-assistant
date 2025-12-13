-- Migration: Add label_url, top100_rank, top100_year to wines table
-- Run this in Supabase SQL Editor

-- Add missing columns to wines table
ALTER TABLE wines 
ADD COLUMN IF NOT EXISTS label_url TEXT,
ADD COLUMN IF NOT EXISTS top100_rank INTEGER,
ADD COLUMN IF NOT EXISTS top100_year INTEGER;

-- Add index for top100 queries
CREATE INDEX IF NOT EXISTS idx_wines_top100_rank ON wines(top100_rank) WHERE top100_rank IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wines_top100_year ON wines(top100_year) WHERE top100_year IS NOT NULL;

