#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Get the list of active network devices from scutil
activeNetwork=$(/usr/sbin/scutil --nwi | awk -F': ' '/Network interfaces:/{print $NF}')

###########################
##### DO THE THINGS #######
###########################

# Loop over the list of active network devices
for device in $(printf '%s\n' "$activeNetwork"); do
	if [[ ! "$device" =~ "utun" ]]; then
		## Get the name of the port associated with the device id, such as "Wi-Fi"
		portName=$(/usr/sbin/networksetup -listallhardwareports | grep -B1 "$device" | awk -F': ' '/Hardware Port:/{print $NF}')
    	## Add that name into an array
    	portNames+=("$portName")
	fi
done

# Print back the array as the returned value
echo "<result>$(printf '%s\n' "${portNames[@]}")</result>"
