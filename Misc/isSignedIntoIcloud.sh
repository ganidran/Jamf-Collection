#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Determine the current user 
currentUser=$(stat -f "%Su" /dev/console)
# Plist pths
appleAccountsPlist="/Library/Preferences/SystemConfiguration/com.apple.accounts.exists.plist"
mobileMePlist="/Users/$currentUser/Library/Preferences/MobileMeAccounts.plist"

###########################
###### CHECK PLISTS #######
###########################

# Check if the com.apple.accounts.exists.plist file exists
if [ -f "$appleAccountsPlist" ]; then
    appleAccountValue=$(/usr/libexec/PlistBuddy -c "Print :com.apple.account.AppleAccount.exists" "$appleAccountsPlist" 2>/dev/null)
    if [ "$appleAccountValue" == "1" ]; then
        echo "<result>Yes</result>"
    else
        echo "<result>No</result>"
    fi
    exit 0
fi

# Check if the MobileMeAccounts.plist file exists if com.apple.accounts.exists.plist doesn't exist
if [ -f "$mobileMePlist" ]; then
    accountDSID=$(/usr/libexec/PlistBuddy -c "Print :Accounts:0:AccountDSID" "$mobileMePlist" 2>/dev/null)
    if [ -n "$accountDSID" ]; then
        echo "<result>Yes</result>"
    else
        echo "<result>No</result>"
    fi
else
    echo "<result>No plist files found.</result>"
fi
