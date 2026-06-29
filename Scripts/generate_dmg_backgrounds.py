#!/usr/bin/env python3
"""Minimal DMG background: light/dark gradient + arrow between icon centers (no baked icons)."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import dmg_layout as layout  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Resources" / "DMG"

ARROW_BLUE_LIGHT = (0x5A, 0xC8, 0xFA)  # soft system blue on light gradient
ARROW_BLUE_DARK = (0x64, 0xD2, 0xFF)  # slightly brighter on dark gradient
DEBUG_RED = (0xFF, 0x00, 0x00)


def _gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(size[1]):
        t = y / max(size[1] - 1, 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (size[0], y)], fill=color)
    return img


def _point_to_px(x: float, y: float) -> tuple[int, int]:
    """Convert Finder points (origin bottom-left) to PIL pixels (origin top-left)."""
    return int(x * layout.BG_SCALE), int((layout.WINDOW_H - y) * layout.BG_SCALE)


def _draw_arrow(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    """Subtle drag hint — only used when DRAW_ARROW is True."""
    half = int(44 * layout.BG_SCALE)
    width = max(4, 3 * layout.BG_SCALE)
    x0, x1 = cx - half, cx + half - 12
    draw.line([(x0, cy), (x1, cy)], fill=color, width=width)
    head = 10 * layout.BG_SCALE
    draw.polygon([(x1 + head, cy), (x1 - 2, cy - head), (x1 - 2, cy + head)], fill=color)


def _draw_debug_markers(draw: ImageDraw.ImageDraw) -> None:
    """Red circles at icon centers — open PNG directly to verify arrow alignment."""
    radius = layout.ICON_SIZE * layout.BG_SCALE // 2
    for cx, cy in (
        (layout.APP_CENTER_X, layout.ICON_CENTER_Y),
        (layout.APPS_CENTER_X, layout.ICON_CENTER_Y),
        (layout.ARROW_CENTER_X, layout.ARROW_CENTER_Y),
    ):
        px, py = _point_to_px(cx, cy)
        draw.ellipse(
            (px - radius, py - radius, px + radius, py + radius),
            outline=DEBUG_RED,
            width=4,
        )


def _render(*, dark: bool, debug: bool) -> Image.Image:
    if dark:
        img = _gradient((layout.BG_W, layout.BG_H), (0x1C, 0x1C, 0x1E), (0x28, 0x28, 0x2A))
    else:
        img = _gradient((layout.BG_W, layout.BG_H), (0xF7, 0xF7, 0xF9), (0xFF, 0xFF, 0xFF))

    draw = ImageDraw.Draw(img)
    if layout.DRAW_ARROW:
        ax, ay = _point_to_px(layout.ARROW_CENTER_X, layout.ARROW_CENTER_Y)
        arrow_color = ARROW_BLUE_DARK if dark else ARROW_BLUE_LIGHT
        _draw_arrow(draw, ax, ay, arrow_color)
    if debug:
        _draw_debug_markers(draw)
    return img


def _save_png(img: Image.Image, path: Path) -> None:
    img.save(path, optimize=True, dpi=(layout.BG_DPI, layout.BG_DPI))


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Generate Drazlo DMG background PNGs")
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Draw red circles at icon/arrow centers (writes *-debug.png only)",
    )
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)

    if args.debug:
        _save_png(_render(dark=False, debug=True), OUT / "dmg-background-light-debug.png")
        _save_png(_render(dark=True, debug=True), OUT / "dmg-background-dark-debug.png")
        print(f"Wrote {OUT}/dmg-background-light-debug.png")
        print(f"Wrote {OUT}/dmg-background-dark-debug.png")
        print("Open debug PNGs — red circles must align with arrow center and icon slots.")
    else:
        _save_png(_render(dark=False, debug=False), OUT / "dmg-background-light.png")
        _save_png(_render(dark=True, debug=False), OUT / "dmg-background-dark.png")
        print(f"Wrote {OUT}/dmg-background-light.png")
        print(f"Wrote {OUT}/dmg-background-dark.png")

    print(layout.layout_summary())


if __name__ == "__main__":
    main()
