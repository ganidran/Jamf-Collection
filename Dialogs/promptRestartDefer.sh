#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Follow format: Feb 28 10:15
compareDate="$4"

# Variables
lastReboot=$(last reboot | awk '/reboot/{print $4" "$5" "$6}' | head -1)
dialogPath="/usr/local/bin/dialog"
pBuddy="/usr/libexec/PlistBuddy"

# Deferral values
deferralMaximum="3"
deferralPlist="/private/var/tmp/com.levelrestart.deferrals.plist"

###########################
##### SYSTEM CHECKS #######
###########################

# Compare reboot dates
if [[ "$lastReboot" > "$compareDate" ]]; then
    echo "The last reboot date is after $compareDate. Exiting..."
    exit 0
else
    echo "The last reboot date is on or before $compareDate. Prompting user to Restart..."
fi

# Check for dialog
if [ -e "$dialogPath" ]
then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
    sleep 1
fi

###########################
###### SET FUNCTIONS#######
###########################

function doTheThings()
{
    # We do the thing!
    echo "Restarting..."
    # Since we did the things, we'll set the deferral count back to 0
    $pBuddy -c "Set DeferralCount 0" $deferralPlist
    sleep 2
    shutdown -r now
}

function promptWithDeferral()
{
    # This is where we define the dialog window options asking the user if they want to do the thing.
    "$dialogPath" \
    --title "Time to Restart!" \
    --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarAdvanced.icns \
    --message "Level IT here! Your computer received an important background update this week that requires a quick reboot. Would you like to do so now? \n\nIf so, please save all open documents first. If not please restart or shut down your computer at the end of your workday. \n\nYou can defer this request 3 times." \
    --button1text "Restart" \
    --button2text "Not Now" \
    --messageposition center \
    --moveable \
    --messagefont "size=15" \
    --width 600 --height 300
}

function promptNoDefferal()
{
    # This is where we define the dialog window options when we're no longer offering deferrals
    "$dialogPath" \
    --title "Your computer is about to restart!" \
    --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarAdvanced.icns \
    --message "Your computer needs to restart and no deferrals are left. \n\nIt will automatically reboot in 10 minutes or immediately by clicking 'Restart Now'. \n\nPlease make sure your laptop is plugged in, charging and save any open documents." \
    --moveable \
    --messageposition center \
    --timer 600 \
    --messagefont "size=15" \
    --button1text "Restart Now" \
    --width 600 --height 300
}

# Send a message to the log. For the example it just echos to standard out
function logMessage()
{
    echo "$(date): $*"
}

# This function exits the script. Takes two arguments. Argument 1 is the exit code and argument 2 is an optional log message
function cleanup()
{
    # If you have temp folders/files that you want to delete as this script exits, this is the place to add that
    logMessage "${2}"
    exit "${1}"
}

function verifyConfigFile()
{
    # Check if we can write to the configuration file by writing something then deleting it.
    if $pBuddy -c "Add Verification string Success" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Delete Verification string Success" "$deferralPlist" > /dev/null 2>&1
    else
        # This should only happen if there's a permissions problem or if the deferralPlist value wasn't defined
        cleanup 1 "ERROR: Cannot write to the deferral file: $deferralPlist"
    fi

    # See below for what this is doing
    verifyDeferralValue "ActiveDeferral"
    verifyDeferralValue "DeferralCount"

}

function verifyDeferralValue()
{
    # Takes an argument to determine if the value exists in the deferral plist file.
    # If the value doesn't exist, it writes a 0 to that value as an integer
    # We always want some value in there so that PlistBuddy doesn't throw errors 
    # when trying to read data later
    if ! $pBuddy -c "Print :$1" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Add :$1 integer 0" "$deferralPlist"  > /dev/null 2>&1
    fi

}

function checkForActiveDefferal()
{
    # This function checks if there is an active deferral present. If there is, then it exits quietly.

    # Get the current deferral value. This will be 0 if there is no active deferral
    currentDeferral=$($pBuddy -c "Print :ActiveDeferral" "$deferralPlist")

    # If unixEpochTime is less than the current deferral time, it means there is an active deferral and we exit
    if [ "$unixEpochTime" -lt "$currentDeferral" ]; then
        cleanup 0 "Active deferral found. Exiting"
    else
        logMessage "No active deferral."
        # We'll delete the "human readable" deferral date value, if it exists.
        $pBuddy -c "Delete :HumanReadableDeferralDate" "$deferralPlist"  > /dev/null 2>&1
    fi
}

function executeDeferral()
{
    # This is where we define what happens when the user chooses to defer. We increase the number of deferrals by 1. This gets checked against the maximum allowed deferrals next time the script runs.
    deferralCount=$(( deferralCount + 1 ))
    "$dialogPath" \
    --title "Deferred" \
    --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarAdvanced.icns \
    --message "Restart will be deferred. You have deferred $deferralCount of $deferralMaximum time(s)." \
    --button1text "OK" \
    --moveable \
    --messageposition center \
    --messagefont "size=15" \
    --width 500 --height 250

    # Writing deferral values to the plist
    $pBuddy -c "Set DeferralCount $deferralCount" $deferralPlist
    $pBuddy -c "Add :HumanReadableDeferralDate string" "$deferralPlist"  > /dev/null 2>&1

    # Deferral has been processed. Exit cleanly.
    cleanup 0 "User chose deferral $deferralCount of $deferralMaximum."
}

###########################
###### DO THE THINGS ######
###########################

# Script Starts Here
verifyConfigFile

# Get the current date in seconds (unix epoc time)
unixEpochTime=$(date +%s)
checkForActiveDefferal

# Get the current deferral count
deferralCount=$($pBuddy -c "Print :DeferralCount" $deferralPlist)

# Check if the number of deferrals used is greater than the maximum allowed
if [ "$deferralCount" -ge "$deferralMaximum" ]; then
    allowDeferral="false"
else
    # Deferral count hasn't been exceeded, so we'll allow deferrals.
    allowDeferral="true"
fi

# If we're allowing deferrals, then
if [ "$allowDeferral" = "true" ]; then
    # Prompt the user to ask for consent. If it exits 0, they clicked OK and we'll do the things
    if promptWithDeferral; then
        # Here is where the actual things we want to do get executed
        doTheThings
        # Capture the exit code of our things, so we can exit the script with the same exit code
        thingsExitCode=$?
        cleanup $thingsExitCode "Things were done. Exit code: $thingsExitCode"
    else
        executeDeferral
    fi
else
    # We are NOT allowing deferrals, so we'll continue with or without user consent
    promptNoDefferal
    doTheThings
    # Capture the exit code of our things, so we can exit the script with the same exit code
    thingsExitCode=$?
    cleanup $thingsExitCode "Things were done. Exit code: $thingsExitCode"
fi