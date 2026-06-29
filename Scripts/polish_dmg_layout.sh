#!/usr/bin/env bash
# DEPRECATED — replaced by Scripts/apply_dmg_ds_store.sh (Python ds_store writer).
# Kept for manual fallback only; create_dmg.sh no longer calls this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build}"
VOLUME_NAME="${VOLUME_NAME:-Drazlo}"
DMG_ASSETS="${REPO_ROOT}/Resources/DMG"
DMG_THEME="${DMG_BACKGROUND:-light}"
case "${DMG_THEME}" in
  dark) BACKGROUND="${BACKGROUND:-${DMG_ASSETS}/dmg-background-dark.png}" ;;
  light|*) BACKGROUND="${BACKGROUND:-${DMG_ASSETS}/dmg-background-light.png}" ;;
esac

DMG_PATH="${1:-}"
if [[ -z "${DMG_PATH}" ]]; then
  VERSION="$(grep -m1 'MARKETING_VERSION = ' "${REPO_ROOT}/FrameFlow/FrameFlow.xcodeproj/project.pbxproj" | sed 's/.*= //;s/;//;s/ //g')"
  DMG_PATH="${BUILD_DIR}/Drazlo-${VERSION:-1.0}.dmg"
fi

if [[ ! -f "${DMG_PATH}" ]]; then
  echo "error: DMG not found at ${DMG_PATH}" >&2
  exit 1
fi

RW_DMG="${DMG_PATH%.dmg}.polish.rw.dmg"
rm -f "${RW_DMG}"

echo "==> Polish DMG Finder layout"
echo "    DMG: ${DMG_PATH}"

hdiutil convert "${DMG_PATH}" -format UDRW -o "${RW_DMG}" -quiet

DEV="$(hdiutil attach -readwrite -noverify -nobrowse "${RW_DMG}" | grep '^/dev/' | head -1 | awk '{print $1}')"
if [[ -z "${DEV}" ]]; then
  echo "error: failed to attach ${RW_DMG}" >&2
  exit 1
fi

eval "$(python3 "${SCRIPT_DIR}/dmg_layout.py" --shell)"

sleep 2
/usr/bin/osascript "${SCRIPT_DIR}/polish_dmg_finder.applescript" \
  "${VOLUME_NAME}" \
  "${DMG_WIN_X}" "${DMG_WIN_Y}" "${DMG_WIN_W}" "${DMG_WIN_H}" \
  "${DMG_ICON_SIZE}" "${DMG_APP_CY}" "${DMG_APP_CX}" "${DMG_APPS_CX}"
sleep 2

hdiutil detach "${DEV}" -quiet

rm -f "${DMG_PATH}"
hdiutil convert "${RW_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_PATH}" -quiet
rm -f "${RW_DMG}"

echo "==> DMG layout polished"
echo "    ${DMG_PATH}"
