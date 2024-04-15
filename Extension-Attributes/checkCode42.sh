#!/bin/bash

###########################
### DOES CODE42 EXIST? ####
###########################

if [[ -e "/Applications/Code42-AAT.app" ]]; then

    # Check for the app.log file
    appLog=""
    if [[ -e "/Library/Application Support/Code42-AAT/logs/app.log" ]]; then
        appLog="/Library/Application Support/Code42-AAT/logs/app.log"
    elif [[ -e "/Library/Application Support/Code42-AAT/Data/logs/app.log" ]]; then
        appLog="/Library/Application Support/Code42-AAT/Data/logs/app.log"
    fi

    # Check if app.log exists
    if [[ -n "$appLog" ]]; then
        # Extract username from app.log
        appLogUsername=$(grep -i "username" "$appLog" | tr '[:upper:]' '[:lower:]' | cut -f 2 -d ':' | cut -f 2 -d \")
        
        # Check if agent is deactivated
        code42AatRegline=$(grep -i "reported as Deactivated" "$appLog")
        
        if [[ -n "$appLogUsername" ]]; then
            if [[ -z "$code42AatRegline" ]]; then
                # Agent is registered and activated
                echo "<result>Installed and registered to: $appLogUsername</result>"
            else
                # Agent is registered but deactivated
                echo "<result>Installed, but deactivated</result>"
            fi
        else
            # Agent is not registered
            echo "<result>Installed, but unregistered</result>"
        fi
    else
        # App.log does not exist
        echo "<result>Installed, but log not found</result>"
    fi
else
    # Code42 app is not installed
    echo "<result>App not installed</result>"
fi
