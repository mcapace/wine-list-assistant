# Quick Database Seeding Guide

## Prerequisites

You need these environment variables:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_KEY` - Your Supabase service role key (not anon key!)
- `ALGOLIA_APP_ID` - Your Algolia application ID
- `ALGOLIA_API_KEY` - Your Algolia admin API key (not search-only key!)

## Step-by-Step Instructions

### Step 1: Get Your Credentials

**Supabase:**
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **service_role key** (secret) → `SUPABASE_SERVICE_KEY` ⚠️ Use service_role, not anon!

**Algolia:**
1. Go to https://www.algolia.com/dashboard
2. Select your application
3. Go to **Settings** → **API Keys**
4. Copy:
   - **Application ID** → `ALGOLIA_APP_ID`
   - **Admin API Key** → `ALGOLIA_API_KEY` ⚠️ Use Admin key, not Search-only!

### Step 2: Set Environment Variables

**Option A: Terminal (for local seeding)**

```bash
cd "/Users/mcapace/Desktop/Wine List Assistant/backend"

export SUPABASE_URL="your-supabase-url-here"
export SUPABASE_SERVICE_KEY="your-service-key-here"
export ALGOLIA_APP_ID="your-algolia-app-id"
export ALGOLIA_API_KEY="your-algolia-admin-key"
```

**Option B: Create .env file (recommended)**

```bash
cd "/Users/mcapace/Desktop/Wine List Assistant/backend"
```

Create a file named `.env` with:

```env
SUPABASE_URL=your-supabase-url-here
SUPABASE_SERVICE_KEY=your-service-key-here
ALGOLIA_APP_ID=your-algolia-app-id
ALGOLIA_API_KEY=your-algolia-admin-key
```

⚠️ **Important:** Add `.env` to `.gitignore` to keep secrets safe!

### Step 3: Run the Seed Script

```bash
cd "/Users/mcapace/Desktop/Wine List Assistant/backend"
npx tsx scripts/seed.ts
```

### Step 4: What Happens

The seed script will:
1. ✅ Load wines from `backend/data/top100-2024.json`
2. ✅ Clear existing data (wines, reviews, saved_wines, Algolia index)
3. ✅ Insert all wines into Supabase with new fields (label_url, top100_rank, top100_year)
4. ✅ Insert all reviews into Supabase
5. ✅ Index all wines in Algolia with all fields

### Expected Output

You should see something like:
```
🍷 Wine List Assistant - Database Seeder

📊 Found 100 wines to import

🗑️  Clearing existing data...
✅ Cleared

📥 Inserting wines...
   ✅ Château Giscours Margaux
   ✅ Aubert Chardonnay Sonoma Coast UV-SL Vineyard
   ...
✅ Inserted 100 wines successfully
✅ Indexed 100 wines in Algolia
```

## Troubleshooting

**Error: "Missing SUPABASE_URL or SUPABASE_SERVICE_KEY"**
- Make sure you set the environment variables (see Step 2)

**Error: "Missing ALGOLIA_APP_ID or ALGOLIA_API_KEY"**
- Make sure you set the Algolia credentials

**Error: "Error inserting wine..."**
- Check that you ran the migration script first
- Verify the database columns exist

**Error: "Algolia indexing failed"**
- Make sure you're using the Admin API key, not search-only key
- Check Algolia dashboard for API limits

## Verify It Worked

**Check Supabase:**
```sql
SELECT COUNT(*) FROM wines;
SELECT label_url, top100_rank, top100_year FROM wines LIMIT 5;
```

**Check Algolia:**
- Go to Algolia Dashboard → Indices → wines
- You should see 100 records with all fields

## Next Steps

After seeding:
1. ✅ Images should display in wine detail sheets
2. ✅ Tasting notes should show in the app
3. ✅ Top 100 rankings should be available
4. ✅ Search should work with all fields

