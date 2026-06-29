#!/usr/bin/env python3
"""DEPRECATED: superseded by Scripts/dmg_settings.py + dmgbuild.

Write Finder .DS_Store for Drazlo DMG layout (no AppleScript / Finder GUI).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import dmg_layout as layout  # noqa: E402


def _window_bounds() -> str:
    return f"{{{{{layout.WIN_X}, {layout.WIN_Y}}}, {{{layout.WINDOW_W}, {layout.WINDOW_H}}}}}"


def _hidden_icon_xy() -> tuple[int, int]:
    """Off-window position for .background / .DS_Store (matches create-dmg reposition)."""
    return layout.WIN_X + layout.WINDOW_W + 100, 100


def _ds_key(name: str) -> str:
    """DS_Store filenames are null-terminated (root folder uses '\\x00' alone)."""
    return "\x00" if not name else f"{name}\x00"


def _background_alias(mount: Path, background_path: Path) -> bytes:
    """Alias must target the file on the mounted volume (not the repo source path)."""
    from mac_alias import Alias

    mount = mount.resolve()
    background_path = background_path.resolve()
    if not str(background_path).startswith(f"{mount}/"):
        raise ValueError(
            f"background must live on mounted volume {mount}, got {background_path}"
        )
    alias_path = str(background_path)
    return Alias.for_file(alias_path).to_bytes()


def write_ds_store(
    *,
    mount: Path,
    background_path: Path,
    ds_store_path: Path | None = None,
) -> None:
    from ds_store import DSStore

    if not mount.is_dir():
        raise SystemExit(f"error: mount path not found: {mount}")
    if not background_path.is_file():
        raise SystemExit(f"error: background not found: {background_path}")

    target = ds_store_path or (mount / ".DS_Store")
    hidden_x, hidden_y = _hidden_icon_xy()

    bwsp = {
        "ShowTabView": False,
        "ShowSidebar": False,
        "ShowStatusBar": False,
        "ShowToolbar": False,
        "WindowBounds": _window_bounds(),
        "ContainerShowSidebar": False,
        "PreviewPaneVisibility": False,
        "SidebarWidth": 0,
    }

    alias_bytes = _background_alias(mount, background_path)

    icvp = {
        "arrangeBy": "none",
        "backgroundColorBlue": 1.0,
        "backgroundColorGreen": 1.0,
        "backgroundColorRed": 1.0,
        "backgroundType": 2,
        "backgroundImageAlias": alias_bytes,
        "gridOffsetX": 0.0,
        "gridOffsetY": 0.0,
        "gridSpacing": 100.0,
        "iconSize": float(layout.ICON_SIZE),
        "labelOnBottom": True,
        "scrollPositionX": 0.0,
        "scrollPositionY": 0.0,
        "showIconPreview": False,
        "showItemInfo": False,
        "textSize": 12.0,
        "viewOptionsVersion": 1,
    }

    root = _ds_key("")
    with DSStore.open(str(target), "w+") as store:
        store[root]["vSrn"] = ("long", 1)
        store[root]["bwsp"] = bwsp
        store[root]["icvp"] = icvp
        store[root]["icvl"] = ("type", b"icnv")
        store[_ds_key("Drazlo.app")]["Iloc"] = (layout.APP_CENTER_X, layout.ICON_CENTER_Y)
        store[_ds_key("Applications")]["Iloc"] = (layout.APPS_CENTER_X, layout.ICON_CENTER_Y)
        store[_ds_key(".DS_Store")]["Iloc"] = (hidden_x, hidden_y)
        store[_ds_key(".background")]["Iloc"] = (hidden_x + 50, hidden_y)
        if (mount / ".VolumeIcon.icns").exists():
            store[_ds_key(".VolumeIcon.icns")]["Iloc"] = (hidden_x + 100, hidden_y)

    print(f"Wrote {target}")
    print(f"  WindowBounds: {_window_bounds()}")
    print(f"  Drazlo.app @ ({layout.APP_CENTER_X}, {layout.ICON_CENTER_Y})")
    print(f"  Applications @ ({layout.APPS_CENTER_X}, {layout.ICON_CENTER_Y})")
    print(f"  Background: {background_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Write Drazlo DMG .DS_Store via ds_store")
    parser.add_argument(
        "mount",
        type=Path,
        help="Mounted DMG volume root (e.g. /Volumes/Drazlo)",
    )
    parser.add_argument(
        "--background",
        type=Path,
        help="Absolute path to background PNG on the mounted volume",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Optional .DS_Store output path (default: <mount>/.DS_Store)",
    )
    args = parser.parse_args()

    mount = args.mount.resolve()
    background = args.background
    if background is None:
        light = mount / ".background" / "dmg-background-light.png"
        dark = mount / ".background" / "dmg-background-dark.png"
        background = light if light.is_file() else dark
    background = background.resolve()

    try:
        write_ds_store(mount=mount, background_path=background, ds_store_path=args.output)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
