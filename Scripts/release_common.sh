#!/usr/bin/env bash
# Shared helpers for Drazlo release scripts (Day 46–47).
set -euo pipefail

release_repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  cd "${script_dir}/.." && pwd
}

release_marketing_version() {
  local repo_root="${1:?}"
  local xcode_project="${repo_root}/FrameFlow/FrameFlow.xcodeproj"
  local version

  version="$(
    xcodebuild -showBuildSettings \
      -project "${xcode_project}" \
      -scheme Drazlo \
      -configuration Release 2>/dev/null \
      | awk -F' = ' '/MARKETING_VERSION/{print $2; exit}'
  )"

  if [[ -z "${version}" ]]; then
    echo "1.0"
  else
    echo "${version}"
  fi
}

release_require_notary_env() {
  if [[ -z "${NOTARY_APPLE_ID:-}" ]]; then
    echo "error: NOTARY_APPLE_ID is required (Apple ID email)." >&2
    exit 1
  fi
  if [[ -z "${NOTARY_APP_PASSWORD:-}" ]]; then
    echo "error: NOTARY_APP_PASSWORD is required (app-specific password or @keychain:label)." >&2
    exit 1
  fi
}

release_validate_stapled_app() {
  local app_path="${1:?}"

  if [[ ! -d "${app_path}" ]]; then
    echo "error: app bundle not found at ${app_path}" >&2
    echo "Run ./Scripts/archive_release.sh and ./Scripts/notarize_app.sh first." >&2
    exit 1
  fi

  echo "==> Verify app code signature"
  codesign --verify --deep --strict --verbose=2 "${app_path}"

  echo "==> Verify app notarisation staple"
  if ! xcrun stapler validate "${app_path}" >/dev/null 2>&1; then
    echo "error: ${app_path} is not stapled. Run ./Scripts/notarize_app.sh first." >&2
    exit 1
  fi
}
