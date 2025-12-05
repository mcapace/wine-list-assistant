# Wine Spectator Wine List Assistant

> *Like Google Translate for fine wine*

A mobile application that uses smartphone camera technology to scan restaurant wine lists and instantly overlay Wine Spectator's trusted critic scores. Transform wine list anxiety into confident ordering.

## The Problem

Every wine lover has faced it: wine list anxiety. You're handed a 60-page menu, names and vintages blur together, and the prices seem random. Is that $525 Montrachet worth it? Is the $175 bottle a steal?

## The Solution

Using your smartphone camera, the app scans any wine list and instantly overlays Wine Spectator's trusted, unbiased critic scores right on your screen. Filter by score (only wines over 90 points), drink window, or best values.

**Key differentiator:** Unlike crowd-sourced alternatives (Vivino, Delectable), this app is powered by editorially-driven reviews from credible blind tastings conducted by highly experienced tasters.

## Features

### Consumer (B2C)
- **Real-time scanning** - Point camera at wine list, see scores instantly
- **AR overlay** - Score badges appear next to recognized wines
- **Smart filters** - Filter by score (90+), drink window, best value
- **Wine details** - Tap for full tasting notes, drink windows, prices
- **Save & share** - Build personal wine lists

### Business (B2B)
- **List analysis** - Upload wine list for comprehensive analysis
- **Markup alerts** - Flag wines outside acceptable markup ranges
- **Drink window alerts** - Identify wines past their prime
- **Replacement suggestions** - Find alternatives for out-of-stock wines

## Documentation

| Document | Description |
|----------|-------------|
| [Project Plan](docs/PROJECT_PLAN.md) | Full project overview, phases, monetization, risks |
| [iOS Technical Spec](docs/IOS_TECHNICAL_SPEC.md) | iOS architecture, code structure, Swift implementation |
| [API Specification](docs/API_SPECIFICATION.md) | Backend API design, endpoints, authentication |

## Technology Stack

### iOS (Primary Platform)
- Swift 5.9+ / SwiftUI
- Apple Vision (OCR)
- ARKit (AR overlay)
- AVFoundation (camera)
- StoreKit 2 (subscriptions)

### Android (Phase 2)
- Kotlin / Jetpack Compose
- ML Kit (OCR)
- ARCore (AR overlay)

### Backend
- REST API
- PostgreSQL (wine database)
- Elasticsearch (fuzzy matching)
- Redis (caching)

## Development Phases

1. **Foundation** (Weeks 1-4) - Architecture, design, API contracts
2. **Core Scanner MVP** (Weeks 5-12) - Camera, OCR, matching, overlay
3. **Polish & Filters** (Weeks 13-18) - Filters, accounts, subscriptions
4. **Launch Prep** (Weeks 19-22) - QA, optimization, App Store prep
5. **Launch & Iterate** (Weeks 23-28) - Launch, feedback, improvements
6. **B2B Features** (Weeks 29-36) - Business tools
7. **Android** (Weeks 37-50) - Android app development

## Key Technical Challenges

1. **OCR in low light** - Restaurant lighting optimization
2. **Fuzzy wine matching** - Handling abbreviations, misspellings, formatting variations
3. **Real-time AR performance** - Smooth overlay with moving camera
4. **Vintage handling** - Same wine, different vintages, different scores

## Monetization

### Consumer
- **Free tier:** 5 scans/month, basic scores
- **Premium:** $9.99/month or $79.99/year - unlimited scans, full notes, filters

### Business
- **Pro:** $999/year - 1 user, list analysis
- **Enterprise:** $2,499/year - 5 users, markup analysis, API access

## Project Status

**Current Phase:** Planning & Architecture

## Team

- Product concept: Jeffrey Lindenmuth
- Technical planning: In progress

---

*Wine Spectator - The World's Most Authoritative Wine Publication*
