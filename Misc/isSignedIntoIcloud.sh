#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Determine the current user 
currentUser=$(stat -f "%Su" /dev/console)
# Plist paths
appleAccountsPlist="/Library/Preferences/SystemConfiguration/com.apple.accounts.exists.plist"
mobileMePlist="/Users/$currentUser/Library/Preferences/MobileMeAccounts.plist"
# macOS Version
osVersion=$(sw_vers -productversion)

###########################
####### IF OS > 13 ########
###########################

# Check if the OS version is greater than or equal to 13.0
if [[ "$osVersion" < 13 ]]; then
  echo "OS Version is less than 13"
else
    echo "OS Version is greater than 13"
    # Check if the com.apple.accounts.exists.plist file exists
    if [ -f "$appleAccountsPlist" ]; then
        appleAccountValue=$(/usr/libexec/PlistBuddy -c "Print :com.apple.account.AppleAccount.exists" "$appleAccountsPlist" 2>/dev/null)
        if [ "$appleAccountValue" == "1" ]; then
            echo "<result>Yes</result>"
        else
            echo "<result>No</result>"
        fi
    else
        echo "<result>No</result>"
        exit 0
    fi
fi

###########################
####### IF OS < 13 ########
###########################

# Check if the MobileMeAccounts.plist file exists 
if [ -f "$mobileMePlist" ]; then
    accountDSID=$(/usr/libexec/PlistBuddy -c "Print :Accounts:0:AccountDSID" "$mobileMePlist" 2>/dev/null)
    if [ -n "$accountDSID" ]; then
        echo "<result>Yes</result>"
    else
        echo "<result>No</result>"
    fi
else
    echo "<result>No</result>"
fi
