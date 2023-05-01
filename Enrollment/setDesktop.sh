#!/bin/bash

###########################
###### SET VARIABLES ######
###########################

levelDesktop="/Library/Desktop Pictures/levelDesktop.png"
desktoppr="/usr/local/bin/desktoppr"
loggedInUser=$(stat -f "%Su" /dev/console)
uid=$(id -u "$loggedInUser")

###########################
###### DO THE THINGS ######
###########################

# Set the desktop
launchctl asuser "$uid" "$desktoppr" "$levelDesktop"

# Cleanup
sleep 1
rm -r /usr/local/bin/desktoppr
