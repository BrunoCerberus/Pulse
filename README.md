# Pulse

A modern iOS news aggregation app built with Clean Architecture, SwiftUI, and Combine. Powered by a self-hosted Supabase RSS aggregator backend.

## Documentation

| Guide | Contents |
|---|---|
| [Features](docs-guide/features.md) | Full feature list + Premium |
| [Architecture](docs-guide/architecture.md) | UDF data flow, navigation, project structure, deeplinks |
| [Development](docs-guide/development.md) | Requirements, setup, API keys, commands, dependencies, troubleshooting |
| [CI/CD](docs-guide/ci-cd.md) | Workflows, privacy conformance, schemes, releasing |
| [Testing](docs-guide/testing.md) | Unit / UI / snapshot / widget tests |

See also [`CLAUDE.md`](CLAUDE.md) for the key-files table and [`AGENTS.md`](AGENTS.md) for conventions.

## Highlights

- **Authentication** — Firebase (Google + Apple) with in-app account deletion and reauthentication.
- **Home / Media / Feed** — breaking news, in-app video + podcast playback, AI Daily Digest (**Premium**).
- **AI on-device** — article summarization and Daily Digest via Gemma 3 1B (**Premium**); personalized For You from on-device topic extraction.
- **Text-to-Speech** — speed presets, language-aware voices, Lock Screen + Dynamic Island Live Activities.
- **Offline-first** — tiered L1 (memory) + L2 (disk) cache, retry/backoff, `NWPathMonitor`, offline banner.
- **iCloud sync** — bookmarks, reading history, preferences, interest topics via CloudKit (always-on, zero-UI).
- **Localization** — English, Portuguese, Spanish (UI + content), no app restart; full accessibility + Dynamic Type.
- **System integrations** — Widget, App Intents / Siri / Spotlight, Share Extension, Home Screen Quick Actions.
- **iPad** — `NavigationSplitView` sidebar, adaptive grids, 720pt reading cap.

A 6-page onboarding runs once after first sign-in. See [Features](docs-guide/features.md) for the complete list and Premium details.

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

Core protocols come from **`EntropyCore`**; navigation is a size-class-adaptive Coordinator + Router. Full details in [Architecture](docs-guide/architecture.md).

## Quick start

```bash
brew install xcodegen
make setup
open Pulse.xcodeproj
```

**Requirements:** Xcode 26.5+ · iOS 26.5+ · Swift 6.2+.

AI features need the on-device LLM model (gitignored, ~756 MB) downloaded first:

```bash
huggingface-cli download bartowski/google_gemma-3-1b-it-GGUF \
  --include "gemma-3-1b-it-Q4_K_M.gguf" \
  --local-dir Pulse/Resources/Models/
```

For DEBUG builds you can override the Supabase URL via `export SUPABASE_URL="..."`; all other keys come from Firebase Remote Config. See [Development](docs-guide/development.md) for the full setup, commands, and dependency list.

## Deeplinks

| URL | |
|---|---|
| `pulse://home` / `media` / `feed` / `bookmarks` / `search` / `settings` | tabs |
| `pulse://search?q=query` | search with query |
| `pulse://article?id=path/to/article` | specific article |
| `pulse://media?type=video` (or `podcast`) | media tab filtered by type |
| `pulse://shared` | drain the Share Extension queue |

The deprecated `pulse://category` redirect and the push-notification payload formats are documented in [Architecture → Deeplinks](docs-guide/architecture.md#deeplinks).

## Data Source

Self-hosted Supabase backend (`pulse-backend` Go RSS worker): aggregates major news, tech, and science RSS feeds (the source list is defined in `pulse-backend`); extracts `og:image` hero images and full content via go-readability (Mozilla Readability port); automatic retention cleanup.

## Privacy & Compliance

Pulse ships a privacy manifest (`Pulse/PrivacyInfo.xcprivacy`) and gates every PR with deterministic **LGPD** (Brazil) and **GDPR** / **CCPA** conformance workflows — PII scanning, docs presence, operational controls, and privacy-manifest structural integrity. Details in [CI/CD → Privacy conformance](docs-guide/ci-cd.md#privacy-conformance).

## Contributing

Fork → branch → changes → `make lint && make test` → PR. Conventional Commit PR titles required.

## License

MIT — see [LICENSE](LICENSE).
