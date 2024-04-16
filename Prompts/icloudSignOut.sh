#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Path to our dialog binary
dialogPath='/usr/local/bin/dialog'
# Determine the current user
currentUser=$(stat -f "%Su" /dev/console)
# Define paths for relevant plist files
appleAccountsPlist="/Library/Preferences/SystemConfiguration/com.apple.accounts.exists.plist"
mobileMePlist="/Users/$currentUser/Library/Preferences/MobileMeAccounts.plist"
# Extract Account ID from MobileMeAccounts.plist using plutil and awk
accountId=$(plutil -convert xml1 -o - "$mobileMePlist" | awk '/<key>AccountID<\/key>/{getline; print}' | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')

###########################
##### SYSTEM CHECKS #######
###########################

# Check if Company images exist
if [ -e /usr/local/jamf/company-icon.png ]
then
    echo "Company Images exist. Proceeding..."
else
    echo "Company Images don't not exist. Installing..."
    jamf policy -event install-company-images
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
## CHECK THE PLIST FILE ###
###########################

# Check if the iCloud plist files exist
if [ -f "$appleAccountsPlist" ]; then
    appleAccountValue=$(/usr/libexec/PlistBuddy -c "Print :com.apple.account.AppleAccount.exists" "$appleAccountsPlist" 2>/dev/null)
    if [ "$appleAccountValue" == "1" ]; then
        echo "User is signed into iCloud via $accountId. Displaying notice..."
    else
        echo "User is NOT signed into iCloud"
        exit 0
    fi
fi

###########################
###### PROMPT USER ########
###########################

"$dialogPath" \
--title "Signing out of iCloud" \
--message "We've detected that you are signed into iCloud. Company policy limits access to it on company hardware. \n\nTo sign out, click the Apple logo () at the top right, select **System Settings**, click your Apple ID and finally, scroll down to click **Sign Out**. \n\nIf any questions arise, please contact the IT team. Thank you!" \
--button1text "This message will expire soon..." \
--button1disabled \
--ontop \
--messagefont "size=16" \
--moveable \
--timer 120 \
--hidetimerbar \
--quitkey l \
--width 600 --height 300 \
--icon caution \
--overlayicon /usr/local/jamf/company-icon.png        

exit 0
