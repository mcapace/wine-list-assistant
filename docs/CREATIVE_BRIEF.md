# Wine Spectator Wine Lens - Creative Brief

## Brand Identity

### App Name
**Wine Spectator Wine Lens**
- Short form: **Wine Lens** (for icon, casual reference)
- Tagline options:
  - "See what the experts see"
  - "Instant expertise, every pour"
  - "Your sommelier, in your pocket"

### Brand Positioning
The definitive wine companion app that brings Wine Spectator's 40+ years of expertise to any wine list, instantly. Premium, authoritative, yet approachable.

---

## Visual Design System

### Color Palette

```
┌─────────────────────────────────────────────────────────────┐
│  PRIMARY COLORS                                              │
├─────────────────────────────────────────────────────────────┤
│  Wine Burgundy     #8B1538    Primary brand color           │
│  Gold Accent       #C9A227    Premium highlights, scores    │
│  Deep Black        #0A0A0A    Primary background            │
│  Charcoal          #1C1C1E    Card surfaces, secondary bg   │
├─────────────────────────────────────────────────────────────┤
│  SCORE COLORS                                                │
├─────────────────────────────────────────────────────────────┤
│  Classic (95-100)  #FFD700    Gold - exceptional wines      │
│  Outstanding (90-94) #C9A227  Amber gold                    │
│  Very Good (85-89) #8B8B8B    Silver                        │
│  Good (80-84)      #6B6B6B    Muted                         │
├─────────────────────────────────────────────────────────────┤
│  UI COLORS                                                   │
├─────────────────────────────────────────────────────────────┤
│  Text Primary      #FFFFFF    Headlines, scores             │
│  Text Secondary    #A1A1A6    Body text, labels             │
│  Text Tertiary     #636366    Captions, metadata            │
│  Divider           #2C2C2E    Subtle separators             │
│  Success           #34C759    Drink now indicators          │
│  Warning           #FF9F0A    Approaching drink window      │
│  Destructive       #FF453A    Errors, past drink window     │
└─────────────────────────────────────────────────────────────┘
```

### Typography

| Element | Font | Weight | Size | Tracking |
|---------|------|--------|------|----------|
| Score Display | SF Pro Rounded | Bold | 72pt | -2% |
| Wine Name | SF Pro Display | Semibold | 20pt | 0 |
| Producer | SF Pro Display | Medium | 17pt | 0 |
| Body Text | SF Pro Text | Regular | 15pt | 0 |
| Caption | SF Pro Text | Regular | 13pt | 0 |
| Button | SF Pro Text | Semibold | 17pt | 0 |
| Tab Bar | SF Pro Text | Medium | 10pt | 0 |

### App Icon Concepts

#### Concept A: "The Lens"
```
┌────────────────────┐
│                    │
│    ┌──────────┐    │
│    │    🍷    │    │  Wine glass silhouette
│    │  ════    │    │  inside camera lens rings
│    │          │    │  Burgundy gradient bg
│    └──────────┘    │
│                    │
└────────────────────┘
```

#### Concept B: "The Score"
```
┌────────────────────┐
│  ┏━━━━━━━━━━━━━┓   │
│  ┃             ┃   │  Bold "95" in gold
│  ┃     95      ┃   │  on burgundy background
│  ┃             ┃   │  Subtle wine glass watermark
│  ┗━━━━━━━━━━━━━┛   │
└────────────────────┘
```

#### Concept C: "WS Monogram"
```
┌────────────────────┐
│                    │
│       ╭───╮        │  Interlocked W+S
│      ╱ W ╲ S       │  in elegant gold
│     ╱     ╲        │  on deep burgundy
│    ╰───────╯       │
│                    │
└────────────────────┘
```

**Recommendation:** Concept A - establishes camera/lens functionality while keeping wine central.

---

## Animation Specifications

### 1. Scan Pulse Animation
**Trigger:** When camera is actively scanning
**Duration:** 2s loop
**Easing:** easeInOutSine
```
Frame 0:    Outer ring opacity 0%, scale 1.0
Frame 50:   Outer ring opacity 40%, scale 1.05
Frame 100:  Outer ring opacity 0%, scale 1.1, repeat
```
**Style:** Concentric rings emanating from center, burgundy with gold highlights

