#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$project_dir/Assets/default-avatar.png" ]]; then
  echo "Synthetic default avatar is missing" >&2
  exit 1
fi

while IFS= read -r -d '' asset; do
  if [[ "$asset" != "$project_dir/Assets/default-avatar.png" ]]; then
    echo "Unexpected asset in public project: $asset" >&2
    exit 1
  fi
done < <(find "$project_dir/Assets" -type f ! -name '.DS_Store' -print0)

if grep -R -n -E '/Users/|/Downloads/' \
  "$project_dir/Sources" "$project_dir/.github" 2>/dev/null; then
  echo "A local private asset reference was found" >&2
  exit 1
fi

echo "Public assets contain only the synthetic default avatar"
