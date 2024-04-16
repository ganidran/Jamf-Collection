#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Set date in Jamf - parameter 4
releaseDate="$4"
# Dialog path
dialogPath="/usr/local/bin/dialog"
# pBuddy variables
pBuddy="/usr/libexec/PlistBuddy"
deferralMaximum="5"
deferralPlist="/private/var/tmp/com.os$releaseDate.deferrals.plist"

###########################
##### SYSTEM CHECKS #######
###########################

# Check for existing macOS installer
for installer in /Library/Management/erase-install/*.pkg
do
    if [ -e "$installer" ]
    then
        echo "Cached installer found. Proceeding..."
        break
    else
        echo "Cached installer not found. Exiting."
        exit 0
    fi
done

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
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
fi
sleep 1

###########################
##### SET FUNCTIONS #######
###########################

function doTheThings()
{
    # We do the thing!
    echo "Installing the cached update..."
    # Since we did the things, we'll set the deferral count back to 0
    sleep 1
    jamf policy -event install-os-cached
}

function promptWithDeferral()
{
    # This is where we define the dialog window options asking the user if they want to do the thing.
    "$dialogPath" \
    --title "Time To Update macOS!" \
    --icon /usr/local/jamf/company-icon.png \
    --message "Hi! Company IT here to inform of an important macOS update released on $releaseDate. This **can take 30 minutes or more**.  \n\nSave any open documents and connect your laptop to power before continuing. If you're able to update now, _Update_ will start the process. Otherwise, _Not Now_ will defer it for a maximum of 5 deferrals. \n\n**You can also update manually anytime from our Company Self Service app. See [our Notion page](<Internal Documentation Link>) for more info.**" \
    --button1text "Update" \
    --button2text "Not Now" \
    --messageposition center \
    --moveable \
    --ontop \
    --messagefont "size=15" \
    --width 650 --height 325
} 

function promptNoDeferral()
{
    # This is where we define the dialog window options when we're no longer offering deferrals. "Aggressive mode" so to speak.
    "$dialogPath" \
    --title "ALERT: The update is about to start!" \
    --icon /usr/local/jamf/company-icon.png \
    --message "There is an outstanding update that needs to be installed and no deferrals are left. \n\n**This may take 30 minutes or more.** Your Mac will automatically update in 10 minutes. To begin the update immediately, press the 'Update Now' button. \n\nPlease make sure your laptop is plugged in, charging and save any open documents." \
    --moveable \
    --messageposition center \
    --quitkey l \
    --timer 600 \
    --ontop \
    --messagefont "size=15" \
    --button1text "Update Now" \
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

function verifyConfigProfile()
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

function checkForActiveDeferral()
{
    # This function checks if there is an active deferral present. If there is, then it exits quietly.

    # Get the current deferral value. This will be 0 if there is no active deferral
    currentDeferral=$($pBuddy -c "Print :ActiveDeferral" "$deferralPlist")
}

function executeDeferral()
{
    # This is where we define what happens when the user chooses to defer. We increase the number of deferrals by 1. This gets checked against the maximum allowed deferrals next time the script runs.
    deferralCount=$(( deferralCount + 1 ))
    "$dialogPath" \
    --title "Deferred" \
    --icon /usr/local/jamf/company-icon.png \
    --message "Update will be deferred. You have deferred $deferralCount of $deferralMaximum time(s)." \
    --button1text "OK" \
    --moveable \
    --ontop \
    --messageposition center \
    --messagefont "size=15" \
    --width 500 --height 250
    deferraldialogResults=$?
    
    #Check if dialog exited with the default exit code
    if [ "$deferraldialogResults" = 0 ]; then
       true
    fi

    # Writing deferral values to the plist
    $pBuddy -c "Set DeferralCount $deferralCount" $deferralPlist
    $pBuddy -c "Add :HumanReadableDeferralDate string" "$deferralPlist"  > /dev/null 2>&1

    # Deferral has been processed. Exit cleanly.
    cleanup 0 "User chose deferral $deferralCount of $deferralMaximum."
}

###########################
##### DO THE THINGS #######
###########################

# Script Starts Here
verifyConfigProfile

# Get the current date in seconds (unix epoc time)
unixEpochTime=$(date +%s)
checkForActiveDeferral

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
    promptNoDeferral
    doTheThings
    # Capture the exit code of our things, so we can exit the script with the same exit code
    thingsExitCode=$?
    cleanup $thingsExitCode "Things were done. Exit code: $thingsExitCode"
fi 
