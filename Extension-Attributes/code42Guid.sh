#!/bin/bash

# Check for the app.log file
appLog=""
if [[ -e "/Library/Application Support/Code42-AAT/logs/app.log" ]]; then
	appLog="/Library/Application Support/Code42-AAT/logs/app.log"
elif [[ -e "/Library/Application Support/Code42-AAT/Data/logs/app.log" ]]; then
	appLog="/Library/Application Support/Code42-AAT/Data/logs/app.log"
fi

# Check if app.log exists
if [[ -f "$appLog" ]]; then
	# Extract the "guid" value from the JSON in app.log
	deviceGuid=$(grep -o '"guid": "[^"]*' "$appLog" | awk -F'"' '{print $4}')

	# Check if deviceGuid is not empty
	if [[ -n "$deviceGuid" ]]; then
    	echo "<result>$deviceGuid</result>"
	else
    	# If deviceGuid is empty, print an error message
    	echo "<result>GUID not found in app.log</result>"
	fi
else
	# App.log does not exist
	echo "<result>App.log not found</result>"
fi
