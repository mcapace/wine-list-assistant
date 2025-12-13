# App Store Connect Setup Guide

## App ID Registration (Apple Developer Portal)

### Bundle ID
**Enter**: `com.winespec.winelensapp`

### Description
**Enter**: `Wine Lens - Wine Spectator's smart wine list scanner`

### Required Capabilities to Enable

Based on your app's features, enable these capabilities:

#### **Essential (Required)**
1. ✅ **In-App Purchase**
   - Required for premium subscriptions
   - Your app uses StoreKit for subscriptions

2. ✅ **Push Notifications** (Optional but Recommended)
   - For subscription updates and notifications
   - Can enable later if needed

#### **Optional (Recommended)**
3. ✅ **Associated Domains**
   - If you want deep linking from your website
   - Format: `applinks:yourdomain.com`

4. ✅ **App Groups** (If using extensions)
   - Only if you plan to add app extensions
   - Can skip for now

#### **Not Needed (Skip These)**
- ❌ Background Modes (Camera works without this)
- ❌ CloudKit (unless you add cloud sync)
- ❌ HealthKit (not needed)
- ❌ HomeKit (not needed)
- ❌ CarPlay (not needed)
- ❌ All other capabilities (skip unless you have specific needs)

### Minimum Required Setup

**For basic functionality, you only need:**
1. ✅ **In-App Purchase** - For subscriptions

**Everything else can be added later if needed.**

---

## App Store Connect - App Information

### Basic Information

**App Name**: `Wine Lens` (or `Wine Spectator Wine Lens`)

**Subtitle**: `Smart wine list scanner`

**Category**: 
- Primary: **Food & Drink**
- Secondary: **Lifestyle** (optional)

**Bundle ID**: `com.winespec.winelensapp`

**SKU**: `wine-lens-app` (unique identifier, can be anything)

**Language**: English (U.S.)

### Pricing and Availability

**Price**: Free (with in-app purchases)

**Availability**: All countries (or select specific countries)

### App Privacy

**Data Collection**: You'll need to answer questions about:
- Camera usage (Required - for scanning)
- User content (if saving wines)
- Identifiers (for subscriptions)

**Privacy Policy URL**: Required if collecting any data

### App Information

**Description**:
```
Wine Lens is the smartest way to navigate any wine list. 
Point your camera at a restaurant wine list and instantly see 
Wine Spectator scores, expert reviews, and value ratings.

Features:
• Scan any wine list with your camera
• See Wine Spectator scores instantly
• Expert reviews from professional blind tastings
• Find the best value wines
• Save your favorite bottles
• Filter by score, price, and drink window

Powered by 40+ years of Wine Spectator expertise.
```

**Keywords**: `wine, wine list, wine spectator, wine scanner, wine app, restaurant, sommelier`

**Support URL**: Your support website
**Marketing URL**: (Optional) Your marketing website

### Version Information

**Version**: `1.0`
**Build**: `1` (increment for each upload)

### App Icon

**Required**: 1024x1024 PNG
- No transparency
- No rounded corners (Apple adds them)
- No text or UI elements

### Screenshots

**Required for iPhone:**
- 6.7" (iPhone 14 Pro Max, 15 Pro Max): 1290 x 2796
- 6.5" (iPhone 11 Pro Max, XS Max): 1242 x 2688
- 5.5" (iPhone 8 Plus): 1242 x 2208

**At minimum, provide:**
- 6.7" screenshots (most common now)

**Screenshot Requirements:**
- Show the scanner view
- Show the matched wines list
- Show wine detail view
- No placeholder text
- Must show actual app functionality

### Age Rating

**Select**: 17+ (or 4+ if no alcohol imagery)
- Reason: References to alcoholic beverages

### App Review Information

**Contact Information**:
- First Name
- Last Name
- Phone Number
- Email Address

**Demo Account** (if login required):
- Username
- Password

**Notes** (Optional):
```
This app scans wine lists using the camera and displays 
Wine Spectator scores. No login required for basic scanning.
Premium subscription unlocks unlimited scans.
```

---

## In-App Purchase Setup

### Subscription Products

Create two subscription products:

1. **Monthly Premium**
   - Product ID: `com.winespec.winelensapp.premium.monthly`
   - Display Name: `Wine Lens Premium Monthly`
   - Price: Set your price (e.g., $4.99/month)
   - Duration: 1 Month

2. **Yearly Premium**
   - Product ID: `com.winespec.winelensapp.premium.yearly`
   - Display Name: `Wine Lens Premium Yearly`
   - Price: Set your price (e.g., $39.99/year)
   - Duration: 1 Year

### Subscription Group

Create a subscription group:
- Name: `Wine Lens Premium`
- Add both monthly and yearly products to this group

---

## Quick Checklist

### Before First Submission

- [ ] App ID registered with In-App Purchase enabled
- [ ] App created in App Store Connect
- [ ] Bundle ID matches: `com.mcapace.winelens`
- [ ] App icon (1024x1024) uploaded
- [ ] Screenshots uploaded (at least 6.7" iPhone)
- [ ] Description and keywords filled in
- [ ] Age rating selected
- [ ] Privacy policy URL (if collecting data)
- [ ] In-App Purchase products created
- [ ] App reviewed and ready for submission

### First Upload

1. Archive app in Xcode
2. Upload to App Store Connect
3. Wait for processing (24-48 hours first time)
4. Add to TestFlight for testing
5. Submit for App Review

---

## Common Issues

**"Invalid Bundle ID"**
- Make sure Bundle ID in Xcode matches App Store Connect exactly
- Check for typos: `com.mcapace.winelens`

**"Missing Capability"**
- Enable In-App Purchase in App ID settings
- Re-download provisioning profiles in Xcode

**"Missing Screenshots"**
- Required for App Store submission
- Can use simulator screenshots for testing

---

## Next Steps

1. ✅ Register App ID with In-App Purchase
2. ✅ Create app in App Store Connect
3. ✅ Fill in all required information
4. ✅ Upload first build
5. ✅ Test in TestFlight
6. ✅ Submit for review

