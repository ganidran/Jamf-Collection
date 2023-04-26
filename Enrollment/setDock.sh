#!/bin/bash

###########################
###### SET VARIABLE $######
###########################

# Check OS version
osVersion=$(sw_vers -productVersion)
# Get logged in user
loggedInUser=$(stat -f "%Su" /dev/console)
# Docks pre/post Venture
venturaDock="/usr/local/jamf/dock/com.apple.dock.v.plist"
montereyDock="/usr/local/jamf/dock/com.apple.dock.m.plist"
defaultDock="/usr/local/jamf/dock/com.apple.dock.plist"
# Default dock path
dockPath="/Users/$loggedInUser/Library/Preferences"

###########################
##### DO THE THINGS $######
###########################

# Remove current dock plist
defaults delete "$dockPath"/com.apple.dock.plist
sleep 0.5 

# Copy appropriate OS dock plist
if [[ "$osVersion" == "12."* ]]; then
    mv "$montereyDock" "$defaultDock"
    cp "$defaultDock" "$dockPath"
else
    mv "$venturaDock" "$defaultDock"
    cp "$defaultDock" "$dockPath"
fi
sleep 0.5

# Make logged in user plist owner
chown $loggedInUser "$dockPath"/com.apple.dock.plist
sleep 0.5

# Update cache
sudo -u $loggedInUser defaults read "$dockPath"/com.apple.dock.plist
sleep 0.5

# Restart the dock
killall Dock
sleep 10

# Reset the LaunchPad
sudo -u $loggedInUser defaults write com.apple.dock ResetLaunchPad -bool true
sleep 0.5
killall Dock

# Clean up
rm -rf /usr/local/jamf/dock