### 2. Score Reveal Animation
**Trigger:** When wine is matched
**Duration:** 600ms
**Easing:** spring(damping: 0.7, stiffness: 300)
```
Frame 0:    Score at 0, opacity 0, scale 0.5
Frame 40:   Count up animation begins
Frame 80:   Score reaches final value
Frame 100:  Scale overshoots to 1.1, settles to 1.0
```
**Enhancement:** Gold particle burst for 95+ scores

### 3. Wine Card Entrance
**Trigger:** When wine info card appears
**Duration:** 400ms
**Easing:** spring(damping: 0.8)
```
Frame 0:    translateY(100%), opacity 0
Frame 60:   translateY(-10%), opacity 1
Frame 100:  translateY(0%), opacity 1
```
**Style:** Slide up from bottom with subtle bounce

### 4. AR Overlay Pop-in
**Trigger:** When score badge appears over wine on list
**Duration:** 300ms
**Easing:** spring(damping: 0.6, stiffness: 400)
```
Frame 0:    scale(0), rotation(-15deg)
Frame 70:   scale(1.15), rotation(5deg)
Frame 100:  scale(1.0), rotation(0deg)
```
**Style:** Playful pop with slight rotation

### 5. Liquid Fill (Score Visualization)
**Trigger:** Detail view score display
**Duration:** 1200ms
**Easing:** easeOutQuart
```
Wine glass fills from bottom to top
Fill level = score percentage (e.g., 95 = 95% full)
Color shifts from burgundy to gold at top
Subtle wave animation on liquid surface
```

### 6. Tab Bar Glow
**Trigger:** Tab selection
**Duration:** 200ms
**Style:** Selected tab icon gets subtle gold glow/halo effect

### 7. Haptic Feedback Map
| Action | Haptic Type |
|--------|-------------|
| Wine detected | .medium impact |
| Score revealed | .success notification |
| 95+ wine found | .success + .rigid |
| Error/no match | .warning notification |
| Button tap | .light impact |
| Save wine | .success notification |

---

## Screen-by-Screen Design Notes

### 1. Scanner View (Main Screen)
```
┌─────────────────────────────────┐
│ ≡                    ⚙️  👤     │  Nav bar (translucent)
├─────────────────────────────────┤
│                                 │
│                                 │
│     ┌─────────────────────┐     │
│     │                     │     │
│     │   CAMERA VIEWFINDER │     │  Full-bleed camera
│     │                     │     │
│     │   ┌───┐             │     │
│     │   │95 │ Wine Name   │     │  AR overlays appear here
│     │   └───┘             │     │
│     │                     │     │
│     └─────────────────────┘     │
│                                 │
│    ○ Scanning for wines...      │  Status indicator
│                                 │
├─────────────────────────────────┤
│ 🔍 Scan    📚 My Wines    ⭐    │  Tab bar
└─────────────────────────────────┘
```

**Key Elements:**
- Camera fills 80% of screen
- Frosted glass nav bar (SF Symbols)
- Floating status pill at bottom
- Scan target reticle (subtle, animated)
- Score badges float over recognized text

### 2. Wine Detail Sheet
```
┌─────────────────────────────────┐
│ ━━━━━━━━━━━━                    │  Drag indicator
├─────────────────────────────────┤
│                                 │
│            ╭───────╮            │
│            │  95   │            │  Large score badge
│            ╰───────╯            │  with glow effect
│                                 │
│  Opus One                       │  Producer
│  Red Blend Napa Valley 2021     │  Wine name + vintage
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🍷 Drink 2025-2045          ││  Info chips
│  │ 💰 $450                     ││
│  │ 🌍 California               ││
│  └─────────────────────────────┘│
│                                 │
│  TASTING NOTES                  │
│  "A powerful, concentrated      │
│  red with layers of black       │
│  currant, graphite..."          │
│                                 │
│  ┌────────┐ ┌────────┐          │
│  │  Save  │ │ Share  │          │
│  └────────┘ └────────┘          │
└─────────────────────────────────┘
```

**Interactions:**
- Pull-to-dismiss
- Score badge pulses on appear
- Tasting notes expandable
- Save button animates (heart fill or bookmark)

