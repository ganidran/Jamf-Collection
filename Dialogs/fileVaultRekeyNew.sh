#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Dialog variabels
dialogPath="/usr/local/bin/dialog"
dialogTitle="Action Required"
dialogButton1="OK"
dialogButton2="Cancel"
dialogMessageNotify="Level IT here with an important notification! Your FileVault Key does **not** match our records and needs to be updated as soon as possible. \n\n Click 'OK' to update your key."
dialogMessage="Your FileVault Key needs to be updated. \n\nPlease enter your password:"
dialogTimer="900"
dialogMsgWrongPass="The computer password you entered is incorrect. Please try again"
dialogMsgForgotPass="You entered an incorrect computer passsword 5 times. Please contact support for assitance."
dialogIcon="/usr/local/jamf/lvl-icon.png"

# Current user
currentUser=$(ls -l /dev/console | awk '{print $3}')

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
    sleep 0.5
fi

# Check if the dialog exists
if [ -e "$dialogPath" ]
then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
    sleep 0.5
fi


# Quick root check
if [  "$currentUser" == "root" ]; then
    echo "Nobody logged in"
    # Exit. The Jamf Policy will trigger this entire workflow again
    exit 0
fi

###########################
###### SET FUNCTIONS ######
###########################

filevaultUserCheck() {
    filevaultUsers="$(/usr/bin/fdesetup list)"
    if ! /usr/bin/grep -E -q "^${currentUser}," <<< "$filevaultUsers"; then
        echo "User is not in the FileVault list, exiting"
        exit 22
    fi
}

fdeRecoveryAgentCheck() {
    # If needed, unload and kill FDERecoveryAgent.
    if /bin/launchctl list | /usr/bin/grep -q "com.apple.security.FDERecoveryAgent"; then
        echo "Unloading FDERecoveryAgent LaunchDaemon..."
        /bin/launchctl unload /System/Library/LaunchDaemons/com.apple.security.FDERecoveryAgent.plist
    fi
    if pgrep -q "FDERecoveryAgent"; then
        echo "Stopping FDERecoveryAgent process..."
        killall "FDERecoveryAgent"
    fi
}

notifyUser() {
    "${dialogPath}" \
    --title "${dialogTitle}" \
    --width 600 --height 300 \
    --hidetimerbar \
    --ontop \
    --message "${dialogMessageNotify}" \
    --button1text "${dialogButton1}" \
    --button2text "${dialogButton2}" \
    --icon "${dialogIcon}"
    dialogResult=$?
}

notifySuccess() {
    "${dialogPath}" \
    --title "Success!" \
    --width 600 --height 300 \
    --message "Your FileVault Key has been successfully updated!" \
    --timer 5 \
    --hidetimerbar
}

promptUser() {
    
    if [[ "${#1}" -ge 1 ]]; then
        dialogMessage="${dialogMsgWrongPass} (attempt "${@}" of 5)"
    fi
    if [ "$1" == "FORGOT_PASS" ]; then
        dialogMessage="${dialogMsgForgotPass}"
    fi

    pass=$("${dialogPath}" \
        --title "${dialogTitle}" \
        --message "${dialogMessage}" \
        --width 600 --height 300 \
        --timer "${dialogTimer}" \
        --hidetimerbar \
        --button1text "${dialogButton1}" \
        --textfield "Your Computer Password",secure,required \
        "${sec_button[@]}" \
        --icon "${dialogIcon}" \
        --ontop )       
    promptResults=$(echo "${pass}" | grep "Your Computer Password" | awk -F " : " '{print $NF}')
    echo "$promptResults"
}

promptError() {
    
    if [ -f "/System/Library/CoreServices/Diagnostics Reporter.app/Contents/Resources/AppIcon.icns" ]; then
        dialogIcon="/System/Library/CoreServices/Diagnostics Reporter.app/Contents/Resources/AppIcon.icns"
    elif [ -f "/System/Library/CoreServices/Problem Reporter.app/Contents/Resources/ProblemReporter.icns" ]; then
        dialogIcon="/System/Library/CoreServices/Problem Reporter.app/Contents/Resources/ProblemReporter.icns"
    fi
        
    pass=$("${dialogPath}" \
        --title "Error" \
        --width 600 --height 300 \
        --message "An error occurred, please contact support." \
        --timer "${dialogTimer}" \
        --hidetimerbar \
        --button1text "Ok" \
        --icon "${dialogIcon}" \
        --ontop )       
}


###########################
##### CALL FUNCTIONS ######
###########################

filevaultUserCheck
fdeRecoveryAgentCheck
notifyUser

if [ $dialogResult == "0" ]; then
    echo "User is proceeding"
    userPass=$(promptUser)
    TRY=1
    until /usr/bin/dscl /Search -authonly "$currentUser" "$userPass" &>/dev/null; do
        (( TRY++ ))
        echo "Prompting $currentUser for their Mac password (attempt $TRY)..."
        userPass=$(promptUser $TRY)
        if (( TRY >= 5 )); then
            userPass=$(promptUser FORGOT_PASS)
            exit 1
        fi
    done
    echo "Successfully prompted for Mac password."

elif [ $dialogResult == "2" ]; then
    echo "User deferred"
    exit 0
else
    exit 1
fi

echo "Issuing new recovery key..."
fdeSetupOutput="$(/usr/bin/fdesetup changerecovery -norecoverykey -verbose -personal -inputplist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Username</key>
    <string>$currentUser</string>
    <key>Password</key>
    <string>$userPass</string>
</dict>
</plist>
EOF
)"

# Test success conditions.
fdesetupResult=$?
echo "FDE Result: $fdesetupResult"

# Clear password variable.
unset userPass

# Differentiate <=10.12 and >=10.13 success conditions
if [[ "$osMajor" -eq 11 ]] || [[ "$osMajor" -eq 10 && "$osMinor" -ge 13 ]]; then
    # Check new modification time of of FileVaultPRK.dat
    escrowStatus=1
    if [ -e "/var/db/FileVaultPRK.dat" ]; then
        newPrkMod=$(/usr/bin/stat -f "%Sm" -t "%s" "/var/db/FileVaultPRK.dat")
        if [[ $newPrkMod -gt $PRK_MOD ]]; then
            escrowStatus=0
            echo "Recovery key updated locally and available for collection via MDM. (This usually requires two 'jamf recon' runs to show as valid.)"
        else
            echo "[WARNING] The recovery key does not appear to have been updated locally."
        fi
    fi
else
    # Check output of fdesetup command for indication of an escrow attempt
    echo "FDESetup Output: $fdeSetupOutput"
    /usr/bin/grep -q "Escrowing recovery key..." <<< "$fdeSetupOutput"
    escrowStatus=$?
fi

if [[ $fdesetupResult -ne 0 ]]; then
    [[ -n "$fdeSetupOutput" ]] && echo "$fdeSetupOutput"
    echo "[WARNING] fdesetup exited with return code: $fdesetupResult."
    promptError
    exit 1
elif [[ $escrowStatus -ne 0 ]]; then
    [[ -n "$fdeSetupOutput" ]] && echo "$fdeSetupOutput"
    echo "[WARNING] FileVault key was generated, but escrow cannot be confirmed. Please verify that the redirection profile is installed and the Mac is connected to the internet."
    notifySuccess
else
    [[ -n "$fdeSetupOutput" ]] && echo "$fdeSetupOutput"
    echo "Displaying \"success\" message..."
    notifySuccess
fi

###########################
#### INVENTORY UPDATE #####
###########################
jamf recon

exit 0