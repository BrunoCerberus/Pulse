# THREAT_MODEL.md — Pulse iOS

> **Purpose.** This document scopes security review of the **Pulse iOS client** (this
> repo). It exists so that LLM-assisted and human security passes start from a shared
> picture of trust boundaries, untrusted inputs, and known vulnerability classes —
> rather than re-deriving them (and inflating severity) on every run. It follows
> Adam Shostack's four questions and Anthropic's *Using LLMs to Secure Source Code*
> playbook (threat-model → discovery → verify → triage → patch).
>
> **Scope.** The iOS app, its extensions (Share, Widget/Live Activity), and their CI.
> The Supabase Go RSS worker lives in the separate `pulse-backend` repo and is
> threat-modeled there — **server-side SQLi / RCE / RLS issues are OUT OF SCOPE here.**
> There is no server code in this repository.

---

## 1. What are we building? (Q1)

SwiftUI + Combine news-aggregation app on a unidirectional-data-flow + clean
architecture: `View → ViewModel → DomainInteractor → Service (Live/Mock) → Network
(EntropyCore) + Storage (SwiftData/CloudKit)`. Notable subsystems:

- **Auth** — Firebase (Google + Apple), plus a hidden reviewer-only Anonymous path.
- **Backend** — self-hosted Supabase REST, HTTPS only, language-filtered queries.
- **On-device LLM** — Gemma 3 1B via SwiftLlama (summaries, topic extraction, digest).
- **Storage/sync** — SwiftData + CloudKit private DB; a separate non-CloudKit
  container for per-device engagement signals.
- **System integrations** — deeplinks, App Intents, Quick Actions, Share Extension,
  push notifications, TTS + Live Activities, biometric/passcode App Lock.

## 2. Trust boundaries & data flows (Q2)

### Trusted components (assumed non-hostile)
| Component | Identifier / note |
|---|---|
| Supabase backend | HTTPS only — no plaintext `http://` permitted in `Pulse/Configs/Networking/` (enforced by conformance jobs) |
| Firebase Remote Config | Primary source of `SUPABASE_URL` (non-empty check) + NewsAPI / GNews keys (min 10 chars). No Supabase anon key exists — the Edge Functions API is public/unauthenticated. |
| Keychain | `com.bruno.Pulse.APIKeys` (user-provided keys), `com.pulse.applock`, APNs token — device-only accessibility |
| CloudKit | `iCloud.com.bruno.Pulse-News` — **`.private`** database (per-user) |
| App Lock | Biometric / passcode gate in front of sensitive flows |

### Untrusted inputs (attacker-influenceable — the real attack surface)
| Source | Entry point |
|---|---|
| **Article JSON** (`Article.title` / `.description` / `.content`) — originates from third-party RSS feeds | **Primary untrusted sink.** Flows into the LLM, TTS, and UI. |
| Push `userInfo` payloads (`deeplink`, `deeplinkType`, `deeplinkQuery`, `deeplinkId`, `articleID`) | `NotificationDeeplinkParser` |
| Share-extension `public.url` items | App Group `group.com.bruno.Pulse-News` (unencrypted UserDefaults JSON queue) → `pulse://shared` |
| `pulse://` URL query params (deeplinks, universal links, Quick Actions, App Intents) | `DeeplinkManager.parse` |
| Engagement / personalization signals | Per-device, non-CloudKit container by design |

### Critical data flows
- Article fields → `ArticleSummaryPromptBuilder` / `TopicExtractionPromptBuilder` /
  `FeedDigestPromptBuilder` → on-device Gemma prompt. **Defense today:** HTML stripped +
  content truncated (1500 chars). **Residual:** no prompt-boundary / role-delimiter
  escaping — see §3.
- Article fields → `AVSpeechUtterance` (TTS) → `MPNowPlayingInfoCenter`.
- Article `mediaURL` → inline `VideoPlayerView` `WKWebView` (video) **and**
  `AudioPlayerView` `AVURLAsset` (podcast). Both sinks — and the open-in-browser gates
  (`MediaDetailDomainInteractor.openInBrowser`, `ArticleDetailDomainInteractor.externalURL`)
  — now route through the shared `SafeMediaURL` HTTPS-only gate so the scheme allowlist
  can't drift apart between sinks (the audio sink was previously ungated). The direct-video
  `WKWebView` branch additionally **disables JavaScript and pins navigation to the loaded
  host** (`Coordinator.decidePolicyFor`), so an attacker-controlled HTTPS page can't run
  scripts or redirect into in-WebView phishing. (Inline-video HTTPS gate found by the weekly
  sweep `SWEEP-2026-06-03-01`; the audio gap + JS/navigation hardening closed in the
  follow-up pass.)
