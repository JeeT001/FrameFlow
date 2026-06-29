#!/usr/bin/env bash
# Builds a drag-to-Applications DMG from a signed, stapled Drazlo.app (Day 47).
# Discord-style drag-to-Applications DMG (gradient background, no baked arrow).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release_common.sh
source "${SCRIPT_DIR}/release_common.sh"

REPO_ROOT="$(release_repo_root)"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build}"
APP_PATH="${1:-${BUILD_DIR}/export/Drazlo.app}"
STAGING_DIR="${BUILD_DIR}/dmg-staging/dist"
DMG_ASSETS="${REPO_ROOT}/Resources/DMG"
VOLICON="${DMG_ASSETS}/DrazloVolume.icns"

VERSION="${VERSION:-$(release_marketing_version "${REPO_ROOT}")}"
DMG_NAME="Drazlo-${VERSION}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"

DMG_THEME="${DMG_BACKGROUND:-light}"
case "${DMG_THEME}" in
  dark) BACKGROUND="${DMG_ASSETS}/dmg-background-dark.png" ;;
  light|*) BACKGROUND="${DMG_ASSETS}/dmg-background-light.png" ;;
esac

usage() {
  cat <<EOF
Usage: $(basename "$0") [path/to/Drazlo.app]

Creates ${BUILD_DIR}/Drazlo-<version>.dmg from a signed, stapled app.

Environment:
  VERSION          Override marketing version (default from Xcode project)
  DMG_BACKGROUND   light (default) or dark background art
  BUILD_DIR        Output directory (default: build/)

Requires: create-dmg (brew install create-dmg)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "==> Drazlo DMG creation (Discord-style installer layout)"
echo "    App:        ${APP_PATH}"
echo "    Version:    ${VERSION}"
echo "    Output:     ${DMG_PATH}"
echo "    Background: ${BACKGROUND}"

if [[ ! -f "${BACKGROUND}" ]]; then
  echo "error: DMG background not found at ${BACKGROUND}" >&2
  echo "Run: python3 Scripts/generate_dmg_backgrounds.py" >&2
  exit 1
fi

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "error: create-dmg is not installed." >&2
  echo "Install with: brew install create-dmg" >&2
  exit 1
fi

if [[ ! -f "${VOLICON}" ]]; then
  echo "error: volume icon not found at ${VOLICON}" >&2
  exit 1
fi

release_validate_stapled_app "${APP_PATH}"
release_eject_drazlo_volumes

echo "==> Stage app for DMG"
rm -rf "${BUILD_DIR}/dmg-staging"
mkdir -p "${STAGING_DIR}"
ditto "${APP_PATH}" "${STAGING_DIR}/Drazlo.app"
xattr -cr "${STAGING_DIR}/Drazlo.app" 2>/dev/null || true

# Layout constants — keep in sync with Scripts/generate_dmg_backgrounds.py
DMG_WIN_W=660
DMG_WIN_H=400
DMG_ICON_SIZE=100
DMG_ICON_Y=150
DMG_APP_X=194
DMG_APPS_X=366

echo "==> create-dmg"
rm -f "${DMG_PATH}"
"${SCRIPT_DIR}/run_create_dmg.sh" \
  --volname "Drazlo" \
  --volicon "${VOLICON}" \
  --background "${BACKGROUND}" \
  --window-pos 400 120 \
  --window-size "${DMG_WIN_W}" "${DMG_WIN_H}" \
  --text-size 12 \
  --icon-size "${DMG_ICON_SIZE}" \
  --icon "Drazlo.app" "${DMG_APP_X}" "${DMG_ICON_Y}" \
  --hide-extension "Drazlo.app" \
  --app-drop-link "${DMG_APPS_X}" "${DMG_ICON_Y}" \
  --bless \
  --no-internet-enable \
  "${DMG_PATH}" \
  "${STAGING_DIR}"

echo "==> Polish Finder layout (.DS_Store window size, icon positions, background)"
if [[ "${SKIP_DMG_POLISH:-}" == "1" ]]; then
  echo "    Skipped (SKIP_DMG_POLISH=1 — headless CI uses create-dmg layout only)"
else
  BACKGROUND="${BACKGROUND}" "${SCRIPT_DIR}/polish_dmg_layout.sh" "${DMG_PATH}"
fi

echo "==> DMG created (unsigned — run ./Scripts/notarize_dmg.sh next)"
echo "    ${DMG_PATH}"
echo ""
echo "Preview:"
echo "  for v in /Volumes/Drazlo*; do [[ -d \"\$v\" ]] && hdiutil detach \"\$v\" -quiet; done"
echo "  open \"${DMG_PATH}\""
