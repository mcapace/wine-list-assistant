# TestFlight Setup Guide - Fast Testing in App Store Connect

## Quick Start Checklist

### 1. App Store Connect Setup (Do First)

1. **Create App Record** (if not already done):
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Click "+" → "New App"
   - Fill in:
     - **Platform**: iOS
     - **Name**: Wine Lens (or Wine Spectator Wine Lens)
     - **Primary Language**: English
     - **Bundle ID**: `com.winespectator.WineLens2026` (must match Xcode)
     - **SKU**: `wine-lens-app` (unique identifier, can be anything)
     - **User Access**: Full Access

2. **Set Up TestFlight**:
   - In App Store Connect, go to your app
   - Click "TestFlight" tab
   - Add Internal Testers (up to 100 people in your organization)
   - Add External Testers (up to 10,000 external testers)

### 2. Xcode Configuration

#### Current Settings:
- **Bundle Identifier**: `com.winespectator.WineLens2026`
- **Version**: `1.0`
- **Build**: `1`

#### Steps to Build & Upload:

1. **Archive the App**:
   ```
   In Xcode:
   - Select "Any iOS Device" or a connected device (not simulator)
   - Product → Archive
   - Wait for archive to complete
   ```

2. **Upload to App Store Connect**:
   ```
   In Organizer window (after Archive):
   - Click "Distribute App"
   - Select "App Store Connect"
   - Select "Upload"
   - Follow the wizard:
     * Choose automatic signing (recommended)
     * Review app information
     * Click "Upload"
   ```

3. **Faster Alternative - Command Line**:
   ```bash
   # Build and archive
   xcodebuild -workspace WineLensApp.xcworkspace \
             -scheme WineLensApp \
             -configuration Release \
             -archivePath ./build/WineLensApp.xcarchive \
             archive
   
   # Upload to App Store Connect
   xcodebuild -exportArchive \
             -archivePath ./build/WineLensApp.xcarchive \
             -exportOptionsPlist ExportOptions.plist \
             -exportPath ./build/export
   ```

### 3. TestFlight Processing

**Timeline**:
- **First Upload**: 24-48 hours for processing
- **Subsequent Updates**: Usually 1-2 hours (much faster!)

**To Speed Up Processing**:
1. **Use Incremental Builds**: Increment build number each time
   - Current: Build `1`
   - Next: Build `2`, then `3`, etc.
   - In Xcode: Target → General → Build (increment manually)

2. **Avoid Common Rejection Reasons**:
   - ✅ App must have proper icons (all sizes)
   - ✅ App must have launch screen
   - ✅ App must have privacy descriptions (if using camera, etc.)
   - ✅ App must not crash on launch
   - ✅ App must have proper signing

### 4. Internal Testing (Fastest - No Review)

**Internal Testers**:
- Available immediately after processing (no review)
- Up to 100 testers
- Perfect for your team

**Steps**:
1. Upload build to App Store Connect
2. Wait for processing (1-2 hours for updates)
3. In TestFlight → Internal Testing
4. Click "+" to add build
5. Add testers (email addresses)
6. Testers receive email invitation

### 5. External Testing (Requires Review)

**External Testers**:
- Requires App Review (usually 24-48 hours first time)
- Up to 10,000 testers
- Good for beta users

**Steps**:
1. Upload build
2. Wait for processing
3. In TestFlight → External Testing
4. Create new group or use existing
5. Add build to group
6. Submit for Beta App Review
7. Once approved, add testers

### 6. Incrementing Build Numbers (Important!)

**Manual Method**:
1. In Xcode: Select project → Target → General
2. Find "Build" number
3. Increment: `1` → `2` → `3`, etc.

**Automated Method** (Recommended):
Add a build script to auto-increment:

```bash
# Add to Build Phases → Run Script (before "Compile Sources")
# Script:
buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFOPLIST_FILE" 2>/dev/null)
buildNumber=$(($buildNumber + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$INFOPLIST_FILE"
```

### 7. Fast Testing Workflow

**Daily Testing Workflow**:
1. Make code changes
2. Increment build number (manually or auto)
3. Archive in Xcode
4. Upload to App Store Connect
5. Wait 1-2 hours for processing
6. Add to Internal Testing group
7. Testers get update notification

**Pro Tips for Speed**:
- ✅ Use Internal Testing (no review needed)
- ✅ Increment build number every upload
- ✅ Upload in the morning (faster processing during business hours)
- ✅ Use Xcode Cloud for automated builds (optional, paid)
- ✅ Keep builds under 150MB (faster upload/processing)

### 8. Required App Information

Before first submission, ensure you have:

- [ ] App Name
- [ ] App Icon (1024x1024)
- [ ] Screenshots (required for App Store, optional for TestFlight)
- [ ] Privacy Policy URL (if collecting data)
- [ ] App Description
- [ ] Category
- [ ] Age Rating
- [ ] Support URL

### 9. Common Issues & Solutions

**"Invalid Bundle"**:
- Check bundle identifier matches App Store Connect
- Verify signing certificates are valid

**"Processing Failed"**:
- Check for missing icons
- Verify Info.plist is correct
- Check for missing required capabilities

**"Build Not Available"**:
- Wait for processing (can take 1-2 hours)
- Check email for any issues
- Verify build number is unique

### 10. Testing Checklist

Before uploading:
- [ ] App builds without errors
- [ ] App runs on device (not just simulator)
- [ ] All features work
- [ ] No crashes on launch
- [ ] Icons are present
- [ ] Launch screen works
- [ ] Build number is incremented

## Quick Reference

**Bundle ID**: `com.winespectator.WineLens2026`  
**Current Version**: `1.0`  
**Current Build**: `1`  
**Next Build**: `2` (increment this!)

**App Store Connect**: https://appstoreconnect.apple.com  
**TestFlight App**: Available on App Store

## Next Steps

1. ✅ Create app in App Store Connect (if not done)
2. ✅ Archive and upload first build
3. ✅ Set up Internal Testing group
4. ✅ Add yourself as tester
5. ✅ Start testing!

---

**Note**: First upload always takes longest (24-48 hours). Subsequent updates are much faster (1-2 hours)!

