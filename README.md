# Wine List Assistant

Monorepo for **Wine Lens** (iOS) and its **backend API** (Node/TypeScript on Vercel).

## Repository layout

| Path | What it is |
|------|------------|
| `ios/WineLensApp/` | Xcode project, SwiftUI app, unit/UI tests |
| `backend/` | Vercel serverless API (`api/`), Algolia search, Supabase-related tooling |

Architecture, data flow, and diagrams: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Sharing Xcode projects in Git (for the team)

Xcode works well in Git if you commit the **project** and **shared** SPM state, and ignore **machine-local** noise.

### Do commit

- **`*.xcodeproj/`** — project file, `project.pbxproj`, and the **shared** workspace data under `project.xcworkspace/xcshareddata/` (includes **`swiftpm/Package.resolved`** so everyone gets the same Lottie version).
- **Source folders** synced by the project (`WineLensApp/`, tests, assets).
- **Team-scheme** files if you add shared schemes under `xcshareddata/xcschemes/` (optional; schemes in personal `xcuserdata` are not shared by default).

### Do not commit

- **`xcuserdata/`** — per-developer UI state, breakpoints, personal scheme tweaks.
- **`DerivedData/`**, local **`build/`** output, **`.DS_Store`**.
- **Secrets** — API keys, Google Cloud Vision keys, provisioning details. Use `Info.plist` / `.xcconfig` gitignored locally, or CI secrets.

This repo’s [`.gitignore`](.gitignore) is set up for the above. After clone, each developer opens the same `.xcodeproj`; Xcode resolves Swift packages from `Package.resolved` on first build.

### Clone and run the iOS app

1. Clone the repository.
2. Open `ios/WineLensApp/WineLensApp.xcodeproj` in Xcode.
3. Select the **WineLensApp** scheme and a simulator or device.
4. **⌘B** to build. SPM will fetch **Lottie** automatically.

Configure optional keys locally (not committed): `GOOGLE_CLOUD_VISION_API_KEY`, `WLA_API_KEY` as referenced in `AppConfiguration.swift`.

### Clone and run the backend

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

Fill in `.env` from `backend/.env.example` (Algolia, Supabase, JWT as needed). `vercel dev` requires the [Vercel CLI](https://vercel.com/docs/cli). See `backend/package.json` for `build`, `lint`, and DB scripts.

---

## Quick reference: builds

| Component | Tooling |
|-----------|---------|
| iOS app | Xcode 16+ (project targets **iOS 18**); Swift **5**; SPM (**Lottie**) |
| Backend | Node **≥ 18**; **TypeScript** → `tsc`; deploy **Vercel** (`api/` routes) |

For detailed stack and request flows, use **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**.
