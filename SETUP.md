# Wine List Assistant - Setup Guide
## Step-by-Step Instructions

This guide will walk you through setting up the complete Wine List Assistant application, from backend services to iOS app.

---

## Prerequisites

Before starting, ensure you have:
- [x] Mac with Xcode 15+ installed
- [x] Apple Developer account
- [x] Node.js 18+ installed (`brew install node`)
- [x] Your Top 100 wines JSON data file

---

## Part 1: Backend Services Setup (30-45 minutes)

### Step 1.1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click **"New Project"**
3. Fill in:
   - **Name:** `wine-list-assistant`
   - **Database Password:** (save this securely!)
   - **Region:** Choose closest to your users
4. Click **"Create new project"** (takes ~2 minutes)
5. Once ready, go to **Settings → API**
6. Copy and save these values:
   ```
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGc...
   SUPABASE_SERVICE_KEY=eyJhbGc...
   ```

### Step 1.2: Set Up Database Schema

1. In Supabase, go to **SQL Editor**
2. Click **"New query"**
3. Copy the contents of `backend/scripts/schema.sql`
4. Paste into the editor and click **"Run"**
5. You should see "Success. No rows returned" for each statement

### Step 1.3: Create Algolia Account

1. Go to [algolia.com](https://www.algolia.com) and sign up
2. Create a new application
3. Go to **Settings → API Keys**
4. Copy and save these values:
   ```
   ALGOLIA_APP_ID=XXXXXXXXXX
   ALGOLIA_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx (Admin API Key)
   ALGOLIA_SEARCH_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx (Search-Only API Key)
   ```

### Step 1.4: Create Vercel Account & Deploy

1. Go to [vercel.com](https://vercel.com) and sign up with GitHub
2. Click **"Add New..." → "Project"**
3. Import this repository (or push to your GitHub first)
4. Configure:
   - **Root Directory:** `backend`
   - **Framework Preset:** Other
5. Add Environment Variables (click "Environment Variables"):
   ```
   SUPABASE_URL = [your value]
   SUPABASE_ANON_KEY = [your value]
   SUPABASE_SERVICE_KEY = [your value]
   ALGOLIA_APP_ID = [your value]
   ALGOLIA_API_KEY = [your value]
   ALGOLIA_SEARCH_KEY = [your value]
   JWT_SECRET = [generate a random 64-char string]
   ```
6. Click **"Deploy"**
7. Note your deployment URL: `https://your-project.vercel.app`

### Step 1.5: Seed the Database

1. Open Terminal
2. Navigate to the backend folder:
   ```bash
   cd wine-list-assistant/backend
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Create a `.env` file:
   ```bash
   cat > .env << 'EOF'
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_SERVICE_KEY=eyJhbGc...
   ALGOLIA_APP_ID=XXXXXXXXXX
   ALGOLIA_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   EOF
   ```
5. Add your Top 100 wines data:
   - Copy your JSON file to `backend/data/top100-2024.json`
   - Ensure it matches the format in `backend/data/sample-wines.json`

6. Run the seed script:
   ```bash
   npx tsx scripts/seed.ts
   ```
7. You should see output like:
   ```
   🍷 Wine List Assistant - Database Seeder
   📊 Found 100 wines to import
   🗑️  Clearing existing data...
   ✅ Cleared
   📥 Inserting wines...
      ✅ 100/100 wines imported
   🔍 Indexing in Algolia...
      ✅ Indexed 100 wines
   🎉 Seeding complete!
   ```

### Step 1.6: Test the API

Test that everything works:

```bash
# Test search endpoint
curl "https://your-project.vercel.app/api/wines/search?q=opus+one"

# You should see a JSON response with wine data
```

---

## Part 2: iOS App Setup (20-30 minutes)

### Step 2.1: Create Xcode Project

1. Open **Xcode**
2. **File → New → Project**
3. Choose **iOS → App**
4. Configure:
   - **Product Name:** `WineListAssistant`
   - **Team:** Your Apple Developer team
   - **Organization Identifier:** `com.winespectator` (or your org)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None
   - Uncheck "Include Tests" for now
5. Click **Next** and save to the `ios` folder (it will create a new folder)

### Step 2.2: Add Source Files

1. In Xcode's Project Navigator, right-click on the `WineListAssistant` folder
2. Select **"Add Files to WineListAssistant..."**
3. Navigate to `ios/WineListAssistant/`
4. Select all the folders:
   - `App`
   - `Core`
   - `Design`
   - `Features`
5. Ensure **"Copy items if needed"** is **UNCHECKED**
6. Ensure **"Create groups"** is selected
7. Click **Add**

### Step 2.3: Configure Info.plist

1. Select your project in the navigator
2. Select the **WineListAssistant** target
3. Go to the **Info** tab
4. Add these keys:
   - `Privacy - Camera Usage Description`: "Wine List Assistant uses the camera to scan wine lists and identify wines for you."
5. Or replace with the Info.plist from `ios/WineListAssistant/Info.plist`

### Step 2.4: Add Build Settings

1. Select your project
2. Select the **WineListAssistant** target
3. Go to **Build Settings**
4. Search for "User-Defined" and add:
   - `WLA_API_URL` = `https://your-project.vercel.app/api`
   - `WLA_API_KEY` = (leave empty for now, or add a key)

### Step 2.5: Update API Configuration

1. Open `App/Configuration/AppConfiguration.swift`
2. Update the `apiBaseURL` to match your Vercel deployment:
   ```swift
   static var apiBaseURL: String {
       switch current {
       case .development:
           return "https://your-project.vercel.app/api"  // Update this
       case .staging:
           return "https://your-project.vercel.app/api"
       case .production:
           return "https://your-project.vercel.app/api"
       }
   }
   ```

### Step 2.6: Build and Run

1. Select an iPhone simulator (iPhone 15 Pro recommended)
2. Press **Cmd + R** to build and run
3. The app should launch showing the onboarding flow

### Step 2.7: Test on Device (Optional but Recommended)

1. Connect your iPhone
2. Select it as the run destination
3. Xcode may prompt you to trust the developer on the device
4. Build and run

---

## Part 3: Prepare Your Wine Data

Your Top 100 JSON file should match this format:

```json
[
  {
    "producer": "Opus One",
    "name": "Opus One",
    "vintage": 2021,
    "region": "Napa Valley",
    "sub_region": "Oakville",
    "country": "USA",
    "color": "red",
    "grape_varieties": [
      { "name": "Cabernet Sauvignon", "percentage": 79 }
    ],
    "alcohol": 14.5,
    "score": 98,
    "tasting_note": "This is intensely structured...",
    "reviewer_initials": "JL",
    "reviewer_name": "James Laube",
    "review_date": "2024-03-15",
    "drink_window_start": 2027,
    "drink_window_end": 2055,
    "release_price": 450
  }
]
```

### Required Fields:
- `producer` (string)
- `name` (string)
- `region` (string)
- `country` (string)
- `color` (string: "red", "white", "rose", "sparkling", "dessert", "fortified")
- `score` (number: 0-100)
- `tasting_note` (string)
- `reviewer_initials` (string)
- `review_date` (string: YYYY-MM-DD)

### Optional Fields:
- `vintage` (number or null)
- `sub_region` (string)
- `appellation` (string)
- `grape_varieties` (array of {name, percentage})
- `alcohol` (number)
- `reviewer_name` (string)
- `issue_date` (string: YYYY-MM-DD)
- `drink_window_start` (number: year)
- `drink_window_end` (number: year)
- `release_price` (number: USD)

---

## Troubleshooting

### "Camera permission denied"
- Go to iPhone Settings → Privacy → Camera → Enable for WineListAssistant

### "API connection failed"
- Verify your Vercel deployment is running
- Check the API URL in AppConfiguration.swift
- Test the API directly with curl

### "No wines found"
- Ensure the seed script completed successfully
- Check Algolia dashboard to verify wines are indexed
- Try searching in Algolia dashboard directly

### Build errors in Xcode
- Clean build folder: Cmd + Shift + K
- Delete derived data: ~/Library/Developer/Xcode/DerivedData
- Restart Xcode

---

## Next Steps

Once the app is running:

1. **Test scanning** - Point camera at a wine list (or printed text with wine names)
2. **Verify matching** - Check that wines from your Top 100 are matched
3. **Test filters** - Try the 90+, Best Value, and Ready Now filters
4. **Check wine details** - Tap a score badge to see full wine info

For production launch:
1. Add more wines to the database
2. Set up App Store Connect
3. Configure in-app purchases
4. Submit for TestFlight beta testing

---

## Support

If you encounter issues:
1. Check the Vercel deployment logs
2. Check Supabase logs
3. Review Xcode console output
4. Verify all API keys are correctly set

---

*Last Updated: December 2024*
