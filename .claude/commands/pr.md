# Create Pull Request

Open a PR from the current branch following the project's commit and body conventions.

## Steps

1. **Inspect the branch.** Run in parallel:
   - `git status`
   - `git log origin/master..HEAD --oneline`
   - `git diff origin/master...HEAD --stat`
   - `git diff origin/master...HEAD --name-only`

2. **Pick a title.** Conventional Commits prefix (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `ci:`, `deps:`). Under 70 chars.

3. **Notice privacy-relevant paths** (informational, not gating). If any changed file matches one of these, mention it in the body's Notes section so reviewers know to look closely:
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

   The privacy conformance workflows (`lgpd-conformance.yml`, `gdpr-conformance.yml`) check the code itself — no body markers required. If a new SDK that collects data is being added, remind the user to update `Pulse/PrivacyInfo.xcprivacy`'s `NSPrivacyCollectedDataTypes` so the **Structural Integrity** job passes. If a new email literal is being introduced, remind them to add it to `.github/pii-allowlist.txt` so the **PII Scan** job passes.

4. **Draft the PR body** following `.github/PULL_REQUEST_TEMPLATE.md`:
   - **Summary**: read the actual diffs and write 1-3 bullets covering what + why.
   - **Test plan**: bulleted checklist of verifications. Include "Build succeeds (`make build`)" for code changes and the manual steps for any UI change.
   - **Notes**: anything non-obvious — migrations, env vars added, follow-ups, screenshots placeholders for UI. If step 3 flagged privacy-relevant paths, note them here for reviewer attention.

5. **Confirm with the user** before opening: show the proposed title and a one-line summary of the body. Adjust if asked.

6. **Push the branch if needed**, then open the PR. **ALWAYS try `gh` first** — it handles auth, retries, error messages, and JSON encoding properly. Do NOT default to the curl fallback because of stale memory from an earlier session; networks recover and `gh` is the right tool when it works:
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
