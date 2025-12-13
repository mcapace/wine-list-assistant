# Backend Setup Checklist

## ✅ Step 1.1: Supabase Project Setup
- [ ] Go to https://supabase.com and sign up/login
- [ ] Click "New Project"
- [ ] Fill in project details:
  - Name: `wine-list-assistant`
  - Database Password: (save securely!)
  - Region: Choose closest to your users
- [ ] Wait for project creation (~2 minutes)
- [ ] Go to Settings → API
- [ ] Copy and save these values:
  - [ ] `SUPABASE_URL`
  - [ ] `SUPABASE_ANON_KEY`
  - [ ] `SUPABASE_SERVICE_KEY`

## ✅ Step 1.2: Database Schema Setup
- [ ] In Supabase, go to SQL Editor
- [ ] Click "New query"
- [ ] Copy contents of `backend/scripts/schema.sql`
- [ ] Paste and click "Run"
- [ ] Verify "Success. No rows returned" for each statement

## ✅ Step 1.3: Algolia Setup
- [ ] Go to https://www.algolia.com and sign up
- [ ] Create a new application
- [ ] Go to Settings → API Keys
- [ ] Copy and save these values:
  - [ ] `ALGOLIA_APP_ID`
  - [ ] `ALGOLIA_API_KEY` (Admin API Key)
  - [ ] `ALGOLIA_SEARCH_KEY` (Search-Only API Key)

## ✅ Step 1.4: Vercel Setup
- [ ] Go to https://vercel.com and sign up with GitHub
- [ ] Click "Add New..." → "Project"
- [ ] Import repository: https://github.com/mcapace/wine-list-assistant
- [ ] Configure:
  - Root Directory: `backend`
  - Framework Preset: Other
- [ ] Add Environment Variables:
  - [ ] `SUPABASE_URL`
  - [ ] `SUPABASE_ANON_KEY`
  - [ ] `SUPABASE_SERVICE_KEY`
  - [ ] `ALGOLIA_APP_ID`
  - [ ] `ALGOLIA_API_KEY`
  - [ ] `ALGOLIA_SEARCH_KEY`
  - [ ] `JWT_SECRET` (generate random 64-char string)
- [ ] Click "Deploy"
- [ ] Note deployment URL: `https://your-project.vercel.app`

## ✅ Step 1.5: Seed Database
- [ ] Navigate to backend folder
- [ ] Install dependencies: `npm install`
- [ ] Create `.env` file with all credentials
- [ ] Add Top 100 wines JSON to `backend/data/top100-2024.json`
- [ ] Run seed script: `npx tsx scripts/seed.ts`
- [ ] Verify successful import

## ✅ Step 1.6: Test API
- [ ] Test search endpoint with curl
- [ ] Verify JSON response with wine data

---

## Quick Reference: Environment Variables Needed

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_KEY=eyJhbGc...
ALGOLIA_APP_ID=XXXXXXXXXX
ALGOLIA_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ALGOLIA_SEARCH_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
JWT_SECRET=[64-character random string]
```




