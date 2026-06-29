"""dmgbuild settings for Drazlo drag-to-Applications installer.

Invoked by Scripts/create_dmg.sh:
  python3 -m dmgbuild -s Scripts/dmg_settings.py -D app=... Drazlo output.dmg
"""

from __future__ import annotations

import sys
from pathlib import Path

repo_root = Path(defines.get("repo_root", "."))  # noqa: F821
script_dir = repo_root / "Scripts"
sys.path.insert(0, str(script_dir))
import dmg_layout as layout  # noqa: E402

# DMG_ARROW=0 disables the background arrow; on by default.
if str(defines.get("arrow", "1")) in ("0", "false", "False"):  # noqa: F821
    layout.DRAW_ARROW = False

application = defines.get("app")  # noqa: F821
if not application:
    raise SystemExit("dmg_settings: -D app=/path/to/Drazlo.app is required")

dmg_assets = repo_root / "Resources" / "DMG"

theme = defines.get("theme", "light")  # noqa: F821
skip_layout = str(defines.get("skip_layout", "0")) in ("1", "true", "True")  # noqa: F821

background_name = "dmg-background-dark.png" if theme == "dark" else "dmg-background-light.png"
background_path = defines.get("background") or str(dmg_assets / background_name)  # noqa: F821
volume_icon = defines.get("volume_icon") or str(dmg_assets / "DrazloVolume.icns")  # noqa: F821

volume_name = defines.get("volume_name", "Drazlo")  # noqa: F821
format = defines.get("format", "UDZO")  # noqa: F821
compression_level = 9

files = [application]
symlinks = {"Applications": "/Applications"}
hide_extensions = ["Drazlo.app"]
hide = [".background.png", ".VolumeIcon.icns"]
icon = volume_icon

if skip_layout:
    background = None
    icon_locations = {}
else:
    background = background_path
    icon_locations = {
        "Drazlo.app": (layout.APP_CENTER_X, layout.ICON_CENTER_Y),
        "Applications": (layout.APPS_CENTER_X, layout.ICON_CENTER_Y),
    }

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 0

window_rect = ((layout.WIN_X, layout.WIN_Y), (layout.WINDOW_W, layout.WINDOW_H))
default_view = "icon-view"
show_icon_preview = False
include_icon_view_settings = True
include_list_view_settings = False

arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = "bottom"
text_size = 12
icon_size = layout.ICON_SIZE
