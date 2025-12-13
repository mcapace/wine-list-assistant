-- =====================================================
-- Supabase Migration Script
-- Add label_url, top100_rank, top100_year to wines table
-- =====================================================
-- 
-- Instructions:
-- 1. Open your Supabase Dashboard
-- 2. Go to SQL Editor
-- 3. Paste this entire script
-- 4. Click "Run" or press Cmd/Ctrl + Enter
--
-- =====================================================

-- Add missing columns to wines table
ALTER TABLE wines 
ADD COLUMN IF NOT EXISTS label_url TEXT,
ADD COLUMN IF NOT EXISTS top100_rank INTEGER,
ADD COLUMN IF NOT EXISTS top100_year INTEGER;

-- Add indexes for top100 queries (improves performance)
CREATE INDEX IF NOT EXISTS idx_wines_top100_rank ON wines(top100_rank) WHERE top100_rank IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wines_top100_year ON wines(top100_year) WHERE top100_year IS NOT NULL;

-- Verify the columns were added (optional - you can run this to check)
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'wines' 
-- AND column_name IN ('label_url', 'top100_rank', 'top100_year');

-- =====================================================
-- Migration Complete!
-- 
-- Next Steps:
-- 1. Run the seed script to populate the new fields:
--    cd backend
--    npx tsx scripts/seed.ts
--
-- 2. Or manually update existing wines if needed
-- =====================================================

