# CI/CD

[← Back to README](../README.md) · [Features](features.md) · [Architecture](architecture.md) · [Development](development.md) · [Testing](testing.md)

## Workflows

- `ci.yml` — code quality (incl. localization key parity) + a `security-audit` job (mobsfscan iOS SAST, HTTPS-only network-call check, privacy-manifest validation, ATS-exception + entitlements + file-permission audit, dependency review) + Debug build + Release build + separate `unit-tests` / `snapshot-tests` / `ui-tests` jobs on iPhone (`ui-tests` also runs an iPad leg, regular size class) + patch & overall coverage (both gating — see [Quality gates](#quality-gates)), on PR **and push to master**. The three test jobs are split (not one matrix job) so `patch-coverage`/`coverage-summary` can depend on just `unit-tests` + `snapshot-tests` and don't stall behind the much slower `ui-tests` legs. Build/release/test jobs share the `.github/actions/setup-ios` composite action (Xcode select + SPM cache + xcodegen + `make generate`); the security-audit body lives in `reusable-security-audit.yml` (pinned tools here; the nightly calls it with latest tools + gitleaks).
- `actionlint.yml` — lints workflow YAML (schema, `${{ }}` exprs, `uses:` refs) + shellcheck over embedded `run:` blocks; a **required** status check that runs unconditionally (no `paths:` filter) on every push to master / PR so it can't deadlock as a pending required check
- `release.yml` — version bump → Release archive → GitHub Release; App Store Connect upload dormant until secrets exist (see [Releasing](#releasing))
- `docs.yml` — DocC build (broken-reference check) on PR + master
- `pr-title.yml` — Conventional Commit PR-title lint
- `claude-code-review.yml` — Claude review on PR open/sync; clears its own prior stale comments/verdicts before posting a fresh review on each push
- `claude-security-review.yml` — threat-model-guided security pass: two-stage `pr-discovery` → separate-context `pr-verify` on PRs + a weekly Monday 06:00 UTC full-repo sweep (`workflow_dispatch`-able); distinct from `claude-code-review.yml`. Each stage clears its own prior stale comments before reposting, tagged with an HTML marker so the two workflows don't delete each other's output. The jobs are required checks (they must run), but findings are advisory — verify never sets a review verdict
- `codeql.yml` — CodeQL security analysis on PR + weekly
- `privacy-conformance.yml` — LGPD (Brazil, Lei 13.709/2018) + GDPR (EU 2016/679) + CCPA / CPRA (California §1798.100 et seq.) PR gates
- `scheduled-tests.yml` — daily at 2 AM UTC full test run + a `dead-code` job (SwiftLint analyzer rules over a full compiler log); notifies on failure (the Claude auto-fix step was removed — it accumulated changes nobody reviewed). Dead-code findings are advisory and never fail the run

> The CI test matrix runs unit (`PulseTests`) and snapshot (`PulseSnapshotTests`) suites on iPhone Air only; the UI suite (`PulseUITests`) runs on both iPhone Air **and** iPad (the iPad entry exercises the regular size class).

## Quality gates

Beyond lint and tests, four gates run on every PR. Three block; the fourth is deliberately advisory. AGENTS.md rule 42 carries the design rationale.

| Gate | Job | Script | Blocks |
|---|---|---|---|
| Zero compiler warnings | Build Project, Release Build | `scripts/check-build-warnings.py` | yes |
| Main-thread Combine sinks | Code Quality | `scripts/check-mainactor-sinks.py` | yes |
| Coverage ratchet | Coverage Summary | `scripts/check-coverage-ratchet.py` | yes |
| Dead code | Nightly Dead Code | `scripts/render-dead-code-report.py` | no |

- **Zero compiler warnings** — parses the teed build log and fails on any `warning:` from a first-party path. Scoped by path rather than `SWIFT_TREAT_WARNINGS_AS_ERRORS`, which would also apply to SwiftPM dependencies and break CI on an upstream bump. Verify locally against a `build-for-testing` log — plain `xcodebuild build` skips the test targets, which is exactly where warnings hide.
- **Main-thread Combine sinks** — enforces the AGENTS.md rule 19 crash rule: a `.sink` in a `@MainActor` interactor needs a main-queue hop, and only the *last* scheduler-changing operator in the chain counts. `--self-test` (11 fixtures) runs ahead of the tree scan, because a clean tree only ever proves the absence of false *positives*.
- **Coverage ratchet** — fails a PR whose overall coverage falls more than 1pt below the last successful master run, closing the erosion gap the changed-lines-only Patch Coverage gate can't see. The baseline is the previous master run's `coverage-value` artifact, so there's no committed baseline file. A missing baseline passes rather than fails. `Coverage Summary` is a required status check.
- **Dead code** — nightly only, because SwiftLint's analyzer rules need a full compiler log and run longer than the whole PR lint job. Advisory because `unused_declaration` cannot see references from protocol requirements the framework fulfils, `#Preview` blocks, or other targets, so real findings arrive mixed with false positives — same posture as the flake report.

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
