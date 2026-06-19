#!/usr/bin/env bash
# End-to-end DMG release helper (Day 47).
# Does not run notarisation without credentials — prompts when NOTARY_* are unset.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release_common.sh
source "${SCRIPT_DIR}/release_common.sh"

REPO_ROOT="$(release_repo_root)"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build}"
APP_PATH="${BUILD_DIR}/export/Drazlo.app"
VERSION="${VERSION:-$(release_marketing_version "${REPO_ROOT}")}"
DMG_PATH="${BUILD_DIR}/Drazlo-${VERSION}.dmg"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--skip-app-check]

Orchestrates DMG packaging for Drazlo:

  1. Validates stapled app at build/export/Drazlo.app (unless --skip-app-check)
  2. ./Scripts/create_dmg.sh
  3. ./Scripts/notarize_dmg.sh (only if NOTARY_APPLE_ID and NOTARY_APP_PASSWORD are set)

Prerequisites (user runs separately if app is missing or not stapled):
  ./Scripts/archive_release.sh
  source Scripts/notary.env   # or export NOTARY_* variables
  ./Scripts/notarize_app.sh

Environment: same as create_dmg.sh / notarize_dmg.sh / notarize_app.sh
EOF
}

SKIP_APP_CHECK=false
if [[ "${1:-}" == "--skip-app-check" ]]; then
  SKIP_APP_CHECK=true
elif [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
elif [[ -n "${1:-}" ]]; then
  echo "error: unknown argument: $1" >&2
  usage
  exit 1
fi

echo "==> Drazlo DMG release (Day 47)"

if [[ "${SKIP_APP_CHECK}" == false ]]; then
  if [[ ! -d "${APP_PATH}" ]]; then
    echo "error: ${APP_PATH} not found." >&2
    echo ""
    echo "Run Day 46 steps first:"
    echo "  ./Scripts/archive_release.sh"
    echo "  ./Scripts/notarize_app.sh"
    exit 1
  fi
  release_validate_stapled_app "${APP_PATH}"
else
  echo "warning: skipping stapled app validation (--skip-app-check)" >&2
fi

"${SCRIPT_DIR}/create_dmg.sh" "${APP_PATH}"

if [[ -z "${NOTARY_APPLE_ID:-}" || -z "${NOTARY_APP_PASSWORD:-}" ]]; then
  echo ""
  echo "==> Skipping DMG notarisation (NOTARY_APPLE_ID / NOTARY_APP_PASSWORD not set)"
  echo "    Export credentials, then run:"
  echo "    ./Scripts/notarize_dmg.sh \"${DMG_PATH}\""
  exit 0
fi

"${SCRIPT_DIR}/notarize_dmg.sh" "${DMG_PATH}"
