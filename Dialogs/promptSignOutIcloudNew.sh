#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Path to our dialog binary
dialogPath='/usr/local/bin/dialog'
currentUser=$(ls -l /dev/console | awk '{print $3}')

###########################
##### SYSTEM CHECKS #######
###########################

# Check if Level images exist
if [ -e /usr/local/jamf/lvl-icon.png ]
then
    echo "Level Images exist. Proceeding..."
else
    echo "Level Images don't not exist. Installing..."
    jamf policy -event install-level-images
fi

# Check if the dialog exists
if [ -e "$dialogPath" ]
then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
fi
sleep 1

###########################
###### PROMPT USER ########
###########################

if [ -f /Users/"$currentUser"/Library/Preferences/MobileMeAccounts.plist ]; then
    echo "User is signed into iCloud"
    # Dialog Popup
    "$dialogPath" \
    --title "Action Required!" \
    --message "Level company policy is now limiting access to iCloud on this Mac. We have detected that you are signed into iCloud. \n\nPlease open _System Preferences > Apple ID > Overview_ and sign out." \
    --button1text "Open Settings" \
    --width 600 --height 250 \
    --icon /usr/local/jamf/lvl-icon.png 
    dialogResults=$?
    echo "Result: $dialogResults - User is signed into iCloud"
        # Open system settings
        if [ "$dialogResults" == "0" ]; then
            open x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane
            exit 0
        fi            
else
        echo "User is not signed into iCloud."
        # Running a quick recon just in case
        jamf recon
fi

exit 0