#!/bin/bash

# Nodified script from Elliot Jordan's guide found here: https://github.com/homebysix/jss-filevault-reissue

###########################
##### SET VARIABLES #######
###########################

# The title of the message that will be displayed to the user.
# Not too long, or it'll get clipped.
promptTitle="Attention Required!"

# The body of the message that will be displayed before prompting the user for
# their password. All message strings below can be multiple lines.
promptMessage="Howdy folks! Your Mac's FileVault encryption key needs to be escrowed by IT.

Click the Next button below, then enter your Mac's password when prompted."

# The body of the message that will be displayed after 5 incorrect passwords.
forgotPwMessage="You made five incorrect password attempts.

Please contact IT for help with your Mac password."

# The body of the message that will be displayed after successful completion.
successMessage="Thank you! Your FileVault key is updated."

# The body of the message that will be displayed if a failure occurs.
failMessage="Sorry, an error occurred while escrowing your FileVault key. Please contact IT for help."

###########################
###### VALIDATIONS ########
###########################

# Suppress errors for the duration of this script. (This prevents JAMF Pro from
# marking a policy as "failed" if the words "fail" or "error" inadvertently
# appear in the script output.)
exec 2>/dev/null

bailOut=false

# Bail out if jamfHelper doesn't exist.
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
if [[ ! -x "$jamfHelper" ]]; then
    reason="jamfHelper not found."
    bailOut=true
fi

# Most of the code below is based on the JAMF reissueKey.sh script:
# https://github.com/jamf/FileVault2_Scripts/blob/master/reissueKey.sh

# Check to see if the encryption process is complete
fvStatus="$(/usr/bin/fdesetup status)"
if /usr/bin/grep -q "Encryption in progress" <<< "$fvStatus"; then
    reason="FileVault encryption is in progress. Please run the script again when it finishes."
    bailOut=true
elif /usr/bin/grep -q "FileVault is Off" <<< "$fvStatus"; then
    reason="Encryption is not active."
    bailOut=true
elif ! /usr/bin/grep -q "FileVault is On" <<< "$fvStatus"; then
    reason="Unable to determine encryption status."
    bailOut=true
fi

# Get the logged in user's name
currentUser=$(stat -f "%Su" /dev/console)

# Make sure there's an actual user logged in
if [[ -z $currentUser || "$currentUser" == "loginwindow" || "$currentUser" == "root" ]]; then
    reason="No user is currently logged in."
    bailOut=true
else
    # Make sure logged in account is already authorized with FileVault 2
    fvUsers="$(/usr/bin/fdesetup list)"
    if ! /usr/bin/grep -E -q "^${currentUser}," <<< "$fvUsers"; then
        reason="$currentUser is not on the list of FileVault enabled users: $fvUsers"
        bailOut=true
    fi
fi

###########################
##### MAIN PROCESS ########
###########################

# Validate logo file. If no logo is found, download it
if [ -e "/usr/local/jamf/company-icon.png" ]
then
    echo "
    --Company images exist. Proceeding...--
    "
else
    echo "
    --Company images don't exist. Installing...--
    "
    jamf policy -event install-company-images
fi
# Set logo path
companyLogo="/usr/local/jamf/company-icon.png"

# Convert POSIX path of logo icon to Mac path for AppleScript.
logoPosix="$(/usr/bin/osascript -e 'return POSIX file "'"$companyLogo"'" as text')"

# Get information necessary to display messages in the current user's context.
# Using both `launchctl` and `sudo -u` per this example: https://scriptingosx.com/2020/08/running-a-command-as-another-user/
userId=$(/usr/bin/id -u "$currentUser")
lId=$userId
lMethod="asuser"

# If any error occurred in the validation section, bail out.
if [[ "$bailOut" == "true" ]]; then
    echo "[ERROR]: $reason"
    launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$failMessage: $reason" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
    exit 1
fi

# Display a branded prompt explaining the password prompt.
echo "Alerting user $currentUser about incoming password prompt..."
/bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$promptMessage" -button1 "Next" -defaultButton 1 -startlaunchd &>/dev/null

# Get the logged in user's password via a prompt.
echo "Prompting $currentUser for their Mac password..."
userPass="$(/bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" /usr/bin/osascript -e 'display dialog "Please enter the password you use to log in to your Mac:" default answer "" with title "'"${promptTitle//\"/\\\"}"'" giving up after 86400 with text buttons {"OK"} default button 1 with hidden answer with icon file "'"${logoPosix//\"/\\\"}"'"' -e 'return text returned of result')"

# Thanks to James Barclay (@futureimperfect) for this password validation loop.
try=1
until /usr/bin/dscl /Search -authonly "$currentUser" "$userPass" &>/dev/null; do
    (( try++ ))
    echo "Prompting $currentUser for their Mac password (attempt $try)..."
    userPass="$(/bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" /usr/bin/osascript -e 'display dialog "Sorry, that password was incorrect. Please try again:" default answer "" with title "'"${promptTitle//\"/\\\"}"'" giving up after 86400 with text buttons {"OK"} default button 1 with hidden answer with icon file "'"${logoPosix//\"/\\\"}"'"' -e 'return text returned of result')"
    if (( try >= 5 )); then
        echo "[ERROR] Password prompt unsuccessful after 5 attempts. Displaying \"forgot password\" message..."
        /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$forgotPwMessage" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
        exit 1
    fi
done
echo "Successfully prompted for Mac password."

# If needed, unload and kill FDERecoveryAgent.
if /bin/launchctl list | /usr/bin/grep -q "com.apple.security.FDERecoveryAgent"; then
    echo "Unloading FDERecoveryAgent LaunchDaemon..."
    /bin/launchctl unload /System/Library/LaunchDaemons/com.apple.security.FDERecoveryAgent.plist
fi
if pgrep -q "FDERecoveryAgent"; then
    echo "Stopping FDERecoveryAgent process..."
    killall "FDERecoveryAgent"
fi

# Translate XML reserved characters to XML friendly representations.
userPass=${userPass//&/&amp;}
userPass=${userPass//</&lt;}
userPass=${userPass//>/&gt;}
userPass=${userPass//\"/&quot;}
userPass=${userPass//\'/&apos;}

# For 10.13's escrow process, store the last modification time of /var/db/FileVaultPRK.dat
if [ -e "/var/db/FileVaultPRK.dat" ]; then
    echo "Found existing personal recovery key."
    prkMod=$(/usr/bin/stat -f "%Sm" -t "%s" "/var/db/FileVaultPRK.dat")
fi

echo "Issuing new recovery key..."
fdesetupOutput="$(/usr/bin/fdesetup changerecovery -norecoverykey -verbose -personal -inputplist << EOF
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

# Clear password variable.
unset userPass

# Check new modification time of of FileVaultPRK.dat
escrowStatus=1
if [ -e "/var/db/FileVaultPRK.dat" ]; then
    newPrkMod=$(/usr/bin/stat -f "%Sm" -t "%s" "/var/db/FileVaultPRK.dat")
    if [[ $newPrkMod -gt $prkMod ]]; then
        escrowStatus=0
        echo "Recovery key updated locally and available for collection via MDM. (This usually requires two 'jamf recon' runs to show as valid.)"
    else
        echo "[WARNING] The recovery key does not appear to have been updated locally."
    fi
fi

if [[ $fdesetupResult -ne 0 ]]; then
    [[ -n "$fdesetupOutput" ]] && echo "$fdesetupOutput"
    echo "[WARNING] fdesetup exited with return code: $fdesetupResult."
    echo "See this page for a list of fdesetup exit codes and their meaning:"
    echo "https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/fdesetup.8.html"
    echo "Displaying \"failure\" message..."
    /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$failMessage: fdesetup exited with code $fdesetupResult. Output: $fdesetupOutput" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
elif [[ $escrowStatus -ne 0 ]]; then
    [[ -n "$fdesetupOutput" ]] && echo "$fdesetupOutput"
    echo "[WARNING] FileVault key was generated, but escrow cannot be confirmed. Please verify that the redirection profile is installed and the Mac is connected to the internet."
    echo "Displaying \"failure\" message..."
    /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$failMessage: New key generated, but escrow did not occur." -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
else
    [[ -n "$fdesetupOutput" ]] && echo "$fdesetupOutput"
    echo "Displaying \"success\" message..."
    /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$successMessage" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
fi

###########################
#### INVENTORY CHECK ######
###########################

jamf recon

exit $fdesetupResult
