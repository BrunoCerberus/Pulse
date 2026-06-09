# Features

[← Back to README](../README.md) · [Architecture](architecture.md) · [Development](development.md) · [CI/CD](ci-cd.md) · [Testing](testing.md)

The app uses iOS 26 Liquid Glass on the root `TabView` (iPhone) and `NavigationSplitView` sidebar (iPad). Users must sign in with Google or Apple; a 6-page onboarding runs once after first sign-in (welcome → AI-powered → privacy → stay-connected → choose-topics → get-started).

## Full feature list

- **Authentication** — Firebase Auth (Google + Apple Sign-In) with in-app account deletion (Apple Guideline 5.1.1(v)), including transparent reauthentication when Firebase requires it.
- **Home / Media / Feed** — breaking news carousel, category filters, recently-read; Videos + Podcasts with in-app playback (YouTube opens externally, podcasts use `AVPlayer`); AI-powered Daily Digest (**Premium**).
- **Personalized For You** — on-device topic extraction from reading history surfaces a recommended-articles carousel on Home; opt-in/out and topic controls via For You Settings.
- **Article Summarization** — on-device summaries via Gemma 3 1B (**Premium**).
- **Text-to-Speech** — `AVSpeechSynthesizer`, speed presets (1×/1.25×/1.5×/2×), language-aware voices, floating mini-player, AirPods/CarPlay/Lock Screen controls.
- **Offline** — tiered L1 (memory) + L2 (disk) cache, retry with exponential backoff, `NWPathMonitor`, offline banner, graceful degradation.
- **Bookmarks + Reading History** — SwiftData, read indicators, dedicated history view.
- **Search** — full-text with 300ms debounce, suggestions, sort options.
- **Related Articles** — horizontal carousel in ArticleDetail.
- **Enhanced Sharing** — `ShareItemsBuilder` formats `[title — source, URL]`.
- **Localization** — English, Portuguese, Spanish (UI + content), no app restart.
- **Accessibility** — Dynamic Type layout adaptation, VoiceOver heading hierarchy, focus management, live announcements.
- **Security** — input validation, untrusted-RSS-text sanitization before the on-device LLM (`PromptSanitizer`), HTTPS-only media-URL gate (`SafeMediaURL`), full sign-out / account-deletion data wipe (incl. private CloudKit zone), Keychain-backed app lock (biometric + passcode), an app-switcher privacy cover over the multitasking snapshot while App Lock is enabled, PII sanitization of all analytics event parameters, and a privacy manifest.
- **Widget + Live Activities** — home screen headlines; TTS on Lock Screen + Dynamic Island.
- **App Intents / Siri / Spotlight** — five intents via `PulseAppShortcuts`: Open Pulse, Open Daily Digest, Open Bookmarks, Search Pulse, Open Settings.
- **Share Extension** — `public.url` → App Group queue → summarize in the main app (Gemma 3 1B exceeds the extension memory budget).
- **Home Screen Quick Actions** — Search, Daily Digest, Bookmarks, Breaking News (localized, registered dynamically at scene-connect).
- **iCloud Cross-Device Sync** — bookmarks, reading history, preferences, and interest topics via `NSPersistentCloudKitContainer` (always-on, zero-UI). Engagement signals stay per-device by design.
- **iPad** — `NavigationSplitView` sidebar on regular width, `LazyVGrid(.adaptive)` article lists, 720pt reading cap.
- **Analytics & Crashlytics** — type-safe Firebase events (incl. CloudKit sync lifecycle); Crashlytics breadcrumbs.

## Premium

StoreKit 2. Two AI features require a subscription: **AI Daily Digest** and **Article Summarization**. Non-premium users see `PremiumGateView` on Feed or a native StoreKit paywall sheet when tapping the summarize button. The premium-gated set is defined by the `PremiumFeature` enum (`dailyDigest`, `articleSummarization`).
