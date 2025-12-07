# Xcode Project Maintenance Guide

## Project Structure

**Xcode Project File:** `ios/WineLensApp/WineLensApp/WineLensApp.xcodeproj`  
**Source Files Location:** `ios/WineLensApp/WineLensApp/`

The project uses `PBXFileSystemSynchronizedRootGroup`, which means Xcode automatically syncs files from the `WineLensApp` folder. **Work directly in `ios/WineLensApp/WineLensApp/`** - new files will be auto-detected.

## Automatic Verification

We have scripts in place to ensure all Swift files are included in the Xcode project:

### Quick Check
```bash
./scripts/verify-xcode-files.sh
```

This will verify all Swift files in `ios/WineLensApp/WineLensApp/` are referenced in the Xcode project file.

### Pre-commit Hook

A git pre-commit hook automatically checks this before each commit. If files are missing, the commit will be blocked with instructions.

## Adding New Files to Xcode

### Method 1: Through Xcode UI (Recommended)
1. Open `ios/WineLensApp/WineLensApp/WineLensApp.xcodeproj` in Xcode
2. Right-click the target folder in Project Navigator
3. Select "Add Files to WineLensApp..."
4. Navigate to the new Swift file
5. Ensure "Copy items if needed" is unchecked
6. Ensure your target is checked
7. Click "Add"

### Method 2: Manual project.pbxproj Update
If you need to add files programmatically, you must:
1. Add a `PBXFileReference` entry
2. Add a `PBXBuildFile` entry  
3. Add the file to the appropriate group
4. Add the build file to the Sources build phase

**⚠️ Warning:** Manually editing `project.pbxproj` is error-prone. Use Xcode UI when possible.

## Verification Checklist

After making changes, always:
- [ ] Run `./scripts/verify-xcode-files.sh`
- [ ] Open project in Xcode and verify files appear
- [ ] Build the project to ensure no missing file errors
- [ ] Commit and push changes

## Project Structure

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` pointing to `ios/WineLensApp/WineLensApp/`:
- Core models: `Core/Models/`
- Services: `Core/Services/`
- Views: `Features/*/Views/`
- ViewModels: `Features/*/ViewModels/`

**Important:** Work directly in `ios/WineLensApp/WineLensApp/` - Xcode will automatically detect new files. No need to manually add them to `project.pbxproj` when using file system synchronization.

