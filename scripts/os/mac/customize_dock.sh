#!/usr/bin/env bash
#
# ░█▀▄░█▀█░█▀▀░█░█░░░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀
# ░█░█░█░█░█░░░█▀▄░░░█░░░█░█░█░█░█▀▀░░█░░█░█
# ░▀▀░░▀▀▀░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀
#
create_items() {

	large_blank='{tile-data={}; tile-type="spacer-tile";}'

	small_blank='{tile-data={}; tile-type="small-spacer-tile";}'

	launchpad=$(dock_item "/System/Applications/Launchpad.app")

	settings=$(dock_item "/System/Applications/System Settings.app")

	appstore=$(dock_item "/System/Applications/App Store.app")

	notes=$(dock_item "/System/Applications/Notes.app")

	firefox=$(dock_item "/Applications/Firefox Developer Edition.app")

	mail=$(dock_item "/Applications/Thunderbird.app")

	messages=$(dock_item "/System/Applications/Messages.app")

	messenger=$(dock_item "/Applications/Caprine.app")

	teams=$(dock_item "/Applications/Microsoft Teams.app")

	safari=$(dock_item "/Applications/Safari.app")

	fantastical=$(dock_item "/Applications/Fantastical.app")

	reminders=$(dock_item "/System/Applications/Reminders.app")

	music=$(dock_item "/System/Applications/Music.app")
	code=$(dock_item "/Applications/Visual Studio Code.app")

}

dock_item() {
	printf "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>" "$1"
}

customize_dock() {
	message "Customizing the dock"
	warning_message "Enter password to delete contents of dock and replace with new setup"

	create_items

	sudo su "$USER" -c 'defaults delete com.apple.dock persistent-apps'

	sudo su "$USER" -c "defaults write com.apple.dock persistent-apps -array		\
'$firefox' '$code' '$small_blank'"

	success_message "Dock contents were updated. Restarting dock..."

	killall Dock
}
