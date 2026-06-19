#!/usr/bin/env bash
# Signs, notarises, and staples a Drazlo DMG (Day 47).
# Secrets via environment variables only — never commit credentials.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release_common.sh
source "${SCRIPT_DIR}/release_common.sh"

REPO_ROOT="$(release_repo_root)"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build}"
VERSION="${VERSION:-$(release_marketing_version "${REPO_ROOT}")}"
DMG_PATH="${1:-${BUILD_DIR}/Drazlo-${VERSION}.dmg}"

NOTARY_TEAM_ID="${NOTARY_TEAM_ID:-6XP66CQ82V}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Simranjit Babbar (6XP66CQ82V)}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [path/to/Drazlo-<version>.dmg]

Signs, submits, waits for, and staples the DMG.

Environment:
  NOTARY_APPLE_ID       Apple ID email (required)
  NOTARY_TEAM_ID        Team ID (default: 6XP66CQ82V)
  NOTARY_APP_PASSWORD   App-specific password or @keychain:label (required)
  SIGNING_IDENTITY      Developer ID Application identity for codesign
  VERSION               Used to locate default DMG if path omitted
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "==> Drazlo DMG notarisation"
echo "    DMG: ${DMG_PATH}"
echo "    Sign: ${SIGNING_IDENTITY}"

if [[ ! -f "${DMG_PATH}" ]]; then
  echo "error: DMG not found at ${DMG_PATH}" >&2
  echo "Run ./Scripts/create_dmg.sh first." >&2
  exit 1
fi

release_require_notary_env

echo "==> Sign DMG"
codesign --force --sign "${SIGNING_IDENTITY}" --timestamp --options runtime "${DMG_PATH}"

echo "==> Verify DMG signature"
codesign --verify --verbose=2 "${DMG_PATH}"

echo "==> Submit DMG to Apple notary service"
xcrun notarytool submit "${DMG_PATH}" \
  --apple-id "${NOTARY_APPLE_ID}" \
  --team-id "${NOTARY_TEAM_ID}" \
  --password "${NOTARY_APP_PASSWORD}" \
  --wait

echo "==> Staple DMG ticket"
xcrun stapler staple "${DMG_PATH}"

echo "==> Verify Gatekeeper assessment"
spctl -a -vv -t open --context context:primary-signature "${DMG_PATH}"
codesign --verify --verbose=2 "${DMG_PATH}"

echo "==> DMG notarisation complete"
echo "    ${DMG_PATH}"
echo ""
echo "Clean Mac test: mount DMG → drag Drazlo to Applications → first launch (no unidentified developer warning)."
