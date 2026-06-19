# Drazlo DMG assets (Day 47)

| File | Purpose |
|------|---------|
| `dmg-background-light.png` | Finder window background (1600×800) — light theme |
| `dmg-background-dark.png` | Finder window background (1600×800) — dark theme |
| `DrazloVolume.icns` | DMG volume icon (from `AppIcon.appiconset`) |

Used by `Scripts/create_dmg.sh`. Default background is **light**; set `DMG_BACKGROUND=dark` for the dark variant.

To regenerate volume icon after app icon changes:

```bash
ICON_SRC="FrameFlow/FrameFlow/Assets.xcassets/AppIcon.appiconset"
ICONSET="Resources/DMG/DrazloVolume.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
cp "$ICON_SRC"/icon_*.png "$ICONSET"/
iconutil -c icns "$ICONSET" -o Resources/DMG/DrazloVolume.icns
rm -rf "$ICONSET"
```

Background art can be regenerated with Pillow (see Day 47 DEV_LOG) or replaced manually in a design tool — keep **1600×800** PNG.
