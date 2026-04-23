# Pulse

A modern iOS news aggregation app built with Clean Architecture, SwiftUI, and Combine. Powered by a self-hosted Supabase RSS aggregator backend.

## Features

- **Authentication** — Firebase Auth (Google + Apple Sign-In) with in-app account deletion (Apple Guideline 5.1.1(v)), including transparent reauthentication when Firebase requires it.
- **Home / Media / Feed** — breaking news carousel, category filters, recently-read; Videos + Podcasts with in-app playback (YouTube opens externally, podcasts use `AVPlayer`); AI-powered Daily Digest (**Premium**).
- **Article Summarization** — on-device summaries via Gemma 3 1B (**Premium**).
- **Text-to-Speech** — `AVSpeechSynthesizer`, speed presets (1×/1.25×/1.5×/2×), language-aware voices, floating mini-player, AirPods/CarPlay/Lock Screen controls.
- **Offline** — tiered L1 (memory) + L2 (disk) cache, retry with exponential backoff, `NWPathMonitor`, offline banner, graceful degradation.
- **Bookmarks + Reading History** — SwiftData, read indicators, dedicated history view.
- **Search** — full-text with 300ms debounce, suggestions, sort options.
- **Related Articles** — horizontal carousel in ArticleDetail.
- **Enhanced Sharing** — `ShareItemsBuilder` formats `[title — source, URL]`.
- **Localization** — English, Portuguese, Spanish (UI + content), no app restart.
- **Accessibility** — Dynamic Type layout adaptation, VoiceOver heading hierarchy, focus management, live announcements.
- **Security** — input validation, sign-out / account-deletion data wipe, Keychain-backed app lock (biometric + passcode), privacy manifest.
- **Widget + Live Activities** — home screen headlines; TTS on Lock Screen + Dynamic Island.
- **App Intents / Siri / Spotlight** — five intents via `PulseAppShortcuts`.
- **Share Extension** — `public.url` → App Group queue → summarize in the main app (Gemma 3 1B exceeds the extension memory budget).
- **Home Screen Quick Actions** — Search, Daily Digest, Bookmarks, Breaking News (localized, registered dynamically).
- **iCloud Cross-Device Sync** — bookmarks, reading history, and preferences via `NSPersistentCloudKitContainer` (always-on, zero-UI).
- **iPad** — `NavigationSplitView` sidebar on regular width, `LazyVGrid(.adaptive)` article lists, 720pt reading cap.
- **Analytics & Crashlytics** — 25 type-safe Firebase events; Crashlytics breadcrumbs.

The app uses iOS 26 Liquid Glass on the root `TabView` (iPhone) and `NavigationSplitView` sidebar (iPad). Users must sign in with Google or Apple; a 4-page onboarding runs once after first sign-in.

### Premium

StoreKit 2. Two AI features require a subscription: **AI Daily Digest** and **Article Summarization**. Non-premium users see `PremiumGateView` on Feed or a native StoreKit paywall sheet when tapping the summarize button.

## Architecture

Unidirectional Data Flow + Clean Architecture + Combine.

```
View (SwiftUI)
  ↓ ViewEvent             ↑ @Published ViewState
ViewModel (CombineViewModel + EventActionMap + Reducer)
  ↓ DomainAction          ↑ DomainState (Combine)
Interactor (CombineInteractor)
  ↓                        ↑
Service Layer (protocol-based, Live/Mock)
  ↓                        ↑
Network (EntropyCore) + Storage (SwiftData + CloudKit)
```

Core protocols (`EntropyCore`): `CombineViewModel`, `CombineInteractor`, `ViewStateReducing`, `DomainEventActionMap`, `ServiceLocator`.

**Navigation** — Coordinator + per-tab `NavigationPath`, size-class adaptive: `AnimatedTabView` on iPhone, `NavigationSplitView` sidebar + detail on iPad. `DeeplinkRouter` routes URL schemes through the `Coordinator`. Views are generic over their router (`HomeView<R: HomeNavigationRouter>`) for testability.

