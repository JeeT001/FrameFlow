on run argv
	-- Layout argv from Scripts/dmg_layout.py (same center coords as create-dmg)
	set volumeName to item 1 of argv
	set winX to 400
	set winY to 120
	set winW to 660
	set winH to 400
	set iconSz to 100
	set appCy to 190
	set appCx to 250
	set appsCx to 410

	if (count of argv) ≥ 2 then set winX to item 2 of argv as integer
	if (count of argv) ≥ 3 then set winY to item 3 of argv as integer
	if (count of argv) ≥ 4 then set winW to item 4 of argv as integer
	if (count of argv) ≥ 5 then set winH to item 5 of argv as integer
	if (count of argv) ≥ 6 then set iconSz to item 6 of argv as integer
	if (count of argv) ≥ 7 then set appCy to item 7 of argv as integer
	if (count of argv) ≥ 8 then set appCx to item 8 of argv as integer
	if (count of argv) ≥ 9 then set appsCx to item 9 of argv as integer

	tell application "Finder"
		activate
		tell disk volumeName
			close
			open
			delay 0.5

			tell container window
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				try
					set sidebar width to 0
				end try
				set the bounds to {winX, winY, winX + winW, winY + winH}
			end tell

			tell icon view options of container window
				set icon size to iconSz
				set text size to 12
				set arrangement to not arranged
				try
					set shows icon preview to false
				end try
			end tell

			set position of item "Drazlo.app" to {appCx, appCy}
			set the extension hidden of item "Drazlo.app" to true
			set position of item "Applications" to {appsCx, appCy}

			close
			open
			delay 1

			tell container window
				set toolbar visible to false
				set statusbar visible to false
				try
					set sidebar width to 0
				end try
				set the bounds to {winX, winY, winX + winW, winY + winH}
			end tell
		end tell

		delay 0.3
		tell application "System Events"
			tell process "Finder"
				try
					set viewMenu to menu 1 of menu bar item "View" of menu bar 1
					repeat with menuLabel in {"Hide Tab Bar", "Hide Path Bar", "Hide Preview"}
						try
							if exists menu item menuLabel of viewMenu then
								click menu item menuLabel of viewMenu
							end if
						end try
					end repeat
				end try
			end tell
		end tell

		delay 1
	end tell
end run
