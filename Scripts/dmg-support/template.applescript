on hideExtraFinderChrome()
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
end hideExtraFinderChrome

on run (volumeName)
	tell application "Finder"
		tell disk (volumeName as string)
			open

			set theXOrigin to WINX
			set theYOrigin to WINY
			set theWidth to WINW
			set theHeight to WINH

			set theBottomRightX to (theXOrigin + theWidth)
			set theBottomRightY to (theYOrigin + theHeight)
			set dsStore to "\"" & "/Volumes/" & volumeName & "/" & ".DS_STORE\""

			tell container window
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				try
					set sidebar width to 0
				end try
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
				REPOSITION_HIDDEN_FILES_CLAUSE
			end tell

			set opts to the icon view options of container window
			tell opts
				set icon size to ICON_SIZE
				set text size to TEXT_SIZE
				set arrangement to not arranged
				try
					set shows icon preview to false
				end try
			end tell
			BACKGROUND_CLAUSE

			POSITION_CLAUSE
			HIDING_CLAUSE
			APPLICATION_CLAUSE
			QL_CLAUSE
			close
			open
			delay 1

			tell container window
				set toolbar visible to false
				set statusbar visible to false
				try
					set sidebar width to 0
				end try
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX - 10, theBottomRightY - 10}
			end tell
		end tell

		delay 1

		tell disk (volumeName as string)
			tell container window
				set toolbar visible to false
				set statusbar visible to false
				try
					set sidebar width to 0
				end try
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
			end tell
		end tell

		my hideExtraFinderChrome()

		delay 3

		set waitTime to 0
		set ejectMe to false
		repeat while ejectMe is false
			delay 1
			set waitTime to waitTime + 1
			if (do shell script "[ -f " & dsStore & " ]; echo $?") = "0" then set ejectMe to true
		end repeat
		log "waited " & waitTime & " seconds for .DS_STORE to be created."
	end tell
end run
