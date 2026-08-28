# CI/CD

[← Back to README](../README.md) · [Features](features.md) · [Architecture](architecture.md) · [Development](development.md) · [Testing](testing.md)

## Workflows

- `ci.yml` — code quality (incl. localization key parity + value completeness + key usage, orphaned-snapshot-reference, and accessibility-audit-coverage checks) + a `security-audit` job (mobsfscan iOS SAST, HTTPS-only network-call check, privacy-manifest validation, ATS-exception + entitlements + file-permission audit, dependency review) + Debug build + Release build (with an app-size ratchet) + separate `unit-tests` / `snapshot-tests` / `ui-tests` jobs on iPhone (`ui-tests` also runs an iPad leg, regular size class; `unit-tests` runs `PulseTests` **and** `PulseWidgetExtensionTests` in one invocation) + patch & overall coverage + test-count ratchet (all gating — see [Quality gates](#quality-gates)) + an advisory `spm-dependency-review` job (sticky comment on lockfile version moves), on PR **and push to master**. The three test jobs are split (not one matrix job) so `patch-coverage`/`coverage-summary` can depend on just `unit-tests` + `snapshot-tests` and don't stall behind the much slower `ui-tests` legs. Build/release/test jobs share the `.github/actions/setup-ios` composite action (Xcode select + SPM cache + xcodegen + `make generate`); the security-audit body lives in `reusable-security-audit.yml` (pinned tools here; the nightly calls it with latest tools + gitleaks).
- `actionlint.yml` — lints workflow YAML (schema, `${{ }}` exprs, `uses:` refs) + shellcheck over embedded `run:` blocks; a **required** status check that runs unconditionally (no `paths:` filter) on every push to master / PR so it can't deadlock as a pending required check
- `release.yml` — version bump → Release archive → GitHub Release; App Store Connect upload dormant until secrets exist (see [Releasing](#releasing))
- `docs.yml` — DocC build (broken-reference check) on PR + master
- `pr-title.yml` — Conventional Commit PR-title lint
- `claude-code-review.yml` — Claude review on PR open/sync; clears its own prior stale comments/verdicts before posting a fresh review on each push
- `claude-security-review.yml` — threat-model-guided security pass: two-stage `pr-discovery` → separate-context `pr-verify` on PRs + a weekly Monday 06:00 UTC full-repo sweep (`workflow_dispatch`-able); distinct from `claude-code-review.yml`. Each stage clears its own prior stale comments before reposting, tagged with an HTML marker so the two workflows don't delete each other's output. The jobs are required checks (they must run), but findings are advisory — verify never sets a review verdict
- `codeql.yml` — CodeQL security analysis on PR + weekly
- `privacy-conformance.yml` — LGPD (Brazil, Lei 13.709/2018) + GDPR (EU 2016/679) + CCPA / CPRA (California §1798.100 et seq.) PR gates
- `scheduled-tests.yml` — daily at 2 AM UTC full test run (unit, UI, snapshot, **and widget** legs) + a `dead-code` job (SwiftLint analyzer rules over a full compiler log) + a `duration-ratchet` job (per-suite wall clock, incl. the two build legs, ratcheted 15% against the last successful run's artifacts); notifies on failure (the Claude auto-fix step was removed — it accumulated changes nobody reviewed). Dead-code, slow-test, and duration-ratchet findings are advisory: the ratchet can red the run but `notify-failure` keys off `test-results` only, so it opens no tracking issue; the nightly renders flake and slow-test reports into its job summary
- `ruleset-integrity.yml` — weekly check that the live master ruleset still requires every context in `.github/required-checks.json`. A missing required check (a gate that silently stopped blocking) fails the check and opens a tracking issue; an extra context only warns until ratified into the list

> The CI test matrix runs unit (`PulseTests`) and snapshot (`PulseSnapshotTests`) suites on iPhone Air only; the UI suite (`PulseUITests`) runs on both iPhone Air **and** iPad (the iPad entry exercises the regular size class).

## Quality gates

Beyond lint and tests, seven gates run across the pipeline: five blocking PR gates, plus two advisory nightly reports (dead code, CI duration) and the Code Quality consistency checks and the advisory SPM dependency review — see below. AGENTS.md rule 42 carries the design rationale.

| Gate | Job | Script | Blocks |
|---|---|---|---|
| Zero compiler warnings | Build Project, Release Build | `scripts/check-build-warnings.py` | yes |
| Main-thread Combine sinks | Code Quality | `scripts/check-mainactor-sinks.py` | yes |
| Coverage ratchet | Coverage Summary | `scripts/check-coverage-ratchet.py` | yes |
| App-size ratchet | Release Build | `scripts/check-app-size-ratchet.py` | yes |
| Test-count ratchet | Coverage Summary | `scripts/check-test-count-ratchet.py` | yes |
| Dead code | Nightly Dead Code | `scripts/render-dead-code-report.py` | no |
| CI duration ratchet | Nightly CI Duration Ratchet | `scripts/check-duration-ratchet.py` | no |

- **Zero compiler warnings** — parses the teed build log and fails on any `warning:` from a first-party path. Scoped by path rather than `SWIFT_TREAT_WARNINGS_AS_ERRORS`, which would also apply to SwiftPM dependencies and break CI on an upstream bump. Verify locally against a `build-for-testing` log — plain `xcodebuild build` skips the test targets, which is exactly where warnings hide.
- **Main-thread Combine sinks** — enforces the AGENTS.md rule 19 crash rule: a `.sink` in a `@MainActor` interactor needs a main-queue hop, and only the *last* scheduler-changing operator in the chain counts. `--self-test` (11 fixtures) runs ahead of the tree scan, because a clean tree only ever proves the absence of false *positives*.
- **Coverage ratchet** — fails a PR whose overall coverage falls more than 1pt below the last successful master run, closing the erosion gap the changed-lines-only Patch Coverage gate can't see. The baseline is the previous master run's `coverage-value` artifact, so there's no committed baseline file. A missing baseline passes rather than fails. `Coverage Summary` is a required status check.
- **App-size ratchet** — measures the Release `Pulse.app` (`du`, extensions included) and fails a PR that grows it more than 10% past the last successful master run (`app-size-value` artifact, same self-seeding baseline pattern as coverage). The App Store size limit is a cliff; the ratchet catches slow bloat — a bundled model, asset, or framework — per PR.
- **Test-count ratchet** — reads the declared test count (PulseTests + PulseWidgetExtensionTests) from the unit result bundle and fails a PR whose count drops more than 2% below master (`test-count-value` artifact). Deleting tests incrementally is the only way the number moves, and each individual deletion looks innocent in review — the ratchet makes the suite a floor.
- **Dead code** — nightly only, because SwiftLint's analyzer rules need a full compiler log and run longer than the whole PR lint job. Advisory because `unused_declaration` cannot see references from protocol requirements the framework fulfils, `#Preview` blocks, or other targets, so real findings arrive mixed with false positives — same posture as the flake report.
- **CI duration ratchet** — the nightly is the only unconditional full-suite run, so its per-suite wall clock (each test leg plus both build legs) is the cleanest CI-cost signal: a runner-image slowdown, suite growth, or a new slow test shows up here before it collides with the 180/210-minute ceilings. Same baseline-by-artifact pattern as the other ratchets (baseline = the last successful run's uploads; missing baseline passes, never a fabricated zero) with a looser 15% per-suite tolerance — shared macOS runners vary far more run-to-run than app size. The baseline can freeze: a legitimate permanent slowdown reds every nightly (the success-only walk-back keeps re-reading the pre-slowdown baseline), so re-anchor with a `rebaseline: true` workflow dispatch on master while the tests pass — it skips the comparison, stays green, and its uploads become the new baseline. Advisory: `notify-failure` keys off `test-results` only, so a regression reds the run without opening a tracking issue.

The Code Quality job also runs five deterministic consistency checks that fail the PR: localization *key* parity (a key in `en` missing from any other language — the raw key would ship to users), localization *value* completeness (empty translations and format-placeholder mismatches are errors; values identical to English only warn — brand names are legitimately the same), localization *key* usage (a key referenced in code via `AppLocalization…localized("…")` / `String(localized: "…")` but missing from the owning target's `en` catalog — parity and completeness are blind to a key missing from **every** language; widgets resolve against their own bundle, doc-comment examples are not checked), orphaned snapshot references (a `__Snapshots__` file whose test method no longer exists — SnapshotTesting never deletes references on rename/remove), and accessibility-audit coverage (every `AppTab` and `Page` case needs an audit in `AccessibilityAuditTests`; genuinely transient screens opt out with an `a11y-audit:exclude` marker on their doc comment). An advisory `SPM Dependency Review` job posts a sticky comment on PRs that move lockfile versions — never fails, since patch/minor bumps auto-merge and the suites re-run against them via the path filter. The nightly additionally renders a **slow-test report** (tests over 30s for unit/snapshot, 120s for UI, top 10 per suite) into its job summary — advisory, like the flake and dead-code reports.

Two Liquid Glass bans (AGENTS.md rule 21) are `custom_rules` in `.swiftlint.yml` and fail the Code Quality job.

## Privacy conformance

One workflow (`privacy-conformance.yml`) covers all three regimes — LGPD, GDPR, and CCPA/CPRA overlap ~80%, so the checks are shared with per-regime steps where they differ. It runs four parallel jobs on push to master + PRs + weekly:

- **PII Scan** — CPF/CNPJ/SSN regex bans, email allowlist in `.github/pii-allowlist.txt`, gitleaks with custom rules in `.github/lgpd-gdpr-rules.toml`
- **Docs Presence** — `README.md` / `AGENTS.md` / `CLAUDE.md` / `Pulse/PrivacyInfo.xcprivacy` exist and are non-empty; README mentions privacy
- **Operational Controls** — sign-out / account-delete wipe is wired, env-var key fallbacks are `#if DEBUG`-gated, networking uses https, CloudKit container is `.private(...)`, engagement-events container is non-CloudKit
- **Structural Integrity** — `Pulse/PrivacyInfo.xcprivacy` valid plist, every `NSPrivacyCollectedDataType` has a purpose, `*UsageDescription` strings non-empty

No PR-body marker required — the deterministic code checks do the gating. Adding a new SDK that collects data needs a corresponding `NSPrivacyCollectedDataTypes` entry; new email addresses in source need an entry in `.github/pii-allowlist.txt`.

## Schemes

`PulseDev`, `PulseProd`, `PulseTests`, `PulseUITests`, `PulseSnapshotTests`, `PulseWidgetExtensionTests`.

## Releasing

Run the **Release** workflow (Actions → Release → Run workflow) and pick `patch` / `minor` / `major`. It bumps `MARKETING_VERSION` in `project.yml`, commits + tags `vX.Y.Z`, and publishes a GitHub Release with auto-generated notes. Pushing a `vX.Y.Z` tag manually does the same for an existing commit. (The Release *compile* is validated on every push to master by CI's Release Build job.)

Building the signed device archive and uploading to App Store Connect / TestFlight is **pre-wired but dormant** — it activates automatically once all of these repository secrets exist (Settings → Secrets and variables → Actions), with no workflow edits:

| Secret | Value |
|---|---|
| `GOOGLE_SERVICE_INFO_PLIST` | base64 of `Pulse/GoogleService-Info.plist` (`base64 -i Pulse/GoogleService-Info.plist`) — the device Release build runs the Crashlytics dSYM phase, which requires it |
| `APP_STORE_CONNECT_API_KEY` | full contents of the `AuthKey_*.p8` file |
| `APP_STORE_CONNECT_KEY_ID` | the key's Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | issuer ID (App Store Connect → Users and Access → Integrations) |
| `APPLE_TEAM_ID` | 10-character Apple Developer Team ID |

Signing uses Xcode cloud signing (`-allowProvisioningUpdates`) — no certificates or provisioning profiles to manage.
