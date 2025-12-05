# Supabase Setup - Quick Reference

## Your Supabase Project
- **URL:** https://cjtrppnmbqvdegtouktj.supabase.co
- **Dashboard:** https://supabase.com/dashboard/project/cjtrppnmbqvdegtouktj

## Step 1: Get API Keys

1. Go to: https://supabase.com/dashboard/project/cjtrppnmbqvdegtouktj/settings/api
2. Copy these values:

```
SUPABASE_URL=https://cjtrppnmbqvdegtouktj.supabase.co
SUPABASE_ANON_KEY=[Copy from "anon" "public" key]
SUPABASE_SERVICE_KEY=[Copy from "service_role" "secret" key]
```

⚠️ **Important:** The service_role key has admin access - keep it secret!

## Step 2: Run Database Schema

1. Go to: https://supabase.com/dashboard/project/cjtrppnmbqvdegtouktj/sql/new
2. Click "New query"
3. Copy the entire contents of `backend/scripts/schema.sql`
4. Paste into the SQL Editor
5. Click "Run" (or press Cmd+Enter)
6. You should see "Success. No rows returned" for each statement

## Step 3: Verify Tables Created

After running the schema, verify these tables exist:
- `wines`
- `reviews`
- `users`
- `saved_wines`

Go to: https://supabase.com/dashboard/project/cjtrppnmbqvdegtouktj/editor

## Next Steps

Once you have the API keys:
1. Set up Algolia (Step 1.3)
2. Deploy to Vercel (Step 1.4)
3. Seed the database (Step 1.5)

