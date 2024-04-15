#!/bin/bash

# Frist requires a package to be deployed with the image along with desktoppr (https://github.com/scriptingosx/desktoppr)

###########################
###### SET VARIABLES ######
###########################

levelDesktop="/Library/Desktop Pictures/desktopImage.png"
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
