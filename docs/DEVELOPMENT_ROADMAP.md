# Wine List Assistant - Development Roadmap
## State-of-the-Art Implementation Guide

---

## Overview

This document outlines the optimal development approach for building a production-ready Wine List Assistant app. We'll use modern tooling, best practices, and cutting-edge ML/AR capabilities.

---

## Technology Decisions

### Why These Choices?

| Decision | Choice | Why State-of-the-Art |
|----------|--------|---------------------|
| **Package Management** | Swift Package Manager | Apple-native, no CocoaPods/Carthage complexity |
| **Architecture** | MVVM + Clean Architecture | Testable, maintainable, scalable |
| **Concurrency** | Swift async/await + Actors | Modern, safe, performant |
| **UI** | SwiftUI + iOS 17+ | Declarative, animations, accessibility built-in |
| **OCR** | Apple Vision + Custom ML | On-device, fast, private |
| **Wine Matching** | Vector embeddings + Elasticsearch | Semantic search, handles variations |
| **AR Overlay** | Vision coordinates + SwiftUI | Simpler than ARKit, reliable |
| **Backend** | Node.js/TypeScript + PostgreSQL | Fast dev, type-safe, scalable |
| **Search** | Elasticsearch + pgvector | Fuzzy matching + semantic search |
| **CI/CD** | Xcode Cloud | Apple-native, automatic signing |
| **Analytics** | TelemetryDeck | Privacy-first, GDPR compliant |

---

## Development Phases

### Phase 1: Foundation (Current → Week 2)
- [x] Project planning & documentation
- [x] iOS project structure & Swift code
- [ ] **Xcode project setup** ← YOU ARE HERE
- [ ] Backend API scaffolding
- [ ] Database schema & seed data
- [ ] Basic API integration

### Phase 2: Core ML Pipeline (Weeks 3-4)
- [ ] Wine name extraction model (NER)
- [ ] Vintage/price pattern detection
- [ ] Confidence scoring system
- [ ] Edge case handling

### Phase 3: Search & Matching (Weeks 5-6)
- [ ] Elasticsearch setup with wine data
- [ ] Fuzzy matching tuning
- [ ] Vector embeddings for semantic search
- [ ] Match accuracy testing (target: 85%+)

### Phase 4: iOS Polish (Weeks 7-8)
- [ ] AR overlay refinement
- [ ] Haptic feedback
- [ ] Accessibility (VoiceOver)
- [ ] Performance optimization
- [ ] Unit & UI tests

### Phase 5: Backend & Infrastructure (Weeks 9-10)
- [ ] User authentication (Sign in with Apple)
- [ ] Subscription verification
- [ ] API rate limiting & caching
- [ ] Monitoring & alerting

### Phase 6: Launch Prep (Weeks 11-12)
- [ ] App Store assets
- [ ] TestFlight beta
- [ ] Wine list testing (100+ lists)
- [ ] Bug fixes & polish

---

## Step-by-Step Execution Plan

### Step 1: Xcode Project Setup
**What we'll do:**
1. Create Xcode project with proper configuration
2. Add Swift Package dependencies
3. Configure signing & capabilities
4. Set up project structure

**Dependencies to add:**
- None required for MVP (all Apple frameworks)
- Optional: KeychainAccess, TelemetryDeck

**You'll need:**
- Mac with Xcode 15+
- Apple Developer account
- ~30 minutes

---

### Step 2: Backend API Setup
**What we'll do:**
1. Create Node.js/TypeScript API
2. Set up PostgreSQL database
3. Create wine data schema
4. Build core endpoints
5. Add Elasticsearch for search

**You'll need:**
- Decision: Self-hosted vs cloud (Vercel, Railway, AWS)
- PostgreSQL instance
- Elasticsearch instance (or Algolia as alternative)
- ~2-3 hours

---

### Step 3: Wine Database Population
**What we'll do:**
1. Define data import format
2. Create import scripts
3. Build search index
4. Validate data quality

**You'll need:**
- Access to Wine Spectator review database
- Data export in CSV/JSON format
- ~1-2 hours for setup, then import time depends on data size

---

### Step 4: Connect iOS to API
**What we'll do:**
1. Configure API endpoints
2. Test authentication flow
3. Verify search/match functionality
4. Handle offline mode

**You'll need:**
- Running backend from Step 2
- ~1-2 hours

---

### Step 5: ML Model Enhancement (Optional but Recommended)
**What we'll do:**
1. Train custom NER model for wine names
2. Improve OCR post-processing
3. Add confidence calibration

**You'll need:**
- Training data (wine list images + annotations)
- Create ML or external ML platform
- ~1-2 weeks if pursuing

