#!/usr/bin/env python3
"""Minimal DMG background: light gradient + centered arrow only (no app icons baked in)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Resources" / "DMG"

# @2x for create-dmg window 660×400 pt — keep in sync with Scripts/create_dmg.sh
W, H = 1320, 800
WINDOW_W, WINDOW_H = 660, 400
ICON_SIZE = 100
ICON_Y_FROM_BOTTOM = 150  # (400 - 100) / 2
LEFT_ICON_X = 194
RIGHT_ICON_X = 366
ARROW_BLUE = (0x0A, 0x84, 0xFF)


def _gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(size[1]):
        t = y / max(size[1] - 1, 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (size[0], y)], fill=color)
    return img


def _icon_center_y_px() -> int:
    from_top = WINDOW_H - ICON_Y_FROM_BOTTOM - (ICON_SIZE / 2)
    return int(from_top * (H / WINDOW_H))


def _draw_arrow(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    half = int(56 * (W / WINDOW_W))
    x0, x1 = cx - half, cx + half - 14
    draw.line([(x0, cy), (x1, cy)], fill=color, width=8)
    draw.polygon([(x1 + 18, cy), (x1 - 4, cy - 13), (x1 - 4, cy + 13)], fill=color)


def _render(*, dark: bool) -> Image.Image:
    if dark:
        img = _gradient((W, H), (0x1C, 0x1C, 0x1E), (0x28, 0x28, 0x2A))
    else:
        img = _gradient((W, H), (0xF7, 0xF7, 0xF9), (0xFF, 0xFF, 0xFF))

    cx = int((WINDOW_W / 2) * (W / WINDOW_W))
    cy = _icon_center_y_px()
    _draw_arrow(ImageDraw.Draw(img), cx, cy, ARROW_BLUE)
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    _render(dark=False).save(OUT / "dmg-background-light.png", optimize=True)
    _render(dark=True).save(OUT / "dmg-background-dark.png", optimize=True)
    print(f"Wrote {OUT}/dmg-background-light.png")
    print(f"Wrote {OUT}/dmg-background-dark.png")
    print(
        f"Layout: {WINDOW_W}x{WINDOW_H} window, icon size {ICON_SIZE}, "
        f"positions ({LEFT_ICON_X}, {ICON_Y_FROM_BOTTOM}) and ({RIGHT_ICON_X}, {ICON_Y_FROM_BOTTOM})"
    )


if __name__ == "__main__":
    main()
