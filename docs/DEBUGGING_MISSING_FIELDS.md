# Debugging Missing Wine Fields (label_url, tasting_note)

## Current Status

✅ **Database**: Has all fields (verified)
✅ **Algolia**: Has all fields (verified)  
✅ **Code**: Supports all fields
❌ **App**: Not displaying images or tasting notes

## What to Check

### 1. Check Xcode Console Logs

When you scan a wine, look for these log messages:

**Cache Lookup:**
```
🍷 tryExactMatch - Found wine: [name]
   - Has labelUrl: true/false
   - Has tastingNote: true/false
```

**API Response:**
```
🌐 WineAPIClient.searchWines - Decoded X results
   Sample wine: [name]
   - Has labelUrl: true/false, value: [url]
   - Has tastingNote: true/false, length: [number]
```

**Detail Sheet:**
```
🍷 WineDetailSheet - Wine data:
   - Has labelUrl: true/false
   - labelUrl value: [url or nil]
   - Has tastingNote: true/false
```

### 2. Clear Cache Steps

1. **Settings → Clear Wine Cache**
   - Should show alert: "Cache Cleared"
   - Check console for: `🗑️ LocalWineCache: Cleared cache files`

2. **Restart App**
   - Cache version check should run
   - If old cache detected: `🔄 LocalWineCache: Cache version mismatch... Clearing old cache`

3. **Scan Again**
   - Should see API calls in console
   - Should see wines being cached with fields

### 3. Force API Call (Skip Cache)

The app now automatically skips cache matches that don't have `labelUrl` or `tastingNote`. This means:
- If cache has old wine → Skip it → Call API → Get fresh data
- If API returns wine with fields → Cache it → Use it

### 4. Verify API Response

Test the API directly:
```bash
curl "https://backend-theta-mauve-9kehaxzmz7.vercel.app/api/wines/search?q=Bedrock&limit=1" \
  -H "X-API-Key: wla_pk_dev_placeholder"
```

Check if response includes:
- `label_url` field
- `tasting_note` field
- `top100_rank` field

## Expected Behavior

After clearing cache and scanning:
1. App checks cache → Finds nothing (or old version)
2. App calls API → Gets wine with all fields
3. App caches wine → Saves with version 2
4. App displays wine → Shows image and tasting note

## If Still Not Working

1. **Check if API is returning fields:**
   - Look for `🌐 WineAPIClient.searchWines` logs
   - Verify `Has labelUrl: true` in logs

2. **Check if Wine model is decoding:**
   - Look for `🍷 WineDetailSheet - Wine data` logs
   - Verify fields are present when displayed

3. **Check cache version:**
   - Look for `🔄 LocalWineCache: Cache version mismatch` on app start
   - If not appearing, cache might not be clearing

4. **Try "Reset App" instead:**
   - Settings → Reset App
   - This clears cache AND all other data
   - Then scan again

## Quick Test

1. Open Xcode
2. Run app on device/simulator
3. Open Console (View → Debug Area → Activate Console)
4. Go to Settings → Clear Wine Cache
5. Scan a wine list
6. Check console logs for field presence
7. Tap a wine to see detail sheet
8. Check console for `🍷 WineDetailSheet - Wine data` log

This will show exactly where the fields are being lost.

