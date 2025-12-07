#!/bin/bash

# Script to verify all Swift files are included in Xcode project
# Usage: ./scripts/verify-xcode-files.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT="$PROJECT_ROOT/ios/WineLensApp/WineLensApp/WineLensApp.xcodeproj/project.pbxproj"
SWIFT_FILES_DIR="$PROJECT_ROOT/ios/WineListAssistant"

echo "🔍 Checking Xcode project file inclusion..."
echo ""

# Find all Swift files in WineListAssistant
SWIFT_FILES=$(find "$SWIFT_FILES_DIR" -name "*.swift" -type f | sort)

MISSING_FILES=()
ALL_PRESENT=true

# Use while loop with process substitution to handle spaces in paths
while IFS= read -r swift_file; do
    filename=$(basename "$swift_file")
    
    # Check if file is referenced in project.pbxproj (exact filename match)
    if grep -q "/$filename" "$XCODE_PROJECT" || grep -q "\"$filename\"" "$XCODE_PROJECT" || grep -q "$filename" "$XCODE_PROJECT"; then
        echo "✅ $filename"
    else
        echo "❌ MISSING: $filename"
        MISSING_FILES+=("$swift_file")
        ALL_PRESENT=false
    fi
done < <(printf '%s\n' $SWIFT_FILES)

echo ""

if [ "$ALL_PRESENT" = true ]; then
    echo "✅ All Swift files are included in Xcode project!"
    exit 0
else
    echo "⚠️  Warning: ${#MISSING_FILES[@]} file(s) are missing from Xcode project:"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "These files need to be manually added to the Xcode project."
    echo "Open the project in Xcode and add them through the UI, or update project.pbxproj manually."
    exit 1
fi

