#!/usr/bin/env bash
# Zips, submits, waits for, and staples notarisation for a signed Drazlo.app (Day 46).
# Secrets via environment variables only — never commit credentials.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build}"

APP_PATH="${1:-${BUILD_DIR}/export/Drazlo.app}"
ZIP_PATH="${BUILD_DIR}/Drazlo-notarize.zip"

NOTARY_APPLE_ID="${NOTARY_APPLE_ID:-}"
NOTARY_TEAM_ID="${NOTARY_TEAM_ID:-6XP66CQ82V}"
NOTARY_APP_PASSWORD="${NOTARY_APP_PASSWORD:-}"

echo "==> Drazlo notarisation"
echo "    App: ${APP_PATH}"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: app bundle not found at ${APP_PATH}" >&2
  echo "Run ./Scripts/archive_release.sh first." >&2
  exit 1
fi

if [[ -z "${NOTARY_APPLE_ID}" ]]; then
  echo "error: NOTARY_APPLE_ID is required (Apple ID email)." >&2
  exit 1
fi

if [[ -z "${NOTARY_APP_PASSWORD}" ]]; then
  echo "error: NOTARY_APP_PASSWORD is required (app-specific password or @keychain:label)." >&2
  exit 1
fi

echo "==> Verify code signature"
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

echo "==> Create notarisation zip"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

echo "==> Submit to Apple notary service"
xcrun notarytool submit "${ZIP_PATH}" \
  --apple-id "${NOTARY_APPLE_ID}" \
  --team-id "${NOTARY_TEAM_ID}" \
  --password "${NOTARY_APP_PASSWORD}" \
  --wait

echo "==> Staple ticket"
xcrun stapler staple "${APP_PATH}"

echo "==> Verify Gatekeeper assessment"
spctl -a -vv "${APP_PATH}"

echo "==> Notarisation complete"
echo "    App: ${APP_PATH}"
echo "    Test on a Mac not logged into the developer account: open \"${APP_PATH}\""
