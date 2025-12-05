# Lottie Animation Setup

## Adding Lottie Package

The app uses Lottie animations for enhanced UX. To enable them:

1. **Open Xcode Project**
2. **File → Add Package Dependencies...**
3. **Enter URL:** `https://github.com/airbnb/lottie-spm`
4. **Select version:** Latest (or 4.3.0+)
5. **Add to target:** WineLensApp (or your app target)
6. **Click Add Package**

## Animation Files

Animation JSON files are located in:
- `ios/WineListAssistant/Resources/Animations/`

Available animations:
- `Scan_Pulse.json` - Scanning indicator animation
- `Score_Reveal.json` - Score reveal animation
- `Wine_Glass_Fill.json` - Wine glass fill animation
- `Card_Slide_Up.json` - Card slide up animation

## Usage

The `LottieView.swift` component provides easy-to-use wrappers:

```swift
// In your SwiftUI view
ScanPulseAnimation()
    .frame(width: 50, height: 50)

ScoreRevealAnimation()
    .frame(width: 100, height: 100)
```

## Fallback

If Lottie package is not added, the app will show a fallback icon instead of crashing.

