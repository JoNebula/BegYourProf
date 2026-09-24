#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="${1:-0.3.0}"
app="$project_dir/dist/BegYourProf.app"
archive="$project_dir/dist/BegYourProf-v${version}-macOS-universal.zip"

if [[ ! -d "$app" ]]; then
  echo "Build the app first with ./scripts/build.sh" >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
unzip -tq "$archive"
echo "Packaged $archive"
