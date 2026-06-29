#!/usr/bin/env bash
# Eject every mounted Drazlo DMG volume (including "Drazlo 1", "Drazlo 2", …).
# Safe to run when nothing is mounted. Works in bash and zsh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release_common.sh
source "${SCRIPT_DIR}/release_common.sh"

release_eject_drazlo_volumes

remaining="$(hdiutil info 2>/dev/null | awk -F'\t' '/\/Volumes\/Drazlo/{print $3}' | wc -l | tr -d ' ')"
if [[ "${remaining}" != "0" ]]; then
  echo "warning: ${remaining} Drazlo volume(s) may still be mounted" >&2
  hdiutil info 2>/dev/null | awk -F'\t' '/\/Volumes\/Drazlo/{print "  " $3}'
  exit 1
fi

echo "==> All Drazlo volumes ejected"