### 3. My Wines (Collection)
```
┌─────────────────────────────────┐
│ My Wines                    +   │
├─────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ │
│ │ All │ │ 95+ │ │Drink│ │Value│ │  Filter chips
│ └─────┘ └─────┘ └─────┘ └─────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 97  │ Screaming Eagle       │ │  Wine cards
│ │     │ Cabernet 2021 • $850  │ │  (horizontal scroll
│ └─────────────────────────────┘ │   or grid)
│ ┌─────────────────────────────┐ │
│ │ 95  │ Opus One              │ │
│ │     │ Red Blend 2021 • $450 │ │
│ └─────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

### 4. Onboarding Flow (4 screens)

**Screen 1: "Point & Scan"**
- Animation: Phone pointing at wine list, scan lines moving
- Copy: "Point your camera at any wine list"

**Screen 2: "Instant Scores"**
- Animation: Score badges appearing over wine names
- Copy: "See Wine Spectator scores instantly"

**Screen 3: "Deep Knowledge"**
- Animation: Card expanding to show tasting notes
- Copy: "Tap for tasting notes, drink windows & more"

**Screen 4: "Start Free"**
- Animation: Subtle confetti/celebration
- Copy: "5 free scans every month. Upgrade anytime."
- CTA: "Get Started" button

---

## Asset Checklist

### Required Design Assets

#### App Icon
- [ ] 1024x1024 App Store icon
- [ ] Adaptive icon (iOS 18+)
- [ ] macOS icon variant
- [ ] watchOS icon (if applicable)

#### Launch Screen
- [ ] Launch screen storyboard or SwiftUI
- [ ] Animated logo (Lottie)

#### Onboarding
- [ ] 4 illustration/animation sets (Lottie preferred)
- [ ] Background patterns/gradients

#### UI Elements
- [ ] Custom score badge component
- [ ] Wine glass fill animation (Lottie)
- [ ] Scan pulse animation (Lottie)
- [ ] Empty state illustrations (3-4)
- [ ] Error state illustration
- [ ] Subscription paywall artwork

#### Tab Bar Icons
- [ ] Scan (camera lens + wine glass)
- [ ] My Wines (wine rack/cellar)
- [ ] Settings (gear)
- [ ] Profile (person)

#### App Store
- [ ] 6 screenshot sets (6.7", 6.5", 5.5")
- [ ] App preview video (30 seconds)
- [ ] Feature graphic (1024x500)

### Lottie Animations Needed

| Animation | Duration | Loops | File |
|-----------|----------|-------|------|
| Scan pulse | 2s | Yes | scan_pulse.json |
| Score reveal | 0.6s | No | score_reveal.json |
| Score reveal 95+ | 0.8s | No | score_reveal_gold.json |
| Card entrance | 0.4s | No | card_enter.json |
| Wine glass fill | 1.2s | No | glass_fill.json |
| Success check | 0.5s | No | success.json |
| Empty cellar | 3s | Yes | empty_cellar.json |
| Loading sommelier | 2s | Yes | loading.json |
| Onboarding 1-4 | 3s each | Yes | onboard_1-4.json |

---

## Technical Specifications

### Supported Devices
- iPhone 12 and later (iOS 16+)
- Camera required
- A14 Bionic or later for optimal AR performance

### Accessibility
- VoiceOver support for all scores and wine info
- Dynamic Type support
- High contrast mode
- Reduce Motion support (disable animations)

### Localization (Phase 2)
- English (US) - Launch
- French, Italian, Spanish, German - Post-launch
- Japanese, Chinese - Future

---

## Next Steps

1. **Approve color palette and typography**
2. **Select app icon direction (A, B, or C)**
3. **Commission Lottie animations** (recommend LottieFiles marketplace or custom designer)
4. **Create Figma/Sketch design system**
5. **Design onboarding illustrations**
6. **Produce App Store screenshots**

---

## Reference Apps for Inspiration

- **Vivino** - Wine scanning UX
- **Shazam** - Instant recognition animation
- **Apple Translate** - AR text overlay
- **Halide** - Premium camera UI
- **Robinhood** - Score/number animations
- **Stripe** - Micro-interactions and polish

---

*Document Version: 1.0*
*Last Updated: December 2024*
