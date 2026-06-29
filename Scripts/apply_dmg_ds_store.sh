#!/usr/bin/env bash
# DEPRECATED: superseded by dmgbuild in Scripts/create_dmg.sh.
# Mount a DMG read-write, write .DS_Store via Python, repack to UDZO.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=release_common.sh
source "${SCRIPT_DIR}/release_common.sh"
DMG_ASSETS="${REPO_ROOT}/Resources/DMG"

DMG_PATH="${1:?usage: apply_dmg_ds_store.sh path/to/Drazlo.dmg}"
DMG_THEME="${DMG_BACKGROUND:-light}"
case "${DMG_THEME}" in
  dark) BACKGROUND_NAME="dmg-background-dark.png" ;;
  light|*) BACKGROUND_NAME="dmg-background-light.png" ;;
esac

if [[ ! -f "${DMG_PATH}" ]]; then
  echo "error: DMG not found at ${DMG_PATH}" >&2
  exit 1
fi

echo "==> Install DMG layout Python deps (ds_store, mac_alias)"
python3 -m pip install -q -r "${SCRIPT_DIR}/requirements-dmg.txt"

RW_DMG="${DMG_PATH%.dmg}.layout.rw.dmg"
rm -f "${RW_DMG}"

echo "==> Apply Python .DS_Store layout"
echo "    DMG: ${DMG_PATH}"

release_eject_drazlo_volumes
for m in /Volumes/dmg.*; do
  [[ -d "${m}" ]] && hdiutil detach "${m}" -quiet 2>/dev/null || true
done

hdiutil convert "${DMG_PATH}" -format UDRW -o "${RW_DMG}" -quiet

ATTACH_OUT="$(hdiutil attach -readwrite -noverify -nobrowse "${RW_DMG}" 2>&1)"
echo "${ATTACH_OUT}"
DEV="$(echo "${ATTACH_OUT}" | grep '^/dev/' | head -1 | awk '{print $1}')"
MOUNT="$(echo "${ATTACH_OUT}" | grep '/Volumes/' | head -1 | awk '{print $NF}')"

if [[ -z "${DEV}" || -z "${MOUNT}" ]]; then
  echo "error: failed to attach ${RW_DMG}" >&2
  echo "${ATTACH_OUT}" >&2
  exit 1
fi

VOL_NAME="$(basename "${MOUNT}")"

cleanup() {
  hdiutil detach "${DEV}" -quiet 2>/dev/null || true
}
trap cleanup EXIT

BG_MOUNTED="${MOUNT}/.background/${BACKGROUND_NAME}"
if [[ ! -f "${BG_MOUNTED}" ]]; then
  echo "error: background missing on volume: ${BG_MOUNTED}" >&2
  exit 1
fi

python3 "${SCRIPT_DIR}/write_ds_store.py" "${MOUNT}" --background "${BG_MOUNTED}"

# Remove any Finder .DS_Store create-dmg may have left; ours is authoritative.
chmod u+w "${MOUNT}/.DS_Store" 2>/dev/null || true

# Close Finder window so tab chrome is not persisted into the final image.
osascript \
  -e 'tell application "Finder"' \
  -e "tell disk \"${VOL_NAME}\"" \
  -e 'close' \
  -e 'end tell' \
  -e 'end tell' \
  2>/dev/null || true

sync
sleep 1
hdiutil detach "${DEV}" -quiet
trap - EXIT

rm -f "${DMG_PATH}"
hdiutil convert "${RW_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_PATH}" -quiet
rm -f "${RW_DMG}"

echo "==> DMG layout applied (.DS_Store written via Python)"
echo "    ${DMG_PATH}"
