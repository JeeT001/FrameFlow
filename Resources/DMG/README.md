# Drazlo DMG assets (Day 47)

Professional drag-to-Applications installer: centered **app → arrow → Applications** row.

| File | Purpose |
|------|---------|
| `DrazloVolume.icns` | DMG volume icon |
| `dmg-background-light.png` | @2x background (660×400 pt) — gradient + arrow only, **144 DPI** |
| `dmg-background-dark.png` | Dark variant |

**Layout:** `Scripts/dmg_layout.py` → `Scripts/dmg_settings.py` via **dmgbuild** (single-step DMG + `.DS_Store`).

```bash
python3 Scripts/dmg_layout.py
python3 Scripts/generate_dmg_backgrounds.py
./Scripts/create_dmg.sh
./Scripts/notarize_dmg.sh
```

Debug: `python3 Scripts/generate_dmg_backgrounds.py --debug` or `open Resources/DMG/dmg-background-debug.png`

Python deps: `pip install -r Scripts/requirements-dmg.txt` (`dmgbuild`)
