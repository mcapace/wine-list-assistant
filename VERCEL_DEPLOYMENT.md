# Vercel Deployment Guide

## Step 1.4: Deploy to Vercel

### 1. Connect Your Repository

1. Go to https://vercel.com and sign up/login with GitHub
2. Click **"Add New..." → "Project"**
3. Import repository: `mcapace/wine-list-assistant`
4. Click **"Import"**

### 2. Configure Project Settings

In the project configuration:

- **Framework Preset:** Other
- **Root Directory:** `backend` (click "Edit" and set to `backend`)
- **Build Command:** Leave empty (Vercel will auto-detect)
- **Output Directory:** Leave empty
- **Install Command:** `npm install`

### 3. Add Environment Variables

Click **"Environment Variables"** and add these 7 variables:

#### Supabase Variables
```
SUPABASE_URL = https://cjtrppnmbqvdegtouktj.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdHJwcG5tYnF2ZGVndG91a3RqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5NDkwMDksImV4cCI6MjA4MDUyNTAwOX0.APNoDergaS-UJctbtcmdhycqXsdunEyrcol_KAHPXSM
SUPABASE_SERVICE_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdHJwcG5tYnF2ZGVndG91a3RqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDk0OTAwOSwiZXhwIjoyMDgwNTI1MDA5fQ.ZCkRXhWrJmtDoj9eWqMpi8F00JxIQ4zpCNldtxS9UrA
```

#### Algolia Variables
```
ALGOLIA_APP_ID = IUS70V57LO
ALGOLIA_API_KEY = 9f13d026ee99f83612ca9753c58b2e6c
ALGOLIA_SEARCH_KEY = 8f41cef458bd389150da1e987782ed55
```

#### JWT Secret
```
JWT_SECRET = c6e2523cb391ae80c6bdc262d71c5bcf212156691e805478c19e5a447afa35da
```

**Important:** Make sure to select **Production**, **Preview**, and **Development** for all variables.

### 4. Deploy

1. Click **"Deploy"**
2. Wait for deployment to complete (~2-3 minutes)
3. Note your deployment URL: `https://your-project-name.vercel.app`

### 5. Test the API

Once deployed, test the API:

```bash
# Test search endpoint (will return empty until you seed data)
curl "https://your-project-name.vercel.app/api/wines/search?q=opus"

# Should return JSON response (may be empty array if no wines seeded yet)
```

## Next Steps After Deployment

1. **Note your Vercel URL** - You'll need this for the iOS app configuration
2. **Run database schema** (if not done yet) in Supabase SQL Editor
3. **Seed the database** with your wine data
4. **Update iOS app** with the Vercel API URL