---

## Immediate Next Step

**Let's start with Step 1: Xcode Project Setup**

I'll create:
1. Xcode project file (.xcodeproj)
2. Package.swift with dependencies
3. Info.plist with required permissions
4. Build configurations (Debug/Release)
5. Asset catalog structure

Then you'll:
1. Open in Xcode
2. Select your development team
3. Build & run on simulator

Ready to proceed?

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            iOS APP                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Presentation Layer                         │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │   │
│  │  │ Scanner  │  │ Wine     │  │ My Wines │  │ Settings │        │   │
│  │  │ View     │  │ Detail   │  │ View     │  │ View     │        │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │   │
│  │       │              │              │              │              │   │
│  │  ┌────┴─────────────┴──────────────┴──────────────┴─────┐       │   │
│  │  │                    ViewModels                          │       │   │
│  │  └────┬─────────────────────────────────────────────────┘       │   │
│  └───────┼─────────────────────────────────────────────────────────┘   │
│          │                                                              │
│  ┌───────┼─────────────────────────────────────────────────────────┐   │
│  │       │               Domain Layer                               │   │
│  │  ┌────┴────┐  ┌─────────────┐  ┌─────────────┐                  │   │
│  │  │ Scanner │  │   Wine      │  │    User     │                  │   │
│  │  │ Service │  │   Matching  │  │   Service   │                  │   │
│  │  └────┬────┘  │   Service   │  └──────┬──────┘                  │   │
│  │       │       └──────┬──────┘         │                          │   │
│  │  ┌────┴────┐         │                │                          │   │
│  │  │   OCR   │         │                │                          │   │
│  │  │ Service │         │                │                          │   │
│  │  └─────────┘         │                │                          │   │
│  └──────────────────────┼────────────────┼──────────────────────────┘   │
│                         │                │                              │
│  ┌──────────────────────┼────────────────┼──────────────────────────┐   │
│  │                      │   Data Layer   │                          │   │
│  │  ┌───────────────────┴────────────────┴───────────────────┐     │   │
│  │  │                    API Client                            │     │   │
│  │  └───────────────────────────┬────────────────────────────┘     │   │
│  │                              │                                    │   │
│  │  ┌─────────────┐    ┌───────┴───────┐    ┌─────────────┐        │   │
│  │  │ Local Cache │    │   Keychain    │    │  UserDefs   │        │   │
│  │  └─────────────┘    └───────────────┘    └─────────────┘        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              BACKEND                                     │
│                                                                          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │   API       │    │   Auth      │    │  Webhook    │                 │
│  │   Gateway   │───▶│   Service   │    │  Handler    │                 │
│  └──────┬──────┘    └─────────────┘    └─────────────┘                 │
│         │                                                                │
│  ┌──────┴──────────────────────────────────────────────┐               │
│  │                  Wine Service                         │               │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │               │
│  │  │   Search    │  │   Match     │  │   Review    │  │               │
│  │  │   Engine    │  │   Engine    │  │   Service   │  │               │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │               │
│  └─────────┼────────────────┼────────────────┼─────────┘               │
│            │                │                │                          │
│  ┌─────────┴────────────────┴────────────────┴─────────┐               │
│  │                    Data Stores                        │               │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │               │
│  │  │ PostgreSQL  │  │Elasticsearch│  │    Redis    │  │               │
│  │  │  (wines,    │  │  (search    │  │  (cache,    │  │               │
│  │  │   users)    │  │   index)    │  │   sessions) │  │               │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │               │
│  └──────────────────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Decision Points for You

Before we proceed, I need your input on:

### 1. Backend Hosting
- **Option A: Managed (Recommended for speed)**
  - Vercel (API) + Supabase (PostgreSQL) + Algolia (Search)
  - Pros: Fast setup, auto-scaling, minimal ops
  - Cons: Higher cost at scale

- **Option B: Self-managed**
  - AWS/GCP with Docker
  - Pros: Full control, lower cost at scale
  - Cons: More setup, ops overhead

### 2. Wine Database Access
- Do you have access to Wine Spectator's review database?
- What format is it in? (SQL, CSV, API?)
- Approximately how many reviews?

### 3. Development Environment
- Do you have a Mac with Xcode 15+?
- Apple Developer account (for TestFlight/App Store)?

### 4. Timeline Priority
- **Fast MVP**: Skip ML enhancements, use basic fuzzy matching
- **High Accuracy**: Invest in custom ML models, more testing
- **Both**: Phased approach (MVP first, enhance later)

---

Let me know your answers and we'll proceed with Step 1!
