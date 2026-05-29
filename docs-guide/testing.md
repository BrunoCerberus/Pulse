# Testing

[← Back to README](../README.md) · [Features](features.md) · [Architecture](architecture.md) · [Development](development.md) · [CI/CD](ci-cd.md)

```bash
make test          # full suite
make test-unit     # Swift Testing only
make test-ui       # XCUITest only
make test-snapshot # SnapshotTesting only
make test-debug    # verbose, for debugging failures
```

- **Unit** — Swift Testing: ViewModels, Interactors, Reducers with mocks. Fresh `ServiceLocator` per test (never shared); mocks in `Configs/Mocks/` expose `Result` properties to pick success/failure.
- **UI** — XCTest + `performAccessibilityAudit()` on the main tab screens (Home, Media, Bookmarks, Search, Settings). `MOCK_PREMIUM=1` in the launch environment unlocks premium flows.
- **Snapshot** — SnapshotTesting; covers loading/empty/error states, Dynamic Type accessibility sizes (`iPhoneAirAccessibility`, `iPhoneAirExtraExtraLarge`), and iPad (`iPad` 1024×768, `iPadPro13` 1032×1376 with `horizontalSizeClass: .regular` + `userInterfaceIdiom: .pad`). Never lower precision — re-record references if layout changed.
- **Widget extension** — `PulseWidgetExtensionTests` covers the timeline provider, shared data manager, and entry views (run via the `PulseWidgetExtensionTests` scheme).

Snapshot device sizes and the `MOCK_PREMIUM` flag are wired in `PulseSnapshotTests/Helpers/SnapshotTestHelpers.swift` and the UI-test launch arguments respectively.
