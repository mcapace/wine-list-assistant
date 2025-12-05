# Wine Spectator Wine List Assistant
## Project Plan & Technical Specification

---

## Executive Summary

The Wine List Assistant is a mobile application that uses smartphone camera technology to scan restaurant wine lists and instantly overlay Wine Spectator's trusted critic scores. The app transforms the often-overwhelming experience of selecting wine at a restaurant into a confident, informed decision.

**Tagline:** *"Like Google Translate for fine wine"*

### Core Value Proposition
- Eliminates "wine list anxiety" at restaurants
- Leverages Wine Spectator's authoritative, editorially-driven blind tasting reviews
- Provides real-time AR overlay of scores, drink windows, and value indicators
- Differentiates from crowd-sourced competitors with professional critic credibility

---

## Table of Contents

1. [Product Vision & Goals](#product-vision--goals)
2. [Target Users](#target-users)
3. [Core Features](#core-features)
4. [User Flows](#user-flows)
5. [Technical Architecture](#technical-architecture)
6. [Data Requirements](#data-requirements)
7. [Key Technical Challenges](#key-technical-challenges)
8. [Platform Strategy](#platform-strategy)
9. [Development Phases](#development-phases)
10. [Monetization Strategy](#monetization-strategy)
11. [Success Metrics](#success-metrics)
12. [Risk Assessment](#risk-assessment)

---

## Product Vision & Goals

### Vision
Become the definitive companion app for wine enthusiasts dining out, powered by the world's most trusted wine publication.

### Primary Goals
1. **Reduce friction** in wine selection at restaurants
2. **Monetize** Wine Spectator's proprietary tasting database in a new format
3. **Increase brand engagement** beyond traditional web/print channels
4. **Create recurring revenue** through subscription model
5. **Establish B2B revenue stream** with restaurant/sommelier tools

### Success Criteria (Year 1)
- 100,000+ downloads
- 20,000+ active subscribers
- 50+ B2B restaurant accounts
- 4.5+ App Store rating

---

## Target Users

### B2C: Consumer Segment

#### Primary Persona: "The Confident Amateur"
- **Demographics:** 35-55 years old, $100K+ household income
- **Behavior:** Dines out 2-4x/month at mid-to-upscale restaurants
- **Pain Point:** Wants to appear knowledgeable but lacks deep wine expertise
- **Goal:** Make smart wine choices without relying on sommelier

#### Secondary Persona: "The Wine Enthusiast"
- **Demographics:** 30-60 years old, active wine collector
- **Behavior:** Already subscribes to Wine Spectator, has wine cellar
- **Pain Point:** Can't remember all scores/vintages when dining out
- **Goal:** Quick reference to WS ratings for informed decisions

#### Tertiary Persona: "The Value Seeker"
- **Demographics:** 28-45 years old, budget-conscious
- **Behavior:** Looks for best value, not necessarily highest score
- **Pain Point:** Doesn't know if restaurant markup is reasonable
- **Goal:** Find the best quality-to-price ratio wines

### B2B: Business Segment

#### Restaurant/Sommelier Users
- **Use Case:** Analyze and optimize wine list
- **Pain Points:**
  - Identifying weak spots in wine program
  - Ensuring appropriate markup ranges
  - Managing aging inventory (drink windows)
  - Finding replacement wines when stock runs out
- **Willingness to Pay:** $1,000+/year for premium tools

#### Wine Distributors/Importers
- **Use Case:** Competitive analysis, placement optimization
- **Pain Points:** Understanding which wines restaurants favor
- **Willingness to Pay:** Higher tier pricing

---

## Core Features

### Consumer Features (MVP)

#### 1. Wine List Scanner
- **Description:** Point camera at wine list, real-time detection
- **Technology:** OCR + AR overlay
- **Output:** WS score badges appear next to recognized wines
- **Priority:** P0 (Critical)

#### 2. Score Overlay
- **Description:** Visual AR overlay showing:
  - WS Score (e.g., "93")
  - Score color indicator (90+ green, 85-89 yellow, <85 red)
  - "Not Reviewed" indicator for unrated wines
- **Priority:** P0 (Critical)

#### 3. Wine Detail View
- **Description:** Tap any recognized wine for:
  - Full tasting note
  - Wine Spectator score
  - Drink window (e.g., "Now-2030")
  - Retail/release price from WS database
  - Vintage variation info
- **Priority:** P0 (Critical)

#### 4. Smart Filters
- **Description:** Filter overlays by:
  - Minimum score (e.g., "Show only 90+")
  - Drink window (e.g., "Ready to drink now")
  - Best value (score-to-price ratio)
- **Priority:** P1 (High)

#### 5. Save & Share
- **Description:**
  - Save wines to personal list
  - Share wine info via text/email
  - Export scanned list as PDF
- **Priority:** P2 (Medium)

#### 6. Purchase Links
- **Description:** "Buy similar" links to wine retailers (affiliate revenue)
- **Priority:** P2 (Medium)

### Business Features (B2B)

#### 7. List Analysis Dashboard
- **Description:** Upload or scan complete wine list for:
  - Coverage report (% of wines with WS scores)
  - Score distribution analysis
  - Drink window alerts (aging wines)
  - Markup analysis vs. release prices
- **Priority:** P1 (High)

#### 8. Replacement Suggestions
- **Description:** For out-of-stock wines, suggest:
  - Same producer, different vintage
  - Similar style/region/price point
  - Wines with comparable scores
- **Priority:** P2 (Medium)

#### 9. Markup Alerts
- **Description:** Flag wines outside acceptable markup range
- **Configurable:** Set custom markup window (e.g., 2.5x-3.5x)
- **Priority:** P2 (Medium)

#### 10. Drink Window Alerts
- **Description:** Alert on wines past optimal drinking
- **Batch Processing:** Analyze entire list automatically
- **Priority:** P2 (Medium)

---

## User Flows

### Primary Flow: Restaurant Scanning

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER AT RESTAURANT                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. OPEN APP                                                     │
│     • Quick launch to camera view                                │
│     • No login required for basic scanning                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. POINT CAMERA AT WINE LIST                                    │
│     • Hold phone 8-12 inches from page                           │
│     • Auto-focus and stabilization                               │
│     • Works in low restaurant lighting                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. REAL-TIME RECOGNITION                                        │
│     • OCR processes visible text                                 │
│     • Fuzzy matching against WS database                         │
│     • 1-3 second recognition time                                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. AR OVERLAY DISPLAY                                           │
│     • Score badges appear next to wines                          │
│     • Color-coded by score range                                 │
│     • "?" for unreviewed wines                                   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. APPLY FILTERS (Optional)                                     │
│     • "90+ Only" button                                          │
│     • "Best Values" button                                       │
│     • "Ready Now" drink window filter                            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. TAP FOR DETAILS                                              │
│     • Full review card slides up                                 │
│     • Tasting notes, drink window, price                         │
│     • Save to favorites or share                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  7. ORDER WITH CONFIDENCE                                        │
│     • User makes informed decision                               │
│     • Optional: rate the experience                              │
└─────────────────────────────────────────────────────────────────┘
```

### Secondary Flow: Saved Wine Lookup

```
User opens app → My Wines tab → Scrolls saved wines → Taps for details
```

### B2B Flow: List Analysis

```
Login as Business → Upload Wine List (PDF/Photo) → Processing →
Dashboard with analytics → Export report → Action items
```

---

## Technical Architecture

### High-Level System Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              MOBILE APP (iOS/Android)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Camera    │  │     OCR     │  │  AR Engine  │  │  Local DB   │     │
│  │   Module    │  │   Engine    │  │   Overlay   │  │   (Cache)   │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │                │             │
│         └────────────────┴────────────────┴────────────────┘             │
│                                   │                                       │
└───────────────────────────────────┼───────────────────────────────────────┘
                                    │ HTTPS/REST
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY                                   │
│                    (Authentication, Rate Limiting, Caching)                │
└───────────────────────────────────┬───────────────────────────────────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         ▼                          ▼                          ▼
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Wine Matching │      │   Review Data   │      │   User Service  │
│     Service     │      │     Service     │      │                 │
│                 │      │                 │      │  • Auth         │
│  • Fuzzy match  │      │  • Scores       │      │  • Preferences  │
│  • NLP/Entity   │      │  • Notes        │      │  • Saved wines  │
│  • Confidence   │      │  • Prices       │      │  • Subscription │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  ▼
                    ┌─────────────────────────┐
                    │   Wine Spectator DB     │
                    │                         │
                    │  • 450,000+ reviews     │
                    │  • Scores & notes       │
                    │  • Release prices       │
                    │  • Producer data        │
                    └─────────────────────────┘
```

### iOS App Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS APPLICATION                          │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                              │
│  ├── CameraScanView                                              │
│  ├── AROverlayView                                               │
│  ├── WineDetailSheet                                             │
│  ├── FilterControlsView                                          │
│  ├── MyWinesView                                                 │
│  └── SettingsView                                                │
├─────────────────────────────────────────────────────────────────┤
│  Domain Layer                                                    │
│  ├── WineRecognitionService                                      │
│  ├── WineMatchingService                                         │
│  ├── FilterService                                               │
│  └── UserPreferencesManager                                      │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer                                                      │
│  ├── WineAPIClient                                               │
│  ├── LocalWineCache (Core Data / SQLite)                         │
│  ├── UserDefaultsStorage                                         │
│  └── KeychainManager                                             │
├─────────────────────────────────────────────────────────────────┤
│  Infrastructure                                                  │
│  ├── VisionKit (OCR)                                             │
│  ├── ARKit (Overlay)                                             │
│  ├── AVFoundation (Camera)                                       │
│  └── Combine (Reactive)                                          │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

#### iOS (Primary Platform)
| Component | Technology | Rationale |
|-----------|------------|-----------|
| Language | Swift 5.9+ | Modern, performant, Apple standard |
| UI Framework | SwiftUI | Declarative, future-proof, AR-friendly |
| OCR Engine | Apple Vision | Native, fast, accurate, no licensing |
| AR Framework | ARKit | Native iOS AR, smooth overlay |
| Camera | AVFoundation | Full camera control |
| Networking | URLSession + Async/Await | Native, modern concurrency |
| Local Storage | SwiftData / Core Data | Native persistence |
| Auth | Sign in with Apple + Email | User preference |

#### Android (Future)
| Component | Technology | Rationale |
|-----------|------------|-----------|
| Language | Kotlin | Modern Android standard |
| UI Framework | Jetpack Compose | Declarative, Google recommended |
| OCR Engine | ML Kit (Google) | Free, powerful, on-device |
| AR Framework | ARCore | Google's AR platform |
| Networking | Ktor / Retrofit | Kotlin-friendly |

#### Backend Services
| Component | Technology | Rationale |
|-----------|------------|-----------|
| API Gateway | AWS API Gateway / Cloudflare | Scalable, secure |
| Authentication | Auth0 / AWS Cognito | Enterprise-ready |
| API Framework | Node.js/Express or Python/FastAPI | Flexible, fast development |
| Database | PostgreSQL | Existing WS infrastructure? |
| Caching | Redis | Fast lookups for fuzzy matching |
| Search | Elasticsearch | Fuzzy wine matching |

---

## Data Requirements

### Wine Database Schema (Conceptual)

```
Wine
├── wine_id (PK)
├── producer_name
├── wine_name
├── vintage (nullable for NV)
├── region
├── sub_region
├── appellation
├── country
├── grape_varieties[]
├── color (red/white/rosé/sparkling)
└── producer_id (FK)

Review
├── review_id (PK)
├── wine_id (FK)
├── score (0-100)
├── tasting_note (text)
├── reviewer_initials
├── review_date
├── issue_date (magazine)
├── drink_window_start
├── drink_window_end
├── release_price
└── created_at

Producer
├── producer_id (PK)
├── name
├── country
├── region
└── website
```

### Local Cache Strategy

For latency and offline capability, embed a lightweight local database:

**Cached Locally:**
- Top 10,000 most-searched wines (score, name, vintage)
- Wine name → ID lookup index
- Producer aliases and common misspellings

**Fetched from API:**
- Full tasting notes
- Price data
- Less common wines
- Updated scores

**Cache Refresh:**
- Daily delta sync in background
- Full refresh weekly
- On-demand for new searches

### API Endpoints (Draft)

```
GET  /v1/wines/search?q={ocr_text}&fuzzy=true
     → Returns matched wines with scores

GET  /v1/wines/{wine_id}
     → Returns full wine details

GET  /v1/wines/{wine_id}/reviews
     → Returns all reviews for a wine

POST /v1/wines/batch-match
     → Batch matching for list analysis (B2B)

GET  /v1/user/saved-wines
POST /v1/user/saved-wines
DELETE /v1/user/saved-wines/{wine_id}

POST /v1/subscription/verify
     → Verify App Store/Play Store subscription
```

---

## Key Technical Challenges

### 1. OCR Accuracy in Low Light

**Challenge:** Restaurant lighting is often dim, wine lists may be on dark paper or in leather-bound books.

**Solutions:**
- Use iPhone's advanced low-light camera capabilities
- Implement adaptive brightness/contrast preprocessing
- Allow manual flash/torch activation
- Offer manual photo capture mode as fallback
- Test extensively in real restaurant conditions

### 2. Fuzzy Wine Matching

**Challenge:** Wine names on lists vary wildly from database entries.

**Examples of Variation:**
| Wine List | Database |
|-----------|----------|
| "Opus One '19" | "Opus One 2019" |
| "Ch. Margaux" | "Château Margaux" |
| "Far Niente Chard" | "Far Niente Chardonnay" |
| "Cloudy Bay SB" | "Cloudy Bay Sauvignon Blanc" |
| "DRC Romanée-Conti" | "Domaine de la Romanée-Conti Romanée-Conti" |

**Solutions:**
- **Normalized Search Index:** Pre-process all wine names
  - Strip accents: "Château" → "Chateau"
  - Expand abbreviations: "SB" → "Sauvignon Blanc"
  - Standardize vintage formats: "'19" → "2019"

- **Fuzzy Matching Algorithm:**
  - Levenshtein distance for typos
  - Token-based matching for word order variations
  - Elasticsearch with phonetic analysis

- **Entity Recognition:**
  - Train NLP model to identify: Producer, Wine Name, Vintage, Region
  - Use Wine Spectator's existing data as training set

- **Confidence Scoring:**
  - Return confidence % with each match
  - High confidence (>90%): Show score
  - Medium (70-90%): Show score with indicator
  - Low (<70%): Show "Possible match" or don't display

- **Learning System:**
  - Log unmatched wines
  - Manual curation of common aliases
  - User feedback on incorrect matches

### 3. Real-Time AR Performance

**Challenge:** Smooth overlay while camera moves, wines scroll in/out of view.

**Solutions:**
- Process OCR on every Nth frame (e.g., every 5 frames)
- Use background threads for matching
- Cache match results by screen region
- Implement smooth animation for appearing/disappearing badges
- Test on older iPhone models (minimum: iPhone 11)

### 4. Vintage Handling

**Challenge:** Same wine, different vintages have different scores.

**Solutions:**
- Prioritize exact vintage match
- If vintage not visible, show most recent reviewed vintage with indicator
- Allow user to manually select vintage from list
- Show vintage in score badge (e.g., "93 '18")

### 5. Price Comparison Accuracy

**Challenge:** Release prices may be outdated; retail prices vary by market.

**Solutions:**
- Clearly label as "Release Price" from WS review
- Show price date: "Release: $50 (2020)"
- Calculate value ratio: Score ÷ (Restaurant Price / Release Price)
- Allow user to input local market context (optional)

---

## Platform Strategy

### iOS-First Approach

**Rationale:**
1. **Demographics:** Wine enthusiasts skew toward higher income → higher iPhone ownership
2. **Technical:** ARKit more mature than ARCore for this use case
3. **Development Speed:** Single codebase, native performance
4. **App Store:** Better discovery, higher willingness to pay for premium apps
5. **Testing:** Easier to test with unified hardware profiles

**Timeline:**
- Months 1-6: iOS MVP development
- Month 7: iOS App Store launch
- Months 8-10: iOS iteration based on feedback
- Months 10-14: Android development
- Month 15: Android launch

### Cross-Platform Considerations

**Shared Components:**
- API backend (100% shared)
- Fuzzy matching logic (server-side, shared)
- Business logic models (potential Kotlin Multiplatform in future)
- Design system/style guide

**Platform-Specific:**
- UI implementation (SwiftUI vs Compose)
- Camera/AR integration
- OCR engine (Vision vs ML Kit)
- App Store integrations

---

## Development Phases

### Phase 0: Foundation (Weeks 1-4)

**Deliverables:**
- [ ] Finalize technical architecture
- [ ] Set up development environment & CI/CD
- [ ] Design API contracts
- [ ] Create high-fidelity UI/UX designs
- [ ] Prototype fuzzy matching algorithm
- [ ] Set up analytics framework

**Key Decisions:**
- Backend hosting (AWS/GCP/Azure)
- Authentication provider
- Analytics platform
- CI/CD tooling

### Phase 1: Core Scanner MVP (Weeks 5-12)

**Deliverables:**
- [ ] Camera capture module
- [ ] OCR integration with Apple Vision
- [ ] Basic wine matching (exact + fuzzy)
- [ ] AR score overlay (static badges)
- [ ] Wine detail view (tap for more)
- [ ] Basic API integration

**Milestone:** Internal demo of end-to-end scanning

### Phase 2: Polish & Filters (Weeks 13-18)

**Deliverables:**
- [ ] Improved matching accuracy
- [ ] Score filters (90+, 85+, etc.)
- [ ] Drink window filter
- [ ] Value indicator
- [ ] Save wines functionality
- [ ] User accounts & authentication
- [ ] Subscription integration (StoreKit 2)

**Milestone:** Closed beta with 50 users

### Phase 3: Launch Prep (Weeks 19-22)

**Deliverables:**
- [ ] Performance optimization
- [ ] Extensive QA (100+ wine lists tested)
- [ ] App Store assets & listing
- [ ] Onboarding flow
- [ ] Share functionality
- [ ] Crash reporting & monitoring

**Milestone:** App Store submission

### Phase 4: Launch & Iterate (Weeks 23-28)

**Deliverables:**
- [ ] App Store launch
- [ ] Monitor & respond to user feedback
- [ ] Fix critical bugs
- [ ] Iterate on matching accuracy
- [ ] A/B test onboarding

**Milestone:** 10,000 downloads

### Phase 5: B2B Features (Weeks 29-36)

**Deliverables:**
- [ ] Business account system
- [ ] Bulk list upload
- [ ] Analysis dashboard
- [ ] Markup alerts
- [ ] Drink window alerts
- [ ] Replacement suggestions
- [ ] Export/reporting tools

**Milestone:** 10 paying B2B accounts

### Phase 6: Android (Weeks 37-50)

**Deliverables:**
- [ ] Android app development
- [ ] ML Kit OCR integration
- [ ] ARCore overlay
- [ ] Feature parity with iOS
- [ ] Play Store launch

---

## Monetization Strategy

### Consumer Pricing

#### Freemium Model

**Free Tier:**
- 5 wine scans per month
- Basic score overlay (number only)
- No tasting notes
- Ads displayed

**Premium Subscription ($9.99/month or $79.99/year):**
- Unlimited scans
- Full tasting notes
- Drink windows
- Value indicators
- Filters
- Save & share
- No ads
- Priority matching

**Wine Spectator Subscriber Benefit:**
- Existing WS subscribers get Premium free or discounted
- Drives subscription retention
- Cross-promotion opportunity

### B2B Pricing

**Restaurant Pro ($999/year):**
- 1 user
- Bulk list analysis
- Drink window alerts
- Basic reporting
- Email support

**Restaurant Enterprise ($2,499/year):**
- 5 users
- All Pro features
- Markup analysis
- Replacement suggestions
- API access
- Phone support
- Custom branding option

**Distributor/Group ($4,999+/year):**
- Unlimited users
- Multi-location
- Advanced analytics
- Dedicated support
- Custom integrations

### Additional Revenue

**Affiliate Wine Sales:**
- "Buy This Wine" links to partners (Wine.com, etc.)
- 5-15% commission per sale
- Non-intrusive, value-add for users

---

## Success Metrics

### Product Metrics

| Metric | Target (Year 1) | Measurement |
|--------|-----------------|-------------|
| Downloads | 100,000 | App Store Connect |
| MAU (Monthly Active Users) | 25,000 | Analytics |
| Scans/User/Month | 4+ | Analytics |
| Match Accuracy | >85% | QA sampling |
| App Store Rating | 4.5+ | App Store |
| Crash-Free Sessions | >99.5% | Crashlytics |

### Business Metrics

| Metric | Target (Year 1) | Measurement |
|--------|-----------------|-------------|
| Free→Paid Conversion | 5% | Subscription analytics |
| Paid Subscribers | 5,000 | RevenueCat/StoreKit |
| ARR (Consumer) | $400K | Financial |
| B2B Accounts | 50 | CRM |
| ARR (B2B) | $75K | Financial |
| Churn (Monthly) | <5% | Subscription analytics |

### Engagement Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Session Duration | 3+ min | Analytics |
| Wines Saved/User | 10+ | Database |
| Return User Rate (D7) | 30% | Analytics |
| NPS Score | 50+ | Surveys |

---

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| OCR accuracy in low light | Medium | High | Extensive testing, fallback modes |
| Fuzzy matching failures | Medium | High | ML investment, manual curation |
| AR performance issues | Low | Medium | Performance testing, device limits |
| API latency | Low | High | Edge caching, local database |

### Business Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Low user adoption | Medium | High | Marketing, WS cross-promotion |
| Competitor response | Medium | Medium | First-mover advantage, WS brand |
| Restaurant resistance | Low | Medium | B2B value proposition |
| Subscription fatigue | Medium | High | Compelling free tier, fair pricing |

### Legal/Compliance Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Data privacy concerns | Low | High | GDPR/CCPA compliance, transparency |
| App Store rejection | Low | High | Follow guidelines closely |
| Restaurant complaints | Low | Low | Focus on consumer value |

---

## Next Steps

### Immediate Actions (This Week)

1. **Stakeholder Alignment**
   - Schedule meeting with Jeffrey, Laura, Michael
   - Review and approve project plan
   - Confirm budget and timeline

2. **Technical Discovery**
   - Audit existing Wine Spectator database
   - Evaluate API options for wine data
   - Prototype OCR + matching pipeline

3. **Design Kickoff**
   - Engage UX designer
   - Create user journey maps
   - Begin wireframing

4. **Resource Planning**
   - Identify iOS developer (internal or contractor)
   - Identify backend developer
   - Estimate hosting/infrastructure costs

---

## Appendix

### A. Competitive Analysis

| App | Scores | OCR Scan | AR Overlay | Price |
|-----|--------|----------|------------|-------|
| Vivino | Crowd-sourced | Yes | No | Free |
| Wine Searcher | Aggregated | No | No | Free/Premium |
| Delectable | Crowd-sourced | Yes | No | Free |
| CellarTracker | Crowd-sourced | No | No | Free/Premium |
| **WS Wine List Assistant** | **Expert/Editorial** | **Yes** | **Yes** | **Subscription** |

**Differentiation:** Only app combining professional critic scores with AR overlay technology.

### B. Technical Glossary

- **OCR:** Optical Character Recognition - converting images of text to machine-readable text
- **AR:** Augmented Reality - overlaying digital content on real-world camera view
- **Fuzzy Matching:** Approximate string matching that finds similar (not exact) matches
- **NLP:** Natural Language Processing - understanding and processing human language
- **ARKit:** Apple's AR framework for iOS
- **Vision:** Apple's image analysis framework including OCR

### C. Wine List Examples for Testing

Gather diverse wine lists for testing:
- Fine dining (60+ page lists)
- Casual restaurants (1-2 page lists)
- International restaurants (non-English wines)
- Wine bars (by-the-glass focused)
- Hotel restaurants
- Different printing styles (serif, sans-serif, handwritten)

---

*Document Version: 1.0*
*Created: December 2024*
*Last Updated: December 2024*
