# Wine List Assistant — architecture & flow

High-level stack and how requests move through the system. For repo layout and Git/Xcode practices, see the [root README](../README.md).

---

## System context

```mermaid
flowchart TB
    subgraph clients["Clients"]
        IOS[Wine Lens iOS app]
    end

    subgraph apple_google["Apple & Google"]
        AVF[AVFoundation / Camera]
        Vision[Apple Vision framework]
        GCV[Google Cloud Vision API]
    end

    subgraph backend["Backend — Vercel"]
        API[Vercel Node functions — api/]
    end

    subgraph data["Data & search"]
        ALG[Algolia wines index]
        SB[(Supabase — auth / DB as configured)]
    end

    IOS --> AVF
    IOS --> Vision
    IOS -->|optional OCR| GCV
    IOS -->|HTTPS JSON| API
    SB -.->|used where configured| API
    API --> ALG
```

**Stack summary**

| Layer | Technology |
|-------|------------|
| iOS UI | SwiftUI, iOS 18 target, Lottie (SPM) |
| On-device | Camera capture; OCR via Apple Vision and/or Google Cloud Vision |
| API | TypeScript on **Vercel** (`backend/api/`) |
| Search | **Algolia** (`wines` index) via `backend/lib/algolia.ts` |
| Data / auth | **Supabase** (per env; client may call additional routes as the app evolves) |

---

## Wine list scan → match (happy path)

```mermaid
sequenceDiagram
    participant User
    participant App as Wine Lens iOS
    participant OCR as Apple Vision / Google Vision
    participant API as Vercel API
    participant Algolia as Algolia

    User->>App: Capture / choose wine list image
    App->>OCR: Extract text lines
    OCR-->>App: Raw line strings
    App->>API: POST /wines/batch-match (lines as queries)
    API->>Algolia: Search per line / batch logic
    Algolia-->>API: Wine hits + confidence
    API-->>App: Matched wines JSON
    App->>User: Show ratings / Spectator data on list
```

**Related API routes in this repo (wines)**

| Method | Route | Role |
|--------|--------|------|
| GET | `/api/wines/search?q=…` | Fuzzy search with filters (color, vintage, min_score, …) |
| POST | `/api/wines/batch-match` | Match many OCR lines to wines in one call |
| GET | `/api/wines/[id]` | Single wine by id |

The iOS client (`WineAPIClient`) is also coded against paths such as **saved wines** and **subscription verify**; implement or stub those on the backend as your product completes those features.

---

## Configuration flow (environments)

```mermaid
flowchart LR
    subgraph ios_config["iOS — AppConfiguration"]
        ENV[DEBUG vs RELEASE]
        BASE[apiBaseURL]
        KEYS[Info.plist keys e.g. GOOGLE_CLOUD_VISION_API_KEY]
    end

    subgraph deploy["Deployment"]
        VERCEL[Vercel deployment URL]
        ENVV[ALGOLIA_* env vars]
    end

    ENV --> BASE
    BASE -->|HTTPS| VERCEL
    ENVV --> VERCEL
    KEYS -->|OCR| GCV_EXT[Google Vision endpoint]
```

Point the app’s **`apiBaseURL`** at your team’s Vercel preview or production host; avoid committing production secrets in source.

---

## Dependency direction

```mermaid
flowchart TB
    subgraph ios["iOS"]
        APP[WineLensApp]
        LOTTIE[Lottie SPM]
    end

    subgraph server["Backend"]
        VERCEL[Vercel API]
        ALG[Algolia]
    end

    APP --> LOTTIE
    APP -->|HTTPS REST| VERCEL
    VERCEL --> ALG
```

The mobile app does not talk to Algolia directly; credentials stay on the server. The app depends on **Lottie** via Swift Package Manager for animations.
