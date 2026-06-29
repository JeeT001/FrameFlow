#!/usr/bin/env python3
"""Write dmg-background-debug.png with colored dots at layout centres (audit only)."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import dmg_layout as layout  # noqa: E402
from generate_dmg_backgrounds import _draw_arrow, _point_to_px, _render  # noqa: E402

OUT = Path(__file__).resolve().parents[1] / "Resources" / "DMG" / "dmg-background-debug.png"

DOTS = (
    ((layout.APP_CENTER_X, layout.ICON_CENTER_Y), (255, 0, 0)),      # red — app
    ((layout.APPS_CENTER_X, layout.ICON_CENTER_Y), (0, 180, 0)),     # green — Applications
    ((layout.ARROW_CENTER_X, layout.ARROW_CENTER_Y), (0, 0, 255)),   # blue — arrow
)


def main() -> None:
    img = _render(dark=False, debug=False)
    draw = ImageDraw.Draw(img)
    r = 12
    for (cx, cy), color in DOTS:
        px, py = _point_to_px(cx, cy)
        draw.ellipse((px - r, py - r, px + r, py + r), fill=color)
    img.save(OUT, optimize=True, dpi=(layout.BG_DPI, layout.BG_DPI))
    print(f"Wrote {OUT}")
    for (cx, cy), color in DOTS:
        px, py = _point_to_px(cx, cy)
        name = { (255,0,0): "app", (0,180,0): "apps", (0,0,255): "arrow" }[color]
        print(f"  {name} center: pt=({cx},{cy}) px=({px},{py})")


if __name__ == "__main__":
    main()
