# Database Seeding Instructions

## Important: Two Data Sources

The app uses **two databases** that need to be updated:

1. **Supabase (PostgreSQL)** - Main database for wine data
2. **Algolia** - Search index for fast wine matching

The JSON files (`top100-2024.json` and `Top100-2025.json`) are just source data files. They need to be loaded into the actual databases.

## Step-by-Step Seeding Process

### Step 1: Run Database Migration

First, add the new columns to your Supabase database:

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Run this migration script:

```sql
-- Add missing columns to wines table
ALTER TABLE wines 
ADD COLUMN IF NOT EXISTS label_url TEXT,
ADD COLUMN IF NOT EXISTS top100_rank INTEGER,
ADD COLUMN IF NOT EXISTS top100_year INTEGER;

-- Add indexes for top100 queries
CREATE INDEX IF NOT EXISTS idx_wines_top100_rank ON wines(top100_rank) WHERE top100_rank IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wines_top100_year ON wines(top100_year) WHERE top100_year IS NOT NULL;
```

Or use the file: `backend/scripts/add_wine_fields_migration.sql`

### Step 2: Set Environment Variables

You need these environment variables to run the seed script:

```bash
export SUPABASE_URL="your-supabase-url"
export SUPABASE_SERVICE_KEY="your-supabase-service-key"
export ALGOLIA_APP_ID="your-algolia-app-id"
export ALGOLIA_API_KEY="your-algolia-api-key"
```

**For Vercel deployment:**
- These should already be set in your Vercel project settings
- You can run the seed script locally with these env vars, or
- Create a Vercel serverless function to run the seed

### Step 3: Transform the Data (if needed)

If you have new `Top100-2025.json` data:

```bash
cd backend
npx tsx scripts/transform-wines.ts
```

This will update `top100-2024.json` with the latest data including `label_url`, `top100_rank`, and `top100_year`.

### Step 4: Run the Seed Script

This will:
- Clear existing data (optional - you can comment out the clear section)
- Insert wines into Supabase
- Insert reviews into Supabase
- Index all wines in Algolia with the new fields

```bash
cd backend
npx tsx scripts/seed.ts
```

**Important:** The seed script will:
- Delete all existing wines, reviews, and saved wines
- Re-insert everything from `top100-2024.json`
- Re-index Algolia with all the new fields

### Step 5: Verify the Data

After seeding, verify:

1. **Supabase**: Check that wines have `label_url`, `top100_rank`, `top100_year` columns populated
2. **Algolia**: Check that search results include these fields
3. **API**: Test the search endpoint to see if it returns the new fields

## Current Status

✅ **Data files updated**: `top100-2024.json` has all the new fields
✅ **Code updated**: Backend and iOS code support the new fields
❌ **Database not seeded**: Supabase and Algolia need to be updated with the new data

## Quick Check

To see if your database has the new fields, you can:

1. Check Supabase: Query `SELECT label_url, top100_rank, top100_year FROM wines LIMIT 5;`
2. Check Algolia: Search for a wine and see if results include these fields

If these return `null` or empty, you need to run the seed script.

