#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Define the update release date in Jamf - parameter 4
releaseDate="$4"
# Define the version number in Jamf - parameter 5
compareChrome="$5"
# Dialog path
dialogPath='/usr/local/bin/dialog'
# Get Chrome version number
currentChrome=$(plutil -p /Applications/Google\ Chrome.app/Contents/Info.plist | grep CFBundleShortVersionString | awk -F'"' '{print $4}')

###########################
####### FILE CHECKS #######
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
    echo "swiftDialog exists. Re-installing..."
    jamf policy -event install-swiftdialog
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
fi
sleep 1

###########################
####### DO THE DEW ########
###########################

# Compare the two version numbers
if [[ $(printf '%s\n' "$currentChrome" "$compareChrome" | sort -V | head -n1) != "$compareChrome" ]]; then
  echo "Chrome version $currentChrome is less than $compareChrome. Downloading and installing update."
else
  echo "Chrome version $currentChrome is greater than or equal to $compareChrome. Update downloaded, installing update."
fi

# Install latest Chrome in the background
curl -L https://dl.google.com/dl/chrome/mac/universal/stable/gcem/GoogleChrome.pkg -o /tmp/GoogleChrome.pkg && installer -pkg /tmp/GoogleChrome.pkg -target / -verbose

# Run dialog pop up
"$dialogPath" \
--title "Update Required!" \
--message "Per #security's new slack post on $releaseDate, we need to update Chrome ASAP. Doing so will close Chrome so make sure all data is saved. \n\nYou can re-open all your current tabs by going to **'File > Reopen Closed Tab'** or pressing **'⌘ + Shift + T'** on your keyboard once it re-launches." \
--button1text "Update Chrome" \
--ontop \
--button2text "Not Now" \
--messagefont size=18 \
--icon /usr/local/jamf/lvl-icon.png \
--width 600 --height 300
dialogResults=$?

# Open system settings
if [ "$dialogResults" == "0" ]; then
    echo "
    ----Notification acknowledged. Updating Chrome...----
    "
    killall "Google Chrome"
    sleep 2
    open -a "Google Chrome"
    jamf recon    
else
    echo "
    ----Notification dismissed. Chrome not yet updated.----
    "
fi

exit 0