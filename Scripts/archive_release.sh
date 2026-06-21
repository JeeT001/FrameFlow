#!/usr/bin/env bash
# Archives and exports a Developer ID–signed Drazlo.app for notarisation (Day 46).
# Requires: Xcode, valid Developer ID Application certificate, automatic signing team 6XP66CQ82V.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
XCODE_PROJECT="${REPO_ROOT}/FrameFlow/FrameFlow.xcodeproj"
EXPORT_OPTIONS="${SCRIPT_DIR}/ExportOptions.plist"

SCHEME="${SCHEME:-Drazlo}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/build}"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"

echo "==> Drazlo release archive"
echo "    Scheme:        ${SCHEME}"
echo "    Configuration: ${CONFIGURATION}"
echo "    Archive:       ${ARCHIVE_PATH}"
echo "    Export:        ${EXPORT_PATH}"

if [[ ! -f "${EXPORT_OPTIONS}" ]]; then
  echo "error: ExportOptions.plist not found at ${EXPORT_OPTIONS}" >&2
  exit 1
fi

mkdir -p "${BUILD_DIR}"

echo "==> xcodebuild archive"
xcodebuild \
  -project "${XCODE_PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -archivePath "${ARCHIVE_PATH}" \
  archive

echo "==> xcodebuild -exportArchive (Developer ID)"
rm -rf "${EXPORT_PATH}"
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS}"

APP_PATH="${EXPORT_PATH}/${SCHEME}.app"
if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: expected exported app at ${APP_PATH}" >&2
  exit 1
fi

echo "==> Export complete"
echo "    App: ${APP_PATH}"
echo ""
echo "Next: ./Scripts/notarize_app.sh \"${APP_PATH}\""
