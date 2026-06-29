#!/usr/bin/env bash
# Builds a drag-to-Applications DMG from a signed, stapled Drazlo.app (Day 47).
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
  SKIP_DMG_REGEN   Set to 1 to skip background regeneration (not recommended)
  SKIP_DMG_LAYOUT  Set to 1 to skip custom Finder layout (debug only)

Requires: Python dmgbuild (pip install -r Scripts/requirements-dmg.txt)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "==> Drazlo DMG creation (dmgbuild)"
echo "    App:        ${APP_PATH}"
echo "    Version:    ${VERSION}"
echo "    Output:     ${DMG_PATH}"

if [[ ! -f "${VOLICON}" ]]; then
  echo "error: volume icon not found at ${VOLICON}" >&2
  exit 1
fi

echo "==> Install DMG Python deps (dmgbuild)"
python3 -m pip install -q -r "${SCRIPT_DIR}/requirements-dmg.txt"

eval "$(python3 "${SCRIPT_DIR}/dmg_layout.py" --shell)"

if [[ "${SKIP_DMG_REGEN:-}" != "1" ]]; then
  echo "==> Regenerate DMG backgrounds (layout + 144 DPI)"
  python3 "${SCRIPT_DIR}/generate_dmg_backgrounds.py"
fi

if [[ ! -f "${BACKGROUND}" ]]; then
  echo "error: DMG background not found at ${BACKGROUND}" >&2
  echo "Run: python3 Scripts/generate_dmg_backgrounds.py" >&2
  exit 1
fi

echo "==> Background for DMG"
echo "    Path: ${BACKGROUND}"
echo "    SHA256: $(shasum -a 256 "${BACKGROUND}" | awk '{print $1}')"

release_validate_stapled_app "${APP_PATH}"
release_eject_drazlo_volumes

echo "==> Stage app for DMG"
rm -rf "${BUILD_DIR}/dmg-staging"
mkdir -p "${STAGING_DIR}"
ditto "${APP_PATH}" "${STAGING_DIR}/Drazlo.app"
xattr -cr "${STAGING_DIR}/Drazlo.app" 2>/dev/null || true

STAGED_APP="${STAGING_DIR}/Drazlo.app"

echo "==> Layout (dmgbuild + Scripts/dmg_settings.py)"
echo "    Window:       ${DMG_WIN_W} x ${DMG_WIN_H} pt @ (${DMG_WIN_X}, ${DMG_WIN_Y})"
echo "    Drazlo.app:   (${DMG_APP_CX}, ${DMG_APP_CY})"
echo "    Applications: (${DMG_APPS_CX}, ${DMG_APPS_CY})"
echo "    Icon size:    ${DMG_ICON_SIZE}"

DMG_DEFINES=(
  -D "app=${STAGED_APP}"
  -D "repo_root=${REPO_ROOT}"
  -D "theme=${DMG_THEME}"
  -D "background=${BACKGROUND}"
  -D "volume_icon=${VOLICON}"
)

if [[ "${SKIP_DMG_LAYOUT:-}" == "1" ]]; then
  echo "==> Skipping custom Finder layout (SKIP_DMG_LAYOUT=1)"
  DMG_DEFINES+=(-D "skip_layout=1")
fi

if [[ "${DMG_ARROW:-}" == "0" ]]; then
  DMG_DEFINES+=(-D "arrow=0")
fi

rm -f "${DMG_PATH}"

python3 -m dmgbuild \
  -s "${SCRIPT_DIR}/dmg_settings.py" \
  "${DMG_DEFINES[@]}" \
  --detach-retries 8 \
  "Drazlo" \
  "${DMG_PATH}"

# dmgbuild should detach its RW mount; clear any stragglers before preview.
release_eject_drazlo_volumes

echo "==> DMG created (unsigned — run ./Scripts/notarize_dmg.sh next)"
echo "    ${DMG_PATH}"
echo ""
echo "Preview:"
echo "  ./Scripts/eject_drazlo_volumes.sh"
echo "  open \"${DMG_PATH}\""
echo ""
echo "  (Do NOT use: open build/Drazlo-*.dmg — that opens every DMG in build/)"
