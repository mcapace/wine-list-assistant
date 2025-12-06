# Bundle ID Troubleshooting Guide

If you're getting "not available" for multiple bundle IDs, here are solutions:

## Common Issues

### 1. Wrong Format
Bundle IDs must follow reverse domain notation:
- ✅ Correct: `com.winespectator.winelens`
- ❌ Wrong: `winespectator.winelens` (missing TLD)
- ❌ Wrong: `winelens` (not reverse domain)

### 2. Using Reserved Domains
Apple may restrict certain domains. Try:
- Your personal domain: `com.yourname.winelens`
- Your company domain: `com.yourcompany.winelens`
- Generic format: `io.winelens.app`

### 3. Account Type Issue
- **Personal Team**: May have restrictions on bundle IDs
- **Organization Account**: More flexibility

## Solutions

### Option 1: Use Your Personal/Company Domain
If you have a domain, use it:
- `com.yourdomain.winelens`
- `io.yourdomain.winelens`
- `app.yourdomain.winelens`

### Option 2: Use Generic Format
Try these patterns:
- `io.winelens.app`
- `app.winelens.scanner`
- `com.winelens.app`
- `net.winelens.app`

### Option 3: Add More Specificity
- `com.winespectator.winelens.scanner`
- `com.winespectator.winelens.mobile`
- `com.winespectator.winelens.ios.app`

### Option 4: Check Your Apple Developer Account
1. Go to [developer.apple.com](https://developer.apple.com)
2. Check your account status
3. Verify you have an active membership
4. Check if there are any restrictions

### Option 5: Use Xcode to Generate
1. In Xcode, go to Signing & Capabilities
2. Click the Bundle Identifier field
3. Xcode may suggest available alternatives
4. Or try "Automatically manage signing" - Xcode will help

## Quick Test

Try this exact format in Apple Developer Portal:
```
com.winespectator.winelens.scanner
```

If that doesn't work, try:
```
io.winelens.app
```

## Alternative: Use Your Email Domain

If you have an email like `mike@example.com`, you could use:
- `com.example.winelens`
- `io.example.winelens`

## Still Not Working?

1. **Check Apple Developer Portal Status**
   - Make sure you're logged in
   - Verify your membership is active
   - Check for any account restrictions

2. **Try Different Browser**
   - Sometimes cache issues
   - Try incognito/private mode

3. **Contact Apple Developer Support**
   - If nothing works, there may be an account issue
   - Apple Developer Support can help

## What to Tell Me

Once you find a bundle ID that works, tell me:
- The exact bundle ID you registered
- I'll update everything in the codebase

