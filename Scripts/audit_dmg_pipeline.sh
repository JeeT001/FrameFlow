#!/usr/bin/env bash
# Empirical DMG pipeline audit — hashes, mounted .background/, exact create-dmg argv.
# Does NOT change layout coordinates. Uses a minimal stub Drazlo.app (no codesign required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build}"
STAGING_DIR="${BUILD_DIR}/dmg-audit-staging"
DMG_ASSETS="${REPO_ROOT}/Resources/DMG"
BACKGROUND="${DMG_ASSETS}/dmg-background-light.png"
VOLICON="${DMG_ASSETS}/DrazloVolume.icns"
DMG_PATH="${BUILD_DIR}/Drazlo-audit.dmg"
VOLUME_NAME="Drazlo"

sha() { shasum -a 256 "$1" | awk '{print $1}'; }

echo "========== 1. FILES RESPONSIBLE FOR DMG =========="
find "${REPO_ROOT}" -type f \( \
  -path '*/Scripts/*dmg*' -o \
  -path '*/Scripts/run_create_dmg.sh' -o \
  -path '*/Resources/DMG/*' -o \
  -path '*/.github/workflows/release.yml' \
\) ! -path '*/__pycache__/*' ! -name '*.pyc' 2>/dev/null | sort

echo ""
echo "========== 2. GENERATE BACKGROUND + DEBUG PNG =========="
python3 "${SCRIPT_DIR}/generate_dmg_backgrounds.py"
python3 "${SCRIPT_DIR}/write_dmg_debug_png.py"

GEN_ABS="$(cd "$(dirname "${BACKGROUND}")" && pwd)/$(basename "${BACKGROUND}")"
GEN_SHA="$(sha "${GEN_ABS}")"
DEBUG_ABS="$(cd "${DMG_ASSETS}" && pwd)/dmg-background-debug.png"

echo "GENERATED_PNG_PATH=${GEN_ABS}"
echo "GENERATED_PNG_SHA256=${GEN_SHA}"
echo "DEBUG_PNG_PATH=${DEBUG_ABS}"
echo "DEBUG_PNG_SHA256=$(sha "${DEBUG_ABS}")"
sips -g pixelWidth -g pixelHeight -g dpiWidth -g dpiHeight "${GEN_ABS}" 2>/dev/null | grep -E 'pixel|dpi'

echo ""
echo "========== 3. STUB APP STAGING =========="
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}/Drazlo.app/Contents/MacOS"
cat > "${STAGING_DIR}/Drazlo.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Drazlo</string>
  <key>CFBundleIdentifier</key><string>com.Simranjit.FrameFlow.audit</string>
  <key>CFBundleName</key><string>Drazlo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.0.0-audit</string>
</dict></plist>
PLIST
echo '#!/bin/sh' > "${STAGING_DIR}/Drazlo.app/Contents/MacOS/Drazlo"
chmod +x "${STAGING_DIR}/Drazlo.app/Contents/MacOS/Drazlo"

eval "$(python3 "${SCRIPT_DIR}/dmg_layout.py" --shell)"

CREATE_DMG_CMD=(
  "${SCRIPT_DIR}/run_create_dmg.sh"
  --volname "${VOLUME_NAME}"
  --volicon "${VOLICON}"
  --background "${GEN_ABS}"
  --window-pos "${DMG_WIN_X}" "${DMG_WIN_Y}"
  --window-size "${DMG_WIN_W}" "${DMG_WIN_H}"
  --text-size 12
  --icon-size "${DMG_ICON_SIZE}"
  --icon "Drazlo.app" "${DMG_APP_CX}" "${DMG_APP_CY}"
  --hide-extension "Drazlo.app"
  --app-drop-link "${DMG_APPS_CX}" "${DMG_APPS_CY}"
  --no-internet-enable
  "${DMG_PATH}"
  "${STAGING_DIR}"
)

