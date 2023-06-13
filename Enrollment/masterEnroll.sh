#!/bin/bash

###########################
####### SETUP CHECK #######
###########################

# Run script after macOS setup assistant
while pgrep -x "Setup Assistant" > /dev/null
do
    sleep 5
done
echo "
--Initial macOS setup complete.--
"

###########################
###### SET VARIABLES ######
###########################

# Dialog path
dialogPath="/usr/local/bin/dialog"
# Grab logged-in user
currentUser=$(stat -f "%Su" /dev/console)

###########################
#### GRAB USER'S NAME #####
###########################

# Get the full name
userFull=$(dscl . -read /Users/"$currentUser" RealName | tr -d '\n' | sed 's/RealName: //')
# Get the first name
userFirst=$(echo "$userFull" | cut -d " " -f 1)
echo "
--Grabbing first name of logged in user: '$userFirst'--
"

###########################
##### SYSTEM CHECKS #######
###########################

# Check if Level images exist
if [ -e "/usr/local/jamf/lvl-icon.png" ]
then
    echo "
    --Level images exist. Proceeding...--
    "
else
    echo "
    --Level images don't exist. Installing...--
    "
    jamf policy -event install-level-images
fi

# Check if the dialog exists
if [ -e "$dialogPath" ]
then
    echo "
    --swiftDialog exists. Re-installing...--
    "
    jamf policy -event install-swiftdialog
else
    echo "
    --swiftDialog does not exist. Installing...--
    "
    jamf policy -event install-swiftdialog
fi

# Lag time for system to run
sleep 15

###########################
## DO ENROLLMENT THINGS ###
###########################

echo "
----START----
"

# Full screen window
echo "
--Placing fullscreen dialog window--
"
$"$dialogPath" \
--blurscreen \
--quitkey l \
--width 600 --height 300 \
--button1text "Installing..." \
--button1disabled \
--title "W E L C O M E    T O    L E V E L" \
--message "Welcome to Level $userFirst! \n\nYour computer is downloading necessary policies and will restart once it's complete. \n\n**Please** plug in the charger to avoid the computer from shutting down." \
--messagefont size=18 \
--icon /usr/local/jamf/lvl-icon.png &

# Lag time
echo "
--Finishing initial installions--
"
sleep 120

# Install EPP
if [ -e /Applications/EndpointProtectorClient.app ]
then
    echo "
    --Endpoint Protector exists--
    "
else
    echo "
    --Endpoint Protector does not exist. Installing...--
    "
    jamf policy -event install_endpoint_protector 
    sleep 0.5
fi

# Install Chrome
if [ -e /Applications/Google\ Chrome.app ]
then
    echo "
    --Google Chrome exists--
    "
else
    echo "
    --Google Chrome does not exist. Installing...--
    "
    jamf policy -event install_google_chrome
    sleep 0.5
fi

# Install Zoom
if [ -e /Applications/zoom.us.app ]
then
    echo "
    --Zoom exists--
    "
else
    echo "
    --Zoom does not exist. Installing...--
    "
    jamf policy -event installzoom
    sleep 0.5
fi

# Set Desktop
jamf policy -event set-desktop
sleep 0.5
echo "--Desktop set--
"

# Set Default Apps
jamf policy -event set-apps
sleep 0.5
echo "
--Default apps set--
"

# Set Dock
jamf policy -event set-dock
sleep 0.5
echo "
--Dock set--
"

# Restart input window
echo "
--Prompting user to restart--
"
$"$dialogPath" \
--width 600 --height 300 \
--button1text "Restart" \
--button2text "Onboarding" \
--ontop \
--title "Setup Complete" \
--timer 120 \
--message "Almost there $userFirst! Your computer has finished its setup and requires a restart. \n\nPlease restart your computer unless you're onboarding with IT." \
--icon /usr/local/jamf/lvl-icon.png
dialogResults=$?

    # User input
    if [ "$dialogResults" == "0" ]; then
        echo "
        --User chose to Restart. Restarting...--
        "
        shutdown -r +1 &
        $"$dialogPath" \
        --width 400 --height 200 \
        --ontop \
        --title "Restarting" \
        --timer 60 \
        --message "Your computer will restart in:" \ &
    elif [ "$dialogResults" == "4" ]; then
        echo "
        --Timer finished without user input. Restarting...--
            "
        shutdown -r +1 &
        $"$dialogPath" \
        --width 400 --height 200 \
        --ontop \
        --title "Restarting" \
        --timer 60 \
        --message "Your computer will restart in:" \ &
    else
        echo "
        --Restart aborted. User chose 'Onboarding'--
        "
        exit 0
    fi

echo "
----FIN----
"
exit 0
