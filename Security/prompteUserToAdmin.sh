#!/bin/bash

###########################
###### SET VARIABLE #######
###########################

userName=$(stat -f "%Su" /dev/console)

###########################
###### DO THE THINGS ######
###########################

if [ $userName == "root" ]; then
	echo "root user can't be removed"
else
dscl . -read /Users/$userName GeneratedUID
cmdResults=$?
echo "Result: $cmdResults"
	
	if [  $cmdResults == "0" ]; then
		GeneratedUID=`dscl . -read /Users/$userName GeneratedUID | awk '{print $2}'`
		echo "Adding: $GeneratedUID"
		
		dscl . -append /Groups/admin GroupMembers "$GeneratedUID"
	fi
	
echo "Adding: $userName"
dscl . -append /Groups/admin GroupMembership "$userName"
fi

exit 0
