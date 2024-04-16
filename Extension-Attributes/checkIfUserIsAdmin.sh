#!/bin/bash

#Find the current user
username=$(stat -f "%Su" /dev/console)

###########################
##### CHECK IF ADMIN ######
###########################

# Check if the logged-in user is an administrator
if dseditgroup -o checkmember -m "$username" admin &>/dev/null
then 
    echo "<result>`True`</result>"
else 
    echo "<result>`False`</result>"
fi

exit 0
