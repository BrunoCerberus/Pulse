#!/usr/bin/env python3
"""Sync values from CI environment to Firebase Remote Config.

Reads keys from environment variables (populated from GitHub Secrets in CI) and
publishes them as STRING parameters to Firebase Remote Config. Uses ETag-based
optimistic concurrency so existing parameters set in the Firebase Console are
preserved.

Required environment variables:
    FIREBASE_PROJECT_ID          Firebase project ID (e.g. "pulse-news-42abc")
    FIREBASE_SERVICE_ACCOUNT     JSON key for a service account with the
                                 Firebase Remote Config Admin role.
    SUPABASE_URL                 Value to publish as "supabase_url".
    SUPABASE_ANON_KEY            Value to publish as "supabase_anon_key".
    NEWS_API_KEY                 Optional — published as "news_api_key".
    GNEWS_API_KEY                Optional — published as "gnews_api_key".

Exit codes:
    0  Success (published or already up to date).
    1  No values provided or required env vars missing.
    2  Firebase API error.
"""
from __future__ import annotations

import json
import os
import sys
from typing import Any

import google.auth.transport.requests
import requests
from google.oauth2 import service_account

REMOTE_CONFIG_ENDPOINT = (
    "https://firebaseremoteconfig.googleapis.com/v1/projects/{project_id}/remoteConfig"
)
SCOPE = "https://www.googleapis.com/auth/firebase.remoteconfig"

KEYS_TO_SYNC: dict[str, str] = {
    "supabase_url": "SUPABASE_URL",
    "supabase_anon_key": "SUPABASE_ANON_KEY",
    "news_api_key": "NEWS_API_KEY",
    "gnews_api_key": "GNEWS_API_KEY",
}


def get_access_token(service_account_json: str) -> str:
    credentials = service_account.Credentials.from_service_account_info(
        json.loads(service_account_json),
        scopes=[SCOPE],
    )
    credentials.refresh(google.auth.transport.requests.Request())
    return credentials.token


def fetch_current_config(project_id: str, token: str) -> tuple[dict[str, Any], str]:
    response = requests.get(
        REMOTE_CONFIG_ENDPOINT.format(project_id=project_id),
        headers={
            "Authorization": f"Bearer {token}",
            "Accept-Encoding": "gzip",
        },
        timeout=30,
    )
    response.raise_for_status()
    return response.json(), response.headers["ETag"]


def publish_config(
    project_id: str,
    token: str,
    config: dict[str, Any],
    etag: str,
) -> None:
    response = requests.put(
        REMOTE_CONFIG_ENDPOINT.format(project_id=project_id),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json; UTF-8",
            "If-Match": etag,
        },
        json=config,
        timeout=30,
    )
    response.raise_for_status()


def collect_values() -> dict[str, str]:
    values: dict[str, str] = {}
    for rc_key, env_var in KEYS_TO_SYNC.items():
        value = os.environ.get(env_var, "").strip()
        if value:
            values[rc_key] = value
        else:
            print(f"::warning::{env_var} not set — {rc_key} will not be updated")
    return values


def merge(parameters: dict[str, Any], new_values: dict[str, str]) -> list[str]:
    changes: list[str] = []
    for rc_key, value in new_values.items():
        current = (
            parameters.get(rc_key, {}).get("defaultValue", {}).get("value")
        )
        if current == value:
            continue
        parameters[rc_key] = {
            "defaultValue": {"value": value},
            "valueType": "STRING",
        }
        changes.append(rc_key)
    return changes


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        print(f"::error::Required env var {name} is not set", file=sys.stderr)
        sys.exit(1)
    return value


def main() -> int:
    project_id = require_env("FIREBASE_PROJECT_ID")
    service_account_json = require_env("FIREBASE_SERVICE_ACCOUNT")

    new_values = collect_values()
    if not new_values:
        print("::error::No values to sync — all env vars are empty", file=sys.stderr)
        return 1

    try:
        token = get_access_token(service_account_json)
        config, etag = fetch_current_config(project_id, token)
    except requests.HTTPError as error:
        print(f"::error::Failed to fetch Remote Config: {error}", file=sys.stderr)
        return 2

    parameters = config.setdefault("parameters", {})
    changes = merge(parameters, new_values)

    if not changes:
        print("Remote Config already up to date — no changes to publish.")
        return 0

    try:
        publish_config(project_id, token, config, etag)
    except requests.HTTPError as error:
        print(f"::error::Failed to publish Remote Config: {error}", file=sys.stderr)
        return 2

    print(f"Published {len(changes)} change(s): {', '.join(sorted(changes))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
