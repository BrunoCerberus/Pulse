# Development

[← Back to README](../README.md) · [Features](features.md) · [Architecture](architecture.md) · [CI/CD](ci-cd.md) · [Testing](testing.md)

## Requirements

- Xcode 26.5+
- iOS 26.5+
- Swift 6.2+

## Setup

```bash
brew install xcodegen
make setup
open Pulse.xcodeproj
```

`make setup` runs `install-xcodegen` + `generate`. To bootstrap the full toolchain instead — Homebrew (if missing), XcodeGen, Mint, SwiftLint, SwiftFormat, and a `make lint` pre-commit git hook — run `make init`.

### On-device LLM model (required for AI features)

The Gemma 3 1B GGUF model (~756 MB) powers Daily Digest and Article Summarization. It is **gitignored** due to size, so each developer must download it before those features will work — the app surfaces an error if it is missing:

```bash
huggingface-cli download bartowski/google_gemma-3-1b-it-GGUF \
  --include "gemma-3-1b-it-Q4_K_M.gguf" \
  --local-dir Pulse/Resources/Models/
```

See [`Pulse/Resources/Models/README.md`](../Pulse/Resources/Models/README.md) for details and a manual-download alternative.

### API keys

Keys are resolved in order: **Firebase Remote Config** (primary) → **environment variables** (`#if DEBUG` builds only) → **Keychain** (user-provided). For DEBUG builds you can override the Supabase URL via env:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
```

There is **no** `SUPABASE_ANON_KEY` env override — the Supabase anon key is sourced from Remote Config only (the Edge Functions API does not require auth). The NewsAPI/GNews keys (`NEWS_API_KEY`, `GNEWS_API_KEY`) also have DEBUG env fallbacks.

Release builds use Remote Config + Keychain only (env-var fallbacks are `#if DEBUG`-gated). The NewsAPI/GNews Remote Config keys are validated at ≥10 chars; the Supabase URL is validated as non-empty. See `APIKeysProvider.swift`, `SupabaseConfig.swift`.

## Commands

```bash
make init                # bootstrap dev tooling (Homebrew/XcodeGen/Mint + SwiftFormat + SwiftLint) + git pre-commit hook
make setup | xcode       # xcodegen setup / open in Xcode
make build | build-release
make test | test-unit | test-ui | test-snapshot | test-debug
make coverage | coverage-report | coverage-badge
make lint | format
make bump-{patch,minor,major}
make deeplink-test | clean | clean-packages | docs
```

New source files require `make generate` (folded into `make setup`) to land in the Xcode project.

## Dependencies

| Package | Purpose |
|---------|---------|
| [EntropyCore](https://github.com/BrunoCerberus/EntropyCore) | UDF protocols, networking, DI |
| [Firebase](https://github.com/firebase/firebase-ios-sdk) | Auth, Remote Config, Analytics, Crashlytics |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | Google Sign-In |
| [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) | Snapshot tests |
| [Lottie](https://github.com/airbnb/lottie-ios) | Animations |
| [swift-llama-cpp](https://github.com/BrunoCerberus/swift-llama-cpp) | On-device LLM (SwiftLlama + [llama.cpp](https://github.com/ggml-org/llama.cpp)) |

> Firebase links four products: `FirebaseAuth`, `FirebaseRemoteConfig` (the primary API-key source), `FirebaseAnalytics`, and `FirebaseCrashlytics`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Build fails | `make clean && make generate` |
| Package resolution | `make clean-packages && make setup` |
| Test timeouts | check async `Task.sleep` + `.sink` waits |
| Snapshot mismatch | re-record references (never lower precision) |
| Service not found | verify `PulseSceneDelegate.registerLiveServices()` |
| AI features error out | confirm the Gemma GGUF model is downloaded (see Setup) |