echo ""
echo "========== 6. EXACT create-dmg COMMAND LINE =========="
printf ' %q' "${CREATE_DMG_CMD[@]}"
echo ""
echo ""
echo "Layout argv:"
echo "  --icon Drazlo.app ${DMG_APP_CX} ${DMG_APP_CY}"
echo "  --app-drop-link ${DMG_APPS_CX} ${DMG_APPS_CY}"
echo "  --background ${GEN_ABS}"

echo ""
echo "========== BUILD (SKIP_DMG_POLISH=1, CI path) =========="
SKIP_DMG_REGEN=1 SKIP_DMG_POLISH=1 "${CREATE_DMG_CMD[@]}"

echo ""
echo "========== 3–4. MOUNT FINISHED DMG + .background/ =========="
for m in /Volumes/Drazlo /Volumes/Drazlo\ *; do
  [[ -d "${m}" ]] && hdiutil detach "${m}" -quiet 2>/dev/null || true
done

hdiutil attach -nobrowse -readonly "${DMG_PATH}" | tee /tmp/dmg-audit-attach.txt
MOUNT="$(grep '/Volumes/' /tmp/dmg-audit-attach.txt | tail -1 | awk '{print $3}')"
echo "MOUNT=${MOUNT}"

echo ""
echo "ls -la ${MOUNT}/.background/"
ls -la "${MOUNT}/.background/" || echo "(no .background directory)"

BG_IN_DMG=""
if [[ -d "${MOUNT}/.background" ]]; then
  BG_IN_DMG="$(find "${MOUNT}/.background" -type f -name '*.png' | head -1)"
fi

if [[ -n "${BG_IN_DMG}" ]]; then
  DMG_BG_ABS="$(cd "$(dirname "${BG_IN_DMG}")" && pwd)/$(basename "${BG_IN_DMG}")"
  DMG_BG_SHA="$(sha "${DMG_BG_ABS}")"
  echo ""
  echo "DMG_BACKGROUND_PATH=${DMG_BG_ABS}"
  echo "DMG_BACKGROUND_SHA256=${DMG_BG_SHA}"
  echo "GENERATED_PNG_SHA256=${GEN_SHA}"
  if [[ "${DMG_BG_SHA}" == "${GEN_SHA}" ]]; then
    echo "HASH_MATCH=yes"
  else
    echo "HASH_MATCH=no — bytes differ between generated PNG and DMG .background copy"
    cmp -l "${GEN_ABS}" "${DMG_BG_ABS}" 2>/dev/null | head -5 || true
  fi
else
  echo "DMG_BACKGROUND_PATH=(missing — create-dmg AppleScript may not have run or background not copied)"
fi

echo ""
echo "========== .DS_Store on volume =========="
if [[ -f "${MOUNT}/.DS_Store" ]]; then
  echo "DS_STORE_PATH=${MOUNT}/.DS_Store"
  echo "DS_STORE_SHA256=$(sha "${MOUNT}/.DS_Store")"
  echo "DS_STORE_SIZE=$(stat -f%z "${MOUNT}/.DS_Store")"
  strings "${MOUNT}/.DS_Store" | grep -E 'background|\.background|dmg-background' || echo "(no background string in .DS_Store strings)"
else
  echo "DS_STORE=(missing)"
fi

echo ""
echo "========== 7. Does create-dmg replace background after copy? =========="
echo "create-dmg copies PNG once to .background/ (line ~469), then AppleScript sets"
echo "background picture reference in .DS_Store — it does NOT re-copy or replace the PNG file."
echo "polish_dmg_layout.sh is SKIPPED in this audit (SKIP_DMG_POLISH=1)."

hdiutil detach "${MOUNT}" -quiet

echo ""
echo "========== 8. Finder cache note =========="
echo "Mounted read-only from ${DMG_PATH}; Finder cache is per-volume .DS_Store inside DMG."
echo "If layout wrong but HASH_MATCH=yes, Finder is using .DS_Store layout + .background PNG"
echo "but icon positions/background binding in .DS_Store may be wrong (AppleScript stage)."

echo ""
echo "AUDIT_DMG=${DMG_PATH}"
echo "AUDIT_DEBUG_PNG=${DEBUG_ABS}"
