#!/bin/bash

# Get the major version using cut
majorVersion=$(sw_vers -productVersion | cut -d '.' -f1)

# Print the major version
echo "$majorVersion"

# Check if the major version is greater than or equal to 13
if [[ "$majorVersion" -ge 13 ]]; then
  echo "OS version is 13 or greater"
  # Add your commands here to handle older OS versions
else
  echo "OS version is less than 13"
fi
