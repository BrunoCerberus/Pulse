# Architecture

[← Back to README](../README.md) · [Features](features.md) · [Development](development.md) · [CI/CD](ci-cd.md) · [Testing](testing.md)

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

Core protocols from **`EntropyCore`**: `CombineViewModel`, `CombineInteractor`, `ViewStateReducing`, `DomainEventActionMap`. Dependency injection is handled by `ServiceLocator` (an EntropyCore `final class`, not a protocol). Design-system primitives (`Spacing`, `Typography`, `CornerRadius`, `HapticManager`, `Logger`) also come from EntropyCore.

## Navigation

Coordinator + per-tab `NavigationPath`, size-class adaptive: `AnimatedTabView` on iPhone (compact), `NavigationSplitView` sidebar + `AdaptiveDetailStack` detail on iPad (regular). `@MainActor Coordinator` owns the five tab paths (home, media, feed, bookmarks, search), `selectedTab`, and `build(page:)`. Settings is reached via a pushed `Page.settings`, not a standalone tab.

`DeeplinkRouter` routes URL schemes through the `Coordinator`. Views are generic over their router type (e.g. `HomeView<R: HomeNavigationRouter>`). Note: `HomeNavigationRouter` is a concrete `final class`, so the constraint resolves to that single type — test doubles use a real router constructed with `coordinator: nil` rather than a mock conforming type.

## Project Structure

```
Pulse/
├── Pulse/                        # app source
│   ├── Authentication/ Home/ Media/ MediaDetail/ Feed/ Digest/
│   ├── Summarization/ ArticleDetail/ Intents/ QuickActions/ SharedURL/
│   ├── Bookmarks/ ReadingHistory/ CloudSync/ Search/ Settings/
│   ├── Notifications/ AppLock/ Onboarding/ Paywall/ SplashScreen/
│   ├── ForYou/ ForYouSettings/ Personalization/
│   ├── Configs/                  # Navigation, DesignSystem, Models, Networking, AI,
│   │                             # Storage, CloudSync, Analytics, Mocks, Widget
│   └── Documentation.docc/       # DocC bundle (Architecture, GettingStarted, Pulse)
├── PulseWidgetExtension/         # WidgetKit + TTS Live Activity
├── PulseWidgetExtensionTests/
├── PulseShareExtension/          # public.url → App Group queue
├── PulseTests/                   # Swift Testing
├── PulseUITests/                 # XCTest + accessibility audits
├── PulseSnapshotTests/           # SnapshotTesting
├── docs/                         # GitHub Pages legal/support site (HTML)
├── docs-guide/                   # this developer documentation
├── .github/workflows/            # CI/CD
└── .claude/commands/             # Claude Code slash commands
```

See [`CLAUDE.md`](../CLAUDE.md) for the full key-files table and [`AGENTS.md`](../AGENTS.md) for conventions and how to add a feature.

## Deeplinks

All system integrations (App Intents, Quick Actions, Share Extension, push handlers) funnel through `DeeplinkManager`, which parses a `pulse://` URL into a `Deeplink` value that `DeeplinkRouter` then routes through the `Coordinator`.

| URL | |
|---|---|
| `pulse://home` / `media` / `feed` / `bookmarks` / `search` / `settings` | tabs (`settings` pushes the Settings page) |
| `pulse://search?q=query` | search with query |
| `pulse://article?id=path/to/article` | specific article |
| `pulse://media?type=video` (or `podcast`) | media tab filtered by type |
| `pulse://shared` | drain the Share Extension's App Group URL queue |
| `pulse://category?name=<category>` | **deprecated** — redirects to the Home tab (kept for backward compatibility) |

### Push payloads

`NotificationDeeplinkParser` converts three push-notification payload shapes into deeplinks:

- `{"deeplink": "pulse://..."}` *(recommended)*
- `{"articleID": "world/2024/..."}` *(legacy shorthand)*
- `{"deeplinkType": "search|article|home|feed|bookmarks|settings", "deeplinkQuery": "...", "deeplinkId": "..."}`

### App Lock interaction

While App Lock is engaged, `DeeplinkRouter` holds incoming deeplinks (Quick Actions, push, `pulse://` launches) in a FIFO queue and drains them only after the user authenticates with biometrics/passcode — so a deeplink target never appears behind the lock overlay.
