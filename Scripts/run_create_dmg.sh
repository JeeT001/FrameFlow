#!/usr/bin/env bash
# Runs Homebrew create-dmg with repo-local Finder template (sidebar hidden).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPPORT="${SCRIPT_DIR}/dmg-support"
REAL="$(command -v create-dmg)"

if [[ ! -x "${REAL}" ]]; then
  echo "error: create-dmg not found (brew install create-dmg)" >&2
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

sed "s|CDMG_SUPPORT_DIR=\"\$prefix_dir/share/create-dmg/support\"|CDMG_SUPPORT_DIR=\"${SUPPORT}\"|" "${REAL}" > "${TMP}"
chmod +x "${TMP}"
exec "${TMP}" "$@"
