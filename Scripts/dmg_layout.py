#!/usr/bin/env python3
"""Single source of truth for Drazlo DMG Finder window layout (Day 47+).

Layout is applied by `Scripts/dmg_settings.py` via **dmgbuild** (single-step DMG + `.DS_Store`).
Background PNG coordinates use top-left origin, pixels = points × BG_SCALE (@2x, 144 DPI).
Icon Iloc values in .DS_Store match the coordinates below (points).
"""

from __future__ import annotations

import argparse

# Window (points)
WINDOW_W = 660
WINDOW_H = 400

# Icon row
ICON_SIZE = 100
ICON_CENTER_SPACING = 160  # center-to-center gap between app and Applications (120–180)

# Finder window chrome (screen position of top-left corner)
WIN_X = 400
WIN_Y = 120

# @2x background pixel space
BG_SCALE = 2
BG_W = WINDOW_W * BG_SCALE
BG_H = WINDOW_H * BG_SCALE
BG_DPI = 72 * BG_SCALE  # 144 — required for Finder to fill the window at @2x

# Icon positions in .DS_Store Iloc (points)
APP_CENTER_X = (WINDOW_W - ICON_CENTER_SPACING) // 2
APPS_CENTER_X = (WINDOW_W + ICON_CENTER_SPACING) // 2
ICON_CENTER_Y = 190

# Background PNG: subtle drag-hint arrow between icons (DMG_ARROW=0 to disable).
DRAW_ARROW = True

ARROW_CENTER_X = (APP_CENTER_X + APPS_CENTER_X) // 2
ARROW_CENTER_Y = ICON_CENTER_Y

# Legacy shell export names (create_dmg.sh / apply_dmg_ds_store.sh)
APP_FINDER_X = APP_CENTER_X
APPS_FINDER_X = APPS_CENTER_X
ICON_FINDER_Y = ICON_CENTER_Y


def shell_exports() -> str:
    """Print bash export statements for create_dmg.sh."""
    lines = [
        f"export DMG_WIN_W={WINDOW_W}",
        f"export DMG_WIN_H={WINDOW_H}",
        f"export DMG_WIN_X={WIN_X}",
        f"export DMG_WIN_Y={WIN_Y}",
        f"export DMG_ICON_SIZE={ICON_SIZE}",
        f"export DMG_APP_CX={APP_CENTER_X}",
        f"export DMG_APP_CY={ICON_CENTER_Y}",
        f"export DMG_APPS_CX={APPS_CENTER_X}",
        f"export DMG_APPS_CY={ICON_CENTER_Y}",
        f"export DMG_ARROW_CX={ARROW_CENTER_X}",
        f"export DMG_ARROW_CY={ARROW_CENTER_Y}",
        f"export DMG_APP_FINDER_X={APP_FINDER_X}",
        f"export DMG_APPS_FINDER_X={APPS_FINDER_X}",
        f"export DMG_ICON_FINDER_Y={ICON_FINDER_Y}",
        f"export DMG_BG_W={BG_W}",
        f"export DMG_BG_H={BG_H}",
        f"export DMG_BG_DPI={BG_DPI}",
    ]
    return "\n".join(lines)


def layout_summary() -> str:
    return (
        f"{WINDOW_W}x{WINDOW_H} window @ ({WIN_X}, {WIN_Y}), icon size {ICON_SIZE}, "
        f"spacing {ICON_CENTER_SPACING}pt center-to-center\n"
        f"  Iloc: app ({APP_CENTER_X}, {ICON_CENTER_Y}), apps ({APPS_CENTER_X}, {ICON_CENTER_Y})\n"
        f"  arrow center: ({ARROW_CENTER_X}, {ARROW_CENTER_Y})\n"
        f"  background: {BG_W}x{BG_H}px @ {BG_DPI} DPI\n"
        f"  applied by: Scripts/dmg_settings.py (dmgbuild)"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Drazlo DMG layout constants")
    parser.add_argument(
        "--shell",
        action="store_true",
        help="Print bash export statements (eval in create_dmg.sh)",
    )
    args = parser.parse_args()
    if args.shell:
        print(shell_exports())
    else:
        print(layout_summary())


if __name__ == "__main__":
    main()
