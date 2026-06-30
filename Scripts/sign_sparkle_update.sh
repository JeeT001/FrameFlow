#!/usr/bin/env bash
# Sign a release DMG for Sparkle appcast (EdDSA). Day 48.
#
# Usage:
#   ./Scripts/sign_sparkle_update.sh build/Drazlo-1.0.dmg
#
# Requires:
#   - Sparkle bin/sign_update (SPARKLE_BIN_DIR or auto-detect in DerivedData)
#   - EdDSA private key (SPARKLE_EDDSA_PRIVATE_KEY_FILE or SPARKLE_EDDSA_PRIVATE_KEY)
#
# Prints edSignature + byte length for Resources/Release/appcast.xml
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./Scripts/sign_sparkle_update.sh <path-to.dmg>

Environment (or Scripts/sparkle.env):
  SPARKLE_BIN_DIR                  Directory with sign_update + generate_keys
  SPARKLE_EDDSA_PRIVATE_KEY_FILE   Path to EdDSA private key file
  SPARKLE_EDDSA_PRIVATE_KEY        Inline private key (alternative to file)

Generate keys once (private key stays off git):
  1. Download Sparkle release tarball from GitHub
  2. ./generate_keys   # prints public key for Info.plist SUPublicEDKey
  3. Store private key at ~/.sparkle/drazlo_eddsa_private.key (gitignored)

Update appcast:
  Copy printed edSignature and length into Resources/Release/appcast.xml
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

DMG_PATH="${1:-}"
if [[ -z "${DMG_PATH}" || ! -f "${DMG_PATH}" ]]; then
  echo "error: provide path to a built .dmg file." >&2
  usage >&2
  exit 1
fi

if [[ -f "${SCRIPT_DIR}/sparkle.env" ]]; then
  # shellcheck disable=SC1091
  set -a && source "${SCRIPT_DIR}/sparkle.env" && set +a
fi

find_sparkle_bin_dir() {
  if [[ -n "${SPARKLE_BIN_DIR:-}" && -x "${SPARKLE_BIN_DIR}/sign_update" ]]; then
    echo "${SPARKLE_BIN_DIR}"
    return 0
  fi

  local candidate
  while IFS= read -r candidate; do
    if [[ -x "${candidate}/sign_update" ]]; then
      echo "${candidate}"
      return 0
    fi
  done < <(
    find "${HOME}/Library/Developer/Xcode/DerivedData" -type f -name sign_update 2>/dev/null \
      | sed 's|/sign_update$||' \
      | sort -u
  )

  return 1
}

resolve_private_key_file() {
  if [[ -n "${SPARKLE_EDDSA_PRIVATE_KEY:-}" ]]; then
    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "${tmp}"' EXIT
    printf '%s' "${SPARKLE_EDDSA_PRIVATE_KEY}" > "${tmp}"
    echo "${tmp}"
    return 0
  fi

  local key_file="${SPARKLE_EDDSA_PRIVATE_KEY_FILE:-${HOME}/.sparkle/drazlo_eddsa_private.key}"
  if [[ -f "${key_file}" ]]; then
    echo "${key_file}"
    return 0
  fi

  return 1
}

SPARKLE_BIN="$(find_sparkle_bin_dir)" || {
  echo "error: sign_update not found." >&2
  echo "Download Sparkle release utilities and set SPARKLE_BIN_DIR, or build the app once so SPM fetches Sparkle." >&2
  echo "https://github.com/sparkle-project/Sparkle/releases" >&2
  exit 1
}

SIGN_UPDATE="${SPARKLE_BIN}/sign_update"
KEY_FILE=""
if KEY_FILE="$(resolve_private_key_file)"; then
  echo "==> Signing update: ${DMG_PATH}"
  echo "    sign_update: ${SIGN_UPDATE}"
  echo "    key file: ${KEY_FILE}"
  SIGN_OUTPUT="$("${SIGN_UPDATE}" "${DMG_PATH}" --ed-key-file "${KEY_FILE}")"
else
  echo "==> Signing update: ${DMG_PATH}"
  echo "    sign_update: ${SIGN_UPDATE}"
  echo "    key source: macOS Keychain (from generate_keys)"
  SIGN_OUTPUT="$("${SIGN_UPDATE}" "${DMG_PATH}")" || {
    echo "error: EdDSA private key not found." >&2
    echo "Run generate_keys from Sparkle bin/, or set SPARKLE_EDDSA_PRIVATE_KEY_FILE." >&2
    exit 1
  }
fi
echo "${SIGN_OUTPUT}"

BYTE_LENGTH="$(wc -c < "${DMG_PATH}" | tr -d ' ')"
echo ""
echo "==> Appcast values"
echo "length=\"${BYTE_LENGTH}\""
echo ""
echo "Paste edSignature from sign_update output into Resources/Release/appcast.xml"
echo "Host DMG at the enclosure url, then publish appcast.xml at https://drazlo.vercel.app/appcast.xml"
