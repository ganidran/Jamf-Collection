#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Determine the current user
currentUser=$(stat -f "%Su" /dev/console)

# Define paths for relevant plist files
appleAccountsPlist="/Library/Preferences/SystemConfiguration/com.apple.accounts.exists.plist"
mobileMePlist="/Users/$currentUser/Library/Preferences/MobileMeAccounts.plist"

# Extract Account ID from MobileMeAccounts.plist using plutil and awk
accountId=$(plutil -convert xml1 -o - "$mobileMePlist" | awk '/<key>AccountID<\/key>/{getline; print}' | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')

###########################
### CHECK ICLOUD STATUS ###
###########################

# Check if the com.apple.accounts.exists.plist file exists
if [ -f "$appleAccountsPlist" ]; then
    # Use PlistBuddy to get the value of com.apple.account.AppleAccount.exists
    appleAccountValue=$(/usr/libexec/PlistBuddy -c "Print :com.apple.account.AppleAccount.exists" "$appleAccountsPlist" 2>/dev/null)
    # Check if iCloud account is logged in based on the retrieved value
    if [ "$appleAccountValue" == "1" ]; then
        echo "<result>Yes. $accountId logged in</result>"
    else
        echo "<result>No</result>"
        exit 0
    fi
else
    # If the com.apple.accounts.exists.plist file doesn't exist, presume iCloud is not logged in
    echo "<result>No</result>"
    exit 0
fi
exit 0
