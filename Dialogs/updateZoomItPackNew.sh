#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Dialog variableß
dialogPath="/usr/local/bin/dialog"
dialogTitle="Zoom Update"
dialogButton1=""
dialogButton2=""
dialogMessage=""
dialogTimer="900"

###########################
##### SYSTEM CHECKS #######
###########################

# Check if the dialog exists
if [ -e "$dialogPath" ]
then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
    sleep 2
fi

###########################
###### SET FUNCTION #######
###########################

promptUser(){
	if [[ "${#1}" -ge 1 ]]; then
		button2=("--button2text" "${dialogButton2}")
	fi

	"${dialogPath}" \
	--title "${dialogTitle}" \
	--message "${dialogMessage}" \
	--timer "${dialogTimer}" \
	--button1text "${dialogButton1}" \
	"${button2[@]}" \
	--hidetimerbar \
	--ontop \
	--width 600 --height 250 \
	--moveable \
	--messagefont size=16 \
	--messageposition center \
	--icon /Applications/zoom.us.app/Contents/Resources/ZPLogo.icns

	echo "$?"
}

###########################
##### DO THE THINGS #######
###########################

zoomType=$(defaults read /Applications/zoom.us.app/Contents/Info ZITPackage)
if [ "$zoomType" == "1" ]; then
	dialogMessage="Your Zoom app is already updated with the latest version from the Level IT team.\n\nDo you want to reinstall Zoom?"
	dialogButton1="No. Exit the installer."
	dialogButton2="Yes. Reinstall Zoom"
	reinstallZoom=$(promptUser "1") 
	echo "$reinstallZoom"
	if [ "$reinstallZoom" == "0" ]; then
 		echo "Exiting Installer"
		exit 0
	else
        echo "Reinstalling Zoom..."
        dialogMessage="Please wait while Zoom is reinstalled..."
        dialogButton1="OK"
        dialogTimer="30"
        promptUser
        jamf policy -event updatezoomit

        dialogMessage="The Zoom update is complete!"
        dialogButton1="OK"
        promptUser
	fi		
	else
		dialogMessage="This will start the Zoom update process and immediately close Zoom if it is open.\n\nDo you want to continue?"
		dialogButton1="Yes. Update Zoom."
		dialogButton2="No. Exit the installer."
		zoomUpdate=$(promptUser "1")
		echo "$zoomUpdate"
		if [ "$zoomUpdate" == "2" ]; then
			exit 1
			else
				echo "Updating Zoom..."
				dialogMessage="Please wait while Zoom is updated..."
				dialogTimer="30"
				dialogButton1="OK"
				promptUser
				jamf policy -event updatezoomit

				dialogMessage="The Zoom update is complete!"
				promptUser
		fi		
fi

exit 0