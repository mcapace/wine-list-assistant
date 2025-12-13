# Fix for Missing Wine Fields and Save Functionality

## Issues Fixed

1. **Missing JSON fields**: `label_url`, `top100_rank`, and `top100_year` were not being stored or returned
2. **Save wine error handling**: Errors were silently failing without user feedback

## Changes Made

### Backend Changes

1. **Database Schema** (`backend/scripts/schema.sql`):
   - Added `label_url TEXT`, `top100_rank INTEGER`, `top100_year INTEGER` to wines table
   - Added indexes for top100 queries

2. **Migration Script** (`backend/scripts/add_wine_fields_migration.sql`):
   - Created migration to add missing columns to existing databases

3. **Backend Types** (`backend/types/index.ts`):
   - Added `label_url`, `top100_rank`, `top100_year` to `Wine` interface

4. **Algolia Integration** (`backend/lib/algolia.ts`):
   - Updated `AlgoliaWineRecord` to include new fields
   - Updated `wineToAlgoliaRecord()` to map new fields
   - Updated `algoliaHitToWine()` to return new fields

5. **API Endpoints**:
   - Updated `/api/wines/[id].ts` to return new fields
   - Search endpoint already returns all fields from Algolia

6. **Seed Script** (`backend/scripts/seed.ts`):
   - Updated `WineInput` interface to include new fields
   - Updated wine insertion to save new fields
   - Updated Algolia indexing to include new fields

### iOS App Changes

1. **WineDetailSheet** (`ios/WineLensApp/WineLensApp/Features/WineDetail/Views/WineDetailSheet.swift`):
   - Added error state and alert for save failures
   - Added loading state during save operation
   - Improved error messages with user-friendly text
   - Added `isSaving` parameter to `ActionButtons`

## Steps to Apply

### 1. Run Database Migration

Run the migration script in your Supabase SQL Editor:

```sql
-- Run: backend/scripts/add_wine_fields_migration.sql
ALTER TABLE wines 
ADD COLUMN IF NOT EXISTS label_url TEXT,
ADD COLUMN IF NOT EXISTS top100_rank INTEGER,
ADD COLUMN IF NOT EXISTS top100_year INTEGER;

CREATE INDEX IF NOT EXISTS idx_wines_top100_rank ON wines(top100_rank) WHERE top100_rank IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wines_top100_year ON wines(top100_year) WHERE top100_year IS NOT NULL;
```

### 2. Re-seed Database (if needed)

If you need to add the new fields to existing wines, you'll need to:

1. Update your JSON data file to include `label_url`, `top100_rank`, and `top100_year`
2. Re-run the seed script:
   ```bash
   cd backend
   npx tsx scripts/seed.ts
   ```

### 3. Re-index Algolia

The seed script will automatically re-index Algolia with the new fields. If you need to manually re-index:

1. The seed script handles this automatically
2. Or use Algolia's dashboard to re-index with the updated schema

### 4. Test the Changes

1. **Test Image Display**: 
   - Open a wine detail that should have a `label_url`
   - Verify the image displays in the detail sheet

2. **Test Tasting Notes**:
   - Open a wine detail
   - Switch to the "Tasting Note" tab
   - Verify tasting notes display correctly

3. **Test Save Functionality**:
   - Try saving a wine (requires authentication)
   - Verify success message appears
   - Try saving without authentication - should show error message
   - Verify error alert displays user-friendly message

## Notes

- The `Wine.swift` model already had these fields defined, so no iOS model changes were needed
- The save functionality requires user authentication - errors will now be shown if the user is not signed in
- All changes are backward compatible - existing wines without these fields will have `null` values

