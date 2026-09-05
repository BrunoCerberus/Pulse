# CI operation

## Required checks

`.github/required-checks.json` is the source of truth for master. The live ruleset
was reconciled to its ten contexts on 2026-09-04, after verifying that Build,
Coverage, and Privacy summary contexts had succeeded on master commit
`b818056255e564481544ffcbcf1756209d36698a`. Other rules and bypass settings were
preserved. Run Ruleset Integrity manually after future protection edits.

CodeQL and DocC always emit `Analyze` and `Build DocC` respectively. Their cheap
change-detection job skips expensive execution only for irrelevant PRs. Source,
dependencies, project settings, shared actions, tool pins, and reporting scripts
trigger analysis; push/scheduled/manual runs execute unconditionally. The final
context fails if planned execution failed or was unexpectedly skipped. Avoid
workflow-level path filters on a required context.

## Reproducible tools

`Mintfile` pins SwiftFormat 0.63.0, SwiftLint 0.64.1, and XcodeGen 2.45.4 to the
versions observed in the last CI run before this change. `make init`, `make
setup`, `make lint`, and `make format` use these pins locally. CI caches compiled
tools by OS, architecture, Xcode version, Mintfile hash, and requested tool set.
SwiftFormat and XcodeGen build once per new cache key. `scripts/swiftlint.sh` installs SwiftLint locally and on CI
from its release zip, checked against `.github/swiftlint.sha256`, to avoid a
cold SwiftSyntax build. Update that checksum alongside the SwiftLint pin.
Update pins in a reviewed PR and run lint/project generation before merging.

## Test verdicts and flakes

The suite runner prefers `xcresulttool get test-results summary` outcome counts,
excluding skipped tests. Its fallback recognizes XCTest and Swift Testing
summaries. Zero execution or missing evidence fails an otherwise-successful
command; a failed/timed-out xcodebuild retains its original status. Fallback
counts establish execution only; they are not totals for the test-count ratchet.

Keep flake detection on the successful test-step path: recorded failures after
an overall passing run are recovered failures. Parsing failures emit
`available: false`, never a fabricated clean report. The 2026-09-04 nightly's
`FeedDomainInteractorTests.offlineErrorSetsFlag()` assertions were recovered on
retry (structured result: 2,752 passed, zero failed); investigate its scheduling
separately from the zero-tests parser defect.

## Health targets

CI Health runs weekly or on manual dispatch. `.github/ci-health-targets.json`
defines advisory median/p95 targets: PR CI 30/45 minutes, CodeQL 35/45, DocC
10/15, nightly 90/120. It reports up to 100 runs per workflow over 30 days, with
successful latency samples and failed/cancelled counts separately. Workflow
latency includes runner waits; the existing per-job CI Timing report separates
runner wait from execution. Samples spanning workflow changes are historical
context, not a benchmark of the latest implementation.

The recurring-flake budget is zero test identities appearing in at least two
of the last ten nightlies. Duplicate assertions/retries in one run count once.
Missing/expired/failed-suite artifacts remain unknown; the report states how
many of the current five nightly suite reports are available. Older workflows
may have fewer suites. These targets warn and provide triage signal, never add
another required gate. Fix recurring tests; do not loosen retries or snapshot
precision to make the report clean.

## Release readiness

Release Readiness runs an unsigned **device** archive weekly, manually, and
before the Release workflow can publish. It checks the app and both embedded
extensions, device platform, executables, distinct identifiers, and matching
versions. An inert Firebase plist satisfies the build-phase resource input;
`PULSE_ARCHIVE_SMOKE=YES` suppresses dSYM upload only when signing is disabled.
The smoke archive is not distributed and does not prove signing/export works.

For a signed local IPA export, dispatch Release Readiness on master with
`signed-export=true`. All five release secrets must exist:
`GOOGLE_SERVICE_INFO_PLIST`, `APP_STORE_CONNECT_API_KEY`,
`APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and `APPLE_TEAM_ID`.
Missing secrets fail that requested job explicitly. Its export destination is
`export`, never `upload`; the temporary signing key is removed even on failure.
The normal Release workflow retains its separate App Store upload behavior.
These credentials were not configured when this change was implemented, so
signed export requires validation after provisioning them.

## Local verification

```sh
python3 -m unittest discover -s scripts/tests -v
python3 scripts/run-ios-test-suite.py --self-test
python3 scripts/report-ci-health.py --self-test
SHELLCHECK_OPTS=--severity=error actionlint
make lint
make generate
make docs
```

Pulse alone enables DocC warnings-as-errors in `project.yml`; dependencies keep
their own warning policy. DocC artifacts must resolve to `Pulse.doccarchive`,
not whichever dependency archive happens to be found first.
