# Drazlo DMG assets (Day 47)

Discord-style installer: clean gradient background; **Drazlo.app** and **Applications** icons placed by `create-dmg` (no arrow in background art).

| File | Purpose |
|------|---------|
| `DrazloVolume.icns` | DMG volume icon |
| `dmg-background-light.png` | @2x background (660×400 pt window) — light gradient |
| `dmg-background-dark.png` | Dark variant |

Regenerate backgrounds after art changes:

```bash
python3 Scripts/generate_dmg_backgrounds.py
./Scripts/create_dmg.sh
./Scripts/notarize_dmg.sh
```

Preview: eject old mounts, then `open build/Drazlo-1.0.dmg` (Finder → tabs off).
