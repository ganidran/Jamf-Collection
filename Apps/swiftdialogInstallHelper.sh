#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

dialogPath="/Library/Application Support/Dialog"
imagePath="/usr/local/jamf/company-icon.png"

###########################
##### DO THE THINGS #######
###########################

# Check if the dialog folder exists
if [ -e "$dialogPath" ]
then
    echo "Dialog folder exists. Renewing..."
    rm -rf "$dialogPath"
    rm -f /usr/bin/local/dialog
fi

# Load the fontd daemon to avoid Xfont errors
launchctl load -w /System/Library/LaunchAgents/com.apple.fontd.useragent.plist

# Create folder with Company image
mkdir "$dialogPath"
sleep 1
chown root:wheel "$dialogPath"
chmod 755 "$dialogPath"
cp $imagePath "$dialogPath"
mv "$dialogPath"/company-icon.png "$dialogPath"/Dialog.png
exit 0
