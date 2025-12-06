# Google Cloud Vision API Setup Guide

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Click **"Select a project"** → **"New Project"**
4. Enter project name: `wine-list-assistant` (or your preferred name)
5. Click **"Create"**
6. Wait for project creation (~30 seconds)

## Step 2: Enable Cloud Vision API

1. In the Google Cloud Console, go to **"APIs & Services"** → **"Library"**
2. Search for **"Cloud Vision API"**
3. Click on **"Cloud Vision API"**
4. Click **"Enable"**
5. Wait for API to be enabled (~1 minute)

## Step 3: Create API Key

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"+ CREATE CREDENTIALS"** → **"API Key"**
3. Copy the API key (you'll need this)
4. **IMPORTANT**: Click **"Restrict Key"** to secure it:
   - Under **"API restrictions"**, select **"Restrict key"**
   - Check **"Cloud Vision API"**
   - Click **"Save"**

## Step 4: Set Up Billing (Required)

1. Go to **"Billing"** in the left menu
2. Click **"Link a billing account"**
3. Add a payment method (credit card)
4. **Note**: Google Cloud offers $300 free credit for new accounts
5. Cloud Vision API pricing: **$1.50 per 1,000 images** (first 1,000/month free)

## Step 5: Add API Key to iOS App

### Option A: Add to Info.plist (Recommended for Development)

1. Open your Xcode project
2. Find `Info.plist` in your project navigator
3. Right-click → **"Add Row"**
4. Key: `GOOGLE_CLOUD_VISION_API_KEY`
5. Type: `String`
6. Value: Your API key (paste it here)

### Option B: Add via Build Settings (Recommended for Production)

1. In Xcode, select your project
2. Go to **"Build Settings"** tab
3. Search for **"Info.plist Preprocessor Definitions"**
4. Add: `GOOGLE_CLOUD_VISION_API_KEY=$(GOOGLE_CLOUD_VISION_API_KEY)`
5. Add the key to your build configuration or environment variables

### Option C: Add to Xcode Scheme (For Testing)

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Select **"Run"** → **"Arguments"**
3. Under **"Environment Variables"**, add:
   - Name: `GOOGLE_CLOUD_VISION_API_KEY`
   - Value: Your API key

## Step 6: Test the Integration

1. Build and run your app
2. Go to Scanner view
3. The app will automatically use Google Cloud Vision if the API key is configured
4. You can switch between providers in app settings (coming soon)

## Pricing Information

- **Free Tier**: First 1,000 images per month free
- **After Free Tier**: $1.50 per 1,000 images
- **Example**: 10,000 scans/month = ~$13.50/month

## Security Best Practices

1. **Restrict API Key**: Only allow Cloud Vision API access
2. **iOS App Restrictions**: Add your app's bundle ID to key restrictions (optional but recommended)
3. **Monitor Usage**: Set up billing alerts in Google Cloud Console
4. **Never commit API keys to git**: Use environment variables or secure storage

## How It Works

The app now supports two OCR providers:

1. **Apple Vision** (Default)
   - Free, offline, fast
   - Good for standard text
   - No internet required

2. **Google Cloud Vision** (Enhanced)
   - Better accuracy for complex layouts
   - Requires internet connection
   - Costs $1.50 per 1,000 images after free tier

The app will automatically use Google Cloud Vision if:
- API key is configured
- User has selected it in settings (or it's the default)
- Internet connection is available

## Troubleshooting

### API Key Not Working
- Verify the key is correctly added to Info.plist
- Check that the API key is not restricted to specific apps
- Ensure Cloud Vision API is enabled in your Google Cloud project

### High Costs
- Monitor usage in Google Cloud Console
- Set up billing alerts
- Consider using Apple Vision for real-time scanning, Google Cloud for captured photos only

### Network Errors
- Check internet connection
- Verify API key is valid
- Check Google Cloud Console for API quota limits

## Next Steps

After completing these steps:
1. ✅ API key is configured
2. ✅ Google Cloud Vision is integrated
3. ✅ App can switch between providers
4. 🔄 Add provider selection in Settings (optional enhancement)