- `pulse://` + push → `DeeplinkManager.parse` / `NotificationDeeplinkParser` →
  `DeeplinkRouter`. Article IDs are allowlist-validated; free-text params
  (search query, category name) are length-capped + control-char-stripped at the
  boundary (`Deeplink.sanitizedQueryParameter`).
- Remote Config → `APIKeysProvider` (Remote Config → `#if DEBUG` env var → Keychain).
- Sign-out / delete-account → `SettingsViewModel.clearAllUserData()` (SwiftData + L1/L2
  cache + Keychain + UserDefaults + ThemeManager + widget data).

## 3. What can go wrong? (Q3) — vulnerability classes

These are the classes a discovery pass should target. Each is grounded in an existing
defense or a known residual; look for **unfixed variants** of each.

1. **Prompt injection via untrusted article text** into the on-device Gemma model
   (`ArticleSummaryPromptBuilder.buildArticleContent`, `TopicExtractionPromptBuilder`,
   `FeedDigestPromptBuilder`). `description`/`content` are HTML-stripped + truncated;
   the `title`. The shared `PromptSanitizer` (`Pulse/Configs/AI/PromptSanitizer.swift`) **is
   present and is now called on every untrusted field — including the `title` — in all three
   prompt builders** before interpolation: it strips Gemma turn markers (`<start_of_turn>`
   etc.), maps control characters to spaces, removes backticks, and length-caps each field.
   Output-side, topic tags are charset-constrained (`parseTags`/`sanitizeTag`) before they
   reach CloudKit. **Residual (by design):** plain-language instruction text is deliberately
   not censored (that would break legitimate news coverage), so a poisoned RSS field can still
   steer the model. *Impact is bounded* — on-device model, no tool access, output is a
   user-facing summary / charset-constrained CloudKit tags — so the realistic worst case is
   manipulated output / minor tag pollution, not exfiltration or RCE. Triage accordingly; do
   not inflate.
2. **Unvalidated deeplink / push parameters.** Article IDs get `isValidArticleID`
   (≤512 chars, charset allowlist, no `..`). Free-text params are bounded at the boundary.
   `DeeplinkManager.handle` (the choke point every entry path funnels through) now
   re-validates **all** identifier/free-text cases — `.search`, `.category`, AND `.article` —
   so a caller that constructs a `Deeplink` directly can't bypass `parse`'s validation.
   Verify push-payload fields stay covered in both `DeeplinkManager` and `NotificationDeeplinkParser`.
