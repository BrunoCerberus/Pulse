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
| Firebase Remote Config | Primary source of `SUPABASE_URL` / `SUPABASE_ANON_KEY` / news API keys (min 10 chars) |
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
   the **`title` is interpolated raw**. None are prompt-boundary-escaped, so a poisoned
   RSS `title` can inject Gemma turn markers (`<start_of_turn>`), tokenized as real
   control tokens. The shared `PromptSanitizer` (commit `5277a32`) is **prepared on the
   unmerged `security/pr-4-prompt-injection` branch — NOT in master**, so this gap is
   live (confirmed by the discovery+verify run). *Impact is bounded* — on-device model,
   no tool access, output is a user-facing summary/CloudKit-synced tags — so the
   realistic worst case is manipulated output / tag pollution, not exfiltration or RCE.
   Triage accordingly; do not inflate.
2. **Unvalidated deeplink / push parameters.** Article IDs get `isValidArticleID`
   (≤512 chars, charset allowlist, no `..`). Free-text params are now bounded at the
   boundary; verify no new param type bypasses this and that push-payload fields are
   covered in both `DeeplinkManager` and `NotificationDeeplinkParser`.
3. **IPC tampering** via the Share Extension queue (App Group UnencryptedUserDefaults).
   Defense is a URL scheme allowlist + length cap. Anything reading the queue must
   re-validate; never trust queue contents as well-formed.
4. **Secret handling / leakage.** `#if DEBUG` env-var key fallback must never reach
   Release; analytics + Crashlytics must stay PII-sanitized (recursive sanitizer);
   Remote Config values validated ≥10 chars before use.
5. **Incomplete data wipe.** Both sign-out and delete-account must call
   `clearAllUserData()`; a new persistence store added without wiring into it leaks
   data across account boundaries.
6. **Entitlement / paywall bypass.** Premium gates must re-verify against StoreKit 2,
   not trust cached state.

### Past-fix "bug-shape" bootstrap
Mine these for siblings/variants — but **verify presence in the working tree, not
`git log --all`**. The repo carries a family of prepared-but-unmerged `security/pr-*`
branches whose fixes are NOT in master; a `--all` SHA does not mean the fix shipped.

**Merged to master (defenses you can rely on):**
- URL-surface hardening + APNs token → Keychain + recursive analytics/error sanitizer (#328)
- Atomic `clearAllUserData()` on sign-out / account deletion (#327)

**Prepared but NOT in master — gaps the discovery+verify run confirmed are live:**
- Article-text `PromptSanitizer` before LLM prompt interpolation → on `security/pr-4-prompt-injection` (class §3.1)
- Reviewer-only anonymous sign-in kept out of analytics + a sign-in throttle → on `security/pr-3-reviewer-hygiene` (class §3.4 / abuse)
- StoreKit re-verification of premium entitlements → on `security/pr-5-storekit-refresh` (class §3.6)

> Also unmerged: `security/pr-1-atomic-cleanup`, `security/pr-2-url-hardening`,
> `security/audit-fixes`, `security/audit-remediation`. Their themes (#327/#328) appear
> merged, but reconcile each branch against master before trusting any "fixed" claim.

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

*Maintained alongside the privacy-conformance workflows (`lgpd-conformance.yml`,
`gdpr-conformance.yml`), which gate merges on deterministic privacy checks. Those are
intentionally separate from this security loop — keep them so.*
