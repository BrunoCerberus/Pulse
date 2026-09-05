#!/bin/bash
# Use the same verified binary locally and on CI; source builds resolve SwiftSyntax.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
version=$(awk -F @ '$1 == "realm/SwiftLint" {print $2}' "$repo_root/Mintfile")
checksum=$(awk '{print $1}' "$repo_root/.github/swiftlint.sha256")
if [ -z "$version" ] || [ -z "$checksum" ]; then
  echo 'Missing SwiftLint version or checksum' >&2
  exit 1
fi
cache_dir="${XDG_CACHE_HOME:-$HOME/Library/Caches}/PulseTools/swiftlint-$version-$checksum"
if [ ! -x "$cache_dir/swiftlint" ]; then
  work_dir=$(mktemp -d)
  trap 'rm -rf "$work_dir"' EXIT
  curl --fail --silent --show-error --location \
    "https://github.com/realm/SwiftLint/releases/download/$version/portable_swiftlint.zip" \
    -o "$work_dir/portable_swiftlint.zip"
  cp "$repo_root/.github/swiftlint.sha256" "$work_dir/checksum"
  (cd "$work_dir" && shasum -a 256 -c checksum >&2)
  unzip -p "$work_dir/portable_swiftlint.zip" swiftlint > "$work_dir/swiftlint"
  chmod +x "$work_dir/swiftlint"
  test "$("$work_dir/swiftlint" version)" = "$version"
  mkdir -p "$cache_dir"
  mv "$work_dir/swiftlint" "$cache_dir/swiftlint"
fi
if [ "${1:-}" = --print-path ]; then
  printf '%s\n' "$cache_dir"
else
  "$cache_dir/swiftlint" "$@"
fi
