#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

dialogPath="/usr/local/bin/dialog"
libPath="/Library/Preferences/SystemConfiguration"
networkDir="/private/var/tmp/networkPlists"

###########################
##### DO THE THINGS #######
###########################

# Install dialog
jamf policy -event install-swiftdialog

# Create folder if not already existing
if [ ! -d "$networkDir" ]; then
    mkdir -p "$networkDir"
fi

# Copy the plist files
echo "Copying plist files to $networkDir just in case"
cp "$libPath/com.apple.airport.preferences.plist" "$networkDir"
cp "$libPath/com.apple.network.eapolclient.configuration.plist" "$networkDir"
cp "$libPath/com.apple.wifi.message-tracer.plist" "$networkDir"
cp "$libPath/NetworkInterfaces.plist" "$networkDir"
cp "$libPath/preferences.plist" "$networkDir"

# Get the Wi-Fi interface name
wifiDevice=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort|Wireless/{getline; print $2}')

if [[ -z $wifiDevice ]]; then
  echo "Wi-Fi interface not found."
  exit 1
fi

# Turn off Wi-Fi
networksetup -setairportpower "$wifiDevice" off
echo "Wi-Fi turned off."

# Remove the plist files
echo "Removing existing plist files"
rm -f "$libPath/com.apple.airport.preferences.plist"
rm -f "$libPath/com.apple.network.eapolclient.configuration.plist"
rm -f "$libPath/com.apple.wifi.message-tracer.plist"
rm -f "$libPath/NetworkInterfaces.plist"
rm -f "$libPath/preferences.plist"

# Restart input window
echo "Prompting user to restart"
"$dialogPath" \
--width 600 --height 300 \
--button1text "Restart Now" \
--ontop \
--title "Setup Complete" \
--timer 120 \
--message "Your computer has finished its network reset and requires a restart." \
--icon /usr/local/jamf/company-icon.png
dialogResults=$?

    # User input
    if [ "$dialogResults" = "0" ]; then
        echo "User chose to Restart. Restarting..."
        shutdown -r +1 &
        "$dialogPath" \
        --width 400 --height 200 \
        --ontop \
        --title "Restarting" \
        --timer 60 \
        --message "Your computer will restart in:" \ &
    elif [ "$dialogResults" = "4" ]; then
        echo "Timer finished without user input. Restarting..."
        shutdown -r +1 &
        "$dialogPath" \
        --width 400 --height 200 \
        --ontop \
        --title "Restarting" \
        --timer 60 \
        --message "Your computer will restart in:" \ &
    fi
