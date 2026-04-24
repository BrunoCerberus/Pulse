# scripts/

Utility scripts run from CI or locally.

## `sync_remote_config.py`

Pushes runtime config values from GitHub Secrets to Firebase Remote Config so a Release build can read them at launch. Triggered by `.github/workflows/sync-remote-config.yml` (manual dispatch).

### One-time setup

1. **Create a Firebase service account**
   - [Firebase Console → Project Settings → Service accounts → Generate new private key](https://console.firebase.google.com/).
   - Or via gcloud: `gcloud iam service-accounts create pulse-remote-config-sync` then `gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:pulse-remote-config-sync@$PROJECT_ID.iam.gserviceaccount.com --role=roles/firebaseremoteconfig.admin`.
   - Grant only `Firebase Remote Config Admin` (`roles/firebaseremoteconfig.admin`). Do not grant broader roles.

2. **Add GitHub Secrets** (Settings → Secrets and variables → Actions):
   | Secret | Value |
   |---|---|
   | `FIREBASE_PROJECT_ID` | e.g. `pulse-news-42abc` |
   | `FIREBASE_SERVICE_ACCOUNT` | full JSON content of the service-account key |
   | `SUPABASE_URL` | already set |
   | `SUPABASE_ANON_KEY` | already set |
   | `NEWS_API_KEY` | optional |
   | `GNEWS_API_KEY` | optional |

3. **Run the workflow**
   - GitHub → Actions → *Sync Firebase Remote Config* → *Run workflow*.
   - Or: `gh workflow run sync-remote-config.yml`.
   - First run populates Remote Config. Re-run any time a secret is rotated.

### Behavior

- Fetches the current Remote Config with its ETag, merges in the four keys (`supabase_url`, `supabase_anon_key`, `news_api_key`, `gnews_api_key`), and publishes with `If-Match`. Other parameters (console-managed) are preserved.
- Skips a key silently if the corresponding GitHub Secret is not set (warning only).
- No-op if published values already match.

### Running locally

Not needed, but supported:

```bash
export FIREBASE_PROJECT_ID=pulse-news-42abc
export FIREBASE_SERVICE_ACCOUNT="$(cat ~/Downloads/service-account.json)"
export SUPABASE_URL=https://xxx.supabase.co
export SUPABASE_ANON_KEY=eyJ...

pip install -r scripts/requirements.txt
python scripts/sync_remote_config.py
```
