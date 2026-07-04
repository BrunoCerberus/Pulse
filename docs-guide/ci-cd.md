# CI/CD

[← Back to README](../README.md) · [Features](features.md) · [Architecture](architecture.md) · [Development](development.md) · [Testing](testing.md)

## Workflows

- `ci.yml` — code quality (incl. localization key parity) + a `security-audit` job (mobsfscan iOS SAST, HTTPS-only network-call check, privacy-manifest validation, ATS-exception + entitlements + file-permission audit, dependency review) + Debug build + Release build + separate `unit-tests` / `snapshot-tests` / `ui-tests` jobs on iPhone (`ui-tests` also runs an iPad leg, regular size class) + patch & overall coverage, on PR **and push to master**. The three test jobs are split (not one matrix job) so `patch-coverage`/`coverage-summary` can depend on just `unit-tests` + `snapshot-tests` and don't stall behind the much slower `ui-tests` legs. Build/release/test jobs share the `.github/actions/setup-ios` composite action (Xcode select + SPM cache + xcodegen + `make generate`); the security-audit body lives in `reusable-security-audit.yml` (pinned tools here; the nightly calls it with latest tools + gitleaks).
- `actionlint.yml` — lints workflow YAML (schema, `${{ }}` exprs, `uses:` refs) + shellcheck over embedded `run:` blocks; a **required** status check that runs unconditionally (no `paths:` filter) on every push to master / PR so it can't deadlock as a pending required check
- `release.yml` — version bump → Release archive → GitHub Release; App Store Connect upload dormant until secrets exist (see [Releasing](#releasing))
- `docs.yml` — DocC build (broken-reference check) on PR + master
- `pr-title.yml` — Conventional Commit PR-title lint
- `claude-code-review.yml` — Claude review on PR open/sync; clears its own prior stale comments/verdicts before posting a fresh review on each push
- `claude-security-review.yml` — threat-model-guided security pass: two-stage `pr-discovery` → separate-context `pr-verify` on PRs + a weekly Monday 06:00 UTC full-repo sweep (`workflow_dispatch`-able); distinct from `claude-code-review.yml`. Each stage clears its own prior stale comments before reposting, tagged with an HTML marker so the two workflows don't delete each other's output. The jobs are required checks (they must run), but findings are advisory — verify never sets a review verdict
- `codeql.yml` — CodeQL security analysis on PR + weekly
- `privacy-conformance.yml` — LGPD (Brazil, Lei 13.709/2018) + GDPR (EU 2016/679) + CCPA / CPRA (California §1798.100 et seq.) PR gates
- `scheduled-tests.yml` — daily at 2 AM UTC full test run; notifies on failure (the Claude auto-fix step was removed — it accumulated changes nobody reviewed)

> The CI test matrix runs unit (`PulseTests`) and snapshot (`PulseSnapshotTests`) suites on iPhone Air only; the UI suite (`PulseUITests`) runs on both iPhone Air **and** iPad (the iPad entry exercises the regular size class).

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
