#!/bin/bash

# Specify the IP address of the printer to check
printerIP="1.2.3.4"

# Check if the printer is installed
if lpstat -v | grep -q "$printerIP"; then
    result="Printer is installed"
else
    result="Printer is not installed"
fi

# Output the result in the format required by Jamf Pro extension attributes
echo "<result>$result</result>"
