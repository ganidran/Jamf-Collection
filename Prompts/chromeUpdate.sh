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

# Check if Company images exist
if [ -e /usr/local/jamf/company-icon.png ]
then
    echo "Company Images exist. Proceeding..."
else
    echo "Company Images don't not exist. Installing..."
    jamf policy -event install-Company-images
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

echo "
----User is on $currentChrome vs. $compareChrome.----
"

# Compare the two version numbers
if [[ $(printf '%s\n' "$currentChrome" "$compareChrome" | sort -V | head -n1) != "$compareChrome" ]]; then
  echo "Current Chrome version $currentChrome is less than latest version: $compareChrome. Downloading & installing update..."
else
  echo "Current Chrome version $currentChrome is greater than or equal to $compareChrome. Update downloaded. Installing..."
fi

# Install latest Chrome in the background
curl -L https://dl.google.com/dl/chrome/mac/universal/stable/gcem/GoogleChrome.pkg -o /tmp/GoogleChrome.pkg

# Run dialog pop up
"$dialogPath" \
--title "Update Required!" \
--message "Per #security's slack post, we need to make sure Chrome is updated to the version released on $releaseDate. Doing so will close Chrome so make sure all data is saved. \n\nYou can re-open all your current tabs by going to **'File > Reopen Closed Tab'** or pressing **'⌘ + Shift + T'** on your keyboard once it re-launches." \
--button1text "Update Chrome" \
--ontop \
--button2text "Not Now" \
--messagefont size=18 \
--icon /usr/local/jamf/company-icon.png \
--width 600 --height 300
dialogResults=$?

# Open system settings
if [ "$dialogResults" == "0" ]; then
    echo "
    ----Notification acknowledged. Updating Chrome...----
    "
    installer -pkg /tmp/GoogleChrome.pkg -target / -verbose
    killall "Google Chrome"
    sleep 1
    open -a "Google Chrome"
    jamf recon    
else
    echo "
    ----Notification dismissed. Chrome not yet updated.----
    "
fi

exit 0
