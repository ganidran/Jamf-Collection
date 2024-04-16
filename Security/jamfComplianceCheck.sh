#!/bin/bash

# Check compliance status of a device
complianceStatus=$(jamf checkJSSConnection)

# Check if the device is compliant
if [[ $complianceStatus == *"The system is compliant"* ]]; then
  echo "The device is compliant"
else
  echo "The device is not compliant"
fi
