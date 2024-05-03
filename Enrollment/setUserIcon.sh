#!/bin/bash

###########################
###### SET VARIABLES ######
###########################

# Get the current user
currentUser=$(stat -f "%Su" /dev/console) 
# Path to the new picture (Level user icon) 
userIcon="/usr/local/jamf/<icon-file-name>.png"  

###########################
####### DO THE DEW ########
###########################

# Delete the current user's existing user icon
dscl . delete /Users/"$currentUser" JPEGPhoto

# Set the new picture as the user icon for the current user
dscl . create Users/"$currentUser" Picture "$userIcon"
