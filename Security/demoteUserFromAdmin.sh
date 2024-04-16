#!/bin/bash

# This will demote the current user if it is not admin
currentUser=$(ls -l /dev/console | awk '{ print $3 }')
echo "current user is $currentUser"

###########################
###### DEMOTE ADMIN #######
###########################

# Check if current user is admin
currentUser=$(ls -l /dev/console | awk '{ print $3 }')
echo "Current user is $currentUser"

# Skips the companyadmin account that is installed at enrollment
if [[ $currentUser != "companyadmin" ]]; then
  # Check if current user is admin
  if id -Gn $currentUser | grep -q -w "admin"; then
    # Demote user from admin
    /usr/sbin/dseditgroup -o edit -n /Local/Default -d $currentUser -t "user" "admin"
    echo "Demoted $currentUser from admin"
  else
    echo "$currentUser is not a local admin"
  fi
fi

exit 0
