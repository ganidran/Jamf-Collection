#!/bin/bash

###########################
###### DIALOG CHECK #######
###########################

# Path to our dialog binary
dialogPath='/usr/local/bin/dialog'

# Check if the dialog exists
if [ -e "$dialogPath" ]
then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
    sleep 1
fi

###########################
####### RUN DIALOG ########
###########################

# Run dialog
dialogResults=$("${dialogPath}" \
--title "Information Needed" \
--message "Please help us determine the best experience for using your Mac by choosing your role below." \
--button1text "OK" \
--ontop \
--width 600 --height 300 \
--moveable \
--messageposition center \
--icon /usr/local/jamf/lvl-icon.png \
--selectvalues "Select One,Engineer,Non-Engineer" \
--selectdefault "Select One")

dialogIndex=$(echo "${dialogResults}" | grep "SelectedIndex" | awk -F ": " '{print $NF}')

if [ "$dialogIndex" == "1" ]; then
	echo "Engineer"
	#jamf recon -position "Engineer"
elif [ "$dialogIndex" == "2" ]; then
	echo "Non-Engineer"
	jamf policy -event demote_admin
    #jamf recon -position "Non-Engineer"
else
	echo "Nothing was chosen"
	exit 1
fi

exit 0