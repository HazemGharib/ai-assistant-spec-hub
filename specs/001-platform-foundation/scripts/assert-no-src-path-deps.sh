#!/usr/bin/env bash
# Fail if any package.json depends on a sibling contracts src path.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
# Workspace root is parent of ai-assistant-spec-hub when script lives under specs/...
# Prefer locating from this script: specs/001.../scripts -> up 4 = ai-assistant/
WORKSPACE="$(cd "$(dirname "$0")/../../../../" && pwd)"

echo "Auditing package.json deps under ${WORKSPACE} for file:.../src paths"

found=0
while IFS= read -r -d '' pkg; do
  if grep -E '"file:.*(/src"|"file:\.\./.*/src)' "$pkg" >/dev/null 2>&1; then
    echo "VIOLATION: $pkg"
    grep -n 'file:.*src' "$pkg" || true
    found=1
  fi
done < <(find "$WORKSPACE" -maxdepth 3 -name package.json \
  ! -path '*/node_modules/*' -print0 2>/dev/null)

if [[ "$found" -ne 0 ]]; then
  echo "Found forbidden file:.../src consumer dependencies."
  exit 1
fi

echo "OK: no file:.../src contract path dependencies."