See `CLAUDE.md` for key files and `AGENTS.md` for conventions and how to add a feature.

## Requirements

- Xcode 26.4+
- iOS 26.4+
- Swift 6.2+

## Setup

```bash
brew install xcodegen
make setup
open Pulse.xcodeproj
```

API keys come from **Firebase Remote Config** (primary). For DEBUG builds you can override via env:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your_anon_key"
```

Release builds use Remote Config + Keychain only (env-var fallbacks are `#if DEBUG`-gated). Remote Config values are validated ≥10 chars. See `APIKeysProvider.swift`, `SupabaseConfig.swift`.

## Commands

```bash
make init                # install Mint + SwiftFormat + SwiftLint
make setup | xcode       # xcodegen setup / open in Xcode
make build | build-release
make test | test-unit | test-ui | test-snapshot | test-debug
make coverage | coverage-report | coverage-badge
make lint | format
make bump-{patch,minor,major}
make deeplink-test | clean | clean-packages | docs
```

## Project Structure

```
Pulse/
├── Pulse/                    # app source
│   ├── Authentication/ Home/ Media/ MediaDetail/ Feed/ Digest/
│   ├── Summarization/ ArticleDetail/ Intents/ QuickActions/ SharedURL/
│   ├── Bookmarks/ ReadingHistory/ CloudSync/ Search/ Settings/
│   ├── Notifications/ AppLock/ Onboarding/ Paywall/ SplashScreen/
│   └── Configs/              # Navigation, DesignSystem, Models, Networking,
│                             # Storage, CloudSync, Analytics, Mocks, Widget
├── PulseWidgetExtension/     # WidgetKit + TTS Live Activity
├── PulseShareExtension/      # public.url → App Group queue
├── PulseTests/               # Swift Testing
├── PulseUITests/             # XCTest + accessibility audits
├── PulseSnapshotTests/       # SnapshotTesting
├── .github/workflows/        # CI/CD
└── .claude/commands/         # Claude Code slash commands
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [EntropyCore](https://github.com/BrunoCerberus/EntropyCore) | UDF protocols, networking, DI |
| [Firebase](https://github.com/firebase/firebase-ios-sdk) | Auth, Analytics, Crashlytics |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | Google Sign-In |
| [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) | Snapshot tests |
| [Lottie](https://github.com/airbnb/lottie-ios) | Animations |
| [swift-llama-cpp](https://github.com/BrunoCerberus/swift-llama-cpp) | On-device LLM (SwiftLlama + [llama.cpp](https://github.com/ggml-org/llama.cpp)) |

## CI/CD

- `ci.yml` — code quality + build + tests on PR
- `claude.yml` — Claude Code on `@claude` mentions
- `claude-code-review.yml` — Claude review on PR open/sync
- `scheduled-tests.yml` — daily at 2 AM UTC

Schemes: `PulseDev`, `PulseProd`, `PulseTests`, `PulseUITests`, `PulseSnapshotTests`.

## Deeplinks

| URL | |
|---|---|
| `pulse://home` / `media` / `feed` / `bookmarks` / `search` / `settings` | tabs |
| `pulse://search?q=query` | search with query |
| `pulse://article?id=path/to/article` | specific article |

## Testing

- **Unit** — Swift Testing: ViewModels, Interactors, Reducers with mocks.
- **UI** — XCTest + `performAccessibilityAudit()` on every main screen.
- **Snapshot** — SnapshotTesting; includes Dynamic Type accessibility and iPad (`iPad` 1024×768, `iPadPro13` 1032×1376) size classes.

## Data Source

Self-hosted Supabase backend (`pulse-backend` Go RSS worker): aggregates Guardian, BBC, TechCrunch, Science Daily, etc.; extracts `og:image` hero images and full content via go-readability (Mozilla Readability port); automatic retention cleanup.

## Contributing

Fork → branch → changes → `make lint && make test` → PR.

## License

MIT — see [LICENSE](LICENSE).
