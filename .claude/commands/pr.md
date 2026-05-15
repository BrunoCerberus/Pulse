# Create Pull Request

Open a PR from the current branch with a body that satisfies the LGPD / GDPR / CCPA conformance gates on the first try.

## Steps

1. **Inspect the branch.** Run in parallel:
   - `git status`
   - `git log origin/master..HEAD --oneline`
   - `git diff origin/master...HEAD --stat`
   - `git diff origin/master...HEAD --name-only`

2. **Pick a title.** Conventional Commits prefix (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `ci:`, `deps:`). Under 70 chars.

3. **Detect privacy impact.** Treat the PR as privacy-relevant if any changed file matches:
   - `Pulse/Authentication/**`
   - `Pulse/Configs/Analytics/**`
   - `Pulse/Configs/Networking/**`
   - `Pulse/Configs/Storage/**`
   - `Pulse/Configs/CloudSync/**`
   - `Pulse/CloudSync/**`
   - `Pulse/Personalization/**`
   - `Pulse/Notifications/**`
   - `Pulse/Bookmarks/**`
   - `Pulse/ReadingHistory/**`
   - `Pulse/Intents/**`
   - `Pulse/Configs/Models/**`
   - `Pulse/PrivacyInfo.xcprivacy`
   - `Pulse/Info.plist`
   - `PulseShareExtension/**`

4. **Draft the PR body** following `.github/PULL_REQUEST_TEMPLATE.md`:
   - **Summary**: read the actual diffs (not just the file list) and write 1-3 bullets covering what + why.
   - **Test plan**: bulleted checklist of verifications. Include "Build succeeds (`make build`)" for code changes, and the manual steps for any UI change.
   - **Privacy**: if step 3 found NO privacy-relevant paths, leave the three lines as `LGPD: N/A`, `GDPR: N/A`, `CCPA: N/A` with a one-line rationale (e.g. `(UI-only changes; no new data collection)`). If step 3 found ANY privacy-relevant paths, replace `N/A` with a real rationale per regulation: purpose, lawful basis, retention, deletion path.

5. **Confirm with the user** before opening: show the proposed title, the privacy block, and a 1-line summary of the body. Adjust if asked.

6. **Push the branch if needed**, then open the PR. **ALWAYS try `gh` first** — it handles auth, retries, error messages, and JSON encoding properly. Do NOT default to the curl fallback because of "stale memory" from an earlier session; networks recover and `gh` is the right tool when it works:
   ```bash
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   <body>
   EOF
   )"
   ```
   **Fallback ONLY if `gh` actually errors right now** with `Post "https://api.github.com/...": dial tcp ...: i/o timeout` (observed against the Brazil edge `4.228.31.149`). Re-test `gh` with `gh pr view <some-pr> --json url` before assuming it's broken — don't carry forward a failure from an earlier turn. When a fallback IS needed, force the connection through the US edge:
   ```bash
   TOKEN=$(gh auth token)
   export BODY='<body>'              # MUST be exported BEFORE python reads it.
                                      # Bare `BODY=$(...)` does NOT put BODY in the
                                      # env for child processes — this nuked PR
                                      # #319's body once. Always export at assign.
   PAYLOAD=$(python3 -c "import json,os;print(json.dumps({'title':'<title>','head':'<branch>','base':'master','body':os.environ['BODY']}))")
   curl -sS --max-time 30 --resolve api.github.com:443:140.82.121.6 \
     -X POST https://api.github.com/repos/<owner>/<repo>/pulls \
     -H "Authorization: Bearer $TOKEN" \
     -H "Accept: application/vnd.github+json" \
     -d "$PAYLOAD"
   ```

7. **Return the PR URL.**

## Required marker grammar

Each privacy line must start the line (optionally prefixed by `- `) and be one of:

```
LGPD: N/A (...)            GDPR: N/A (...)            CCPA: N/A (...)
LGPD review: <rationale>   GDPR review: <rationale>   CCPA review: <rationale>
[x] LGPD: <rationale>      [x] GDPR: <rationale>      [x] CCPA: <rationale>
```

`lgpd-conformance.yml` requires its own LGPD marker. `gdpr-conformance.yml` covers both regimes and accepts either a GDPR or a CCPA marker, but for clarity always include all three.

Loose phrases like "no PII" buried in prose are rejected — markers are line-anchored.