3. **IPC tampering** via the Share Extension queue (App Group UnencryptedUserDefaults).
   Defense is a URL scheme allowlist + length cap, applied on **both** the write side
   (`enqueue`) and the read side (`readQueue` re-caps the decoded array to `maxQueueSize`,
   and `LiveSharedURLImportService` re-validates each item's scheme). Never trust queue
   contents as well-formed.
4. **Secret handling / leakage.** `#if DEBUG` env-var key fallback must never reach
   Release; analytics + Crashlytics must stay PII-sanitized — the recursive sanitizer is
   now applied on **both** the error path (`recordError`) AND the event path (`logEvent`
   runs `event.parameters` through `sanitize(any:)`). Remote Config values validated
   ≥10 chars before use. Test-only launch-env affordances (`UI_TESTING` /
   `IS_RUNNING_UNIT_TESTS`) are funnelled through `TestEnvironment`, which compiles to
   `false` outside `DEBUG`.
5. **Incomplete data wipe.** Both sign-out and delete-account call `clearAllUserData()`,
   and it is **also** triggered centrally on any `authenticated → unauthenticated`
   transition in `AuthenticationManager` (de-dupes a *concurrent* Settings wipe via a
   single-flight guard, and is idempotent so a sequential re-run is harmless; never fires on
   cold-launch `loading → unauthenticated`), so server-driven sign-outs (token revoked / account
   disabled or deleted on another device) wipe local data too. `LiveAuthService` clears the
   GoogleSignIn session on sign-out / delete. A new persistence store added without wiring
   into `clearAllUserData()` still leaks across account boundaries — keep wiring new stores in.
6. **Entitlement / paywall bypass.** Premium gates re-verify against StoreKit, and the
   LLM execution paths (`SummarizationDomainInteractor.startSummarization`,
   `FeedDomainInteractor.generateDigest`) now re-check `isPremium` at the service boundary,
   not just in the view layer. (Bypass still requires device-level code injection; impact is
   bounded to free on-device compute — no server-side paid data exists in this repo.)

### Past-fix "bug-shape" bootstrap
Mine these for siblings/variants — but **verify presence in the working tree, not
`git log --all`**. The repo carries a family of prepared-but-unmerged `security/pr-*`
branches whose fixes are NOT in master; a `--all` SHA does not mean the fix shipped.

**Merged to master (defenses you can rely on):**
- URL-surface hardening + APNs token → Keychain + recursive analytics/error sanitizer (#328)
- Atomic `clearAllUserData()` on sign-out / account deletion (#327)

**Closed in the latest hardening pass (present on this branch — verify in the working tree):**
- Article-text `PromptSanitizer` wired into all three prompt builders incl. `title` (class §3.1)
- Shared `SafeMediaURL` HTTPS gate across video/audio/browser sinks + direct-video WebView
  JS-off & host-pinned navigation (class §2 mediaURL flow)
- Central data wipe on the `authenticated → unauthenticated` transition + GoogleSignIn
  session cleared on sign-out/delete (class §3.5)
- `DeeplinkManager.handle` re-validates `.category` / `.article`; share-queue read-side cap;
  `logEvent` PII sanitization; `TestEnvironment` DEBUG-gating; service-boundary premium
  re-check (classes §3.2 / §3.3 / §3.4 / §3.6)
- Reviewer-only anonymous sign-in kept out of analytics (`setUserID(nil)` for the anonymous
  provider + suppressed throttle-failure events) + a 60s sign-in throttle (#353, class §3.4 / abuse)

> The repo still carries a family of stale `security/pr-*` branches
> (`security/pr-1-atomic-cleanup`, `security/pr-2-url-hardening`, `security/audit-fixes`,
> `security/audit-remediation`). Their themes (#327/#328) appear merged; reconcile each
> branch against master before trusting any "fixed" claim.

## 4. What are we going to do about it? (Q4)

- **Discovery** — a dedicated adversarial security pass (`claude-security-review.yml`),
  separate from the style review, guided by this doc and the classes in §3.
- **Verify** — a fresh-context "disprove it" pass before any finding is treated as
  real; hunt upstream validation, auth gates, unreachable code.
- **Triage** — score every finding against `SEVERITY_RUBRIC.md`, grounded in this
  doc's reachability/preconditions (most Pulse findings cap at Medium/Low because
  nearly everything sits behind Firebase auth + a private CloudKit zone).
- **Patch** — failing test first → repro stops → regression suite passes → fresh
  re-attack; minimal diffs; hunt same-class + same-call-site variants.
- **Close the loop** — fold validated findings back into this doc and, where possible,
  a grep / CodeQL rule.

## Dependency security policy

GitHub Actions are SHA-pinned; Dependabot runs weekly. SPM dependencies are pinned via
`Package.resolved` + `-onlyUsePackageVersionsFromResolvedFile`.
`dependency-review-action` fails the build on **critical** advisories. Security-critical
SDKs: Firebase (Auth / Remote Config / Crashlytics), `swift-llama-cpp` (vendored
xcframework, SHA-pinned), GoogleSignIn / AppAuth, EntropyCore (Keychain access). A new
third-party SDK that collects data requires a matching `NSPrivacyCollectedDataTypes`
entry in `Pulse/PrivacyInfo.xcprivacy`; a new email address in source requires an entry
in `.github/pii-allowlist.txt`.

---

*Maintained alongside the privacy-conformance workflow (`privacy-conformance.yml`),
which gates merges on deterministic privacy checks. Those are intentionally separate
from this security loop — keep them so.*
