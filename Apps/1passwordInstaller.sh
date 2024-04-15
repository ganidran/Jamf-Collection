#!/bin/bash

###########################
##### SET VARIABLES #######
###########################

# Paths to the folders and files to be deleted
supportFolder="$HOME/Library/Application Support/"
preferencesFolder="$HOME/Library/Preferences/"
containersFolder="$HOME/Library/Containers/"
groupContainersFolder="$HOME/Library/Group Containers/"
# Define latest 1Pass download URL and the output file name
downloadURL="https://downloads.1password.com/mac/1Password.pkg"
outputFile="1Password.pkg"

###########################
##### DO THE THINGS #######
###########################

# Check if 1Password 7 exists
if [ -e /Applications/1Password\ 7.app ]; then
    # 1Password 7 exists, remove it
    echo "1Password 7 Exists, removing..."
    # Quit the app just in case
    osascript -e 'quit app "1Password 7"'
    # Function to delete a folder if it exists
    deleteFolder() {
        if [ -d "$1" ]; then
            rm -rf "$1"
        fi
    }

    # Function to delete a file if it exists
    deleteFile() {
        if [ -e "$1" ]; then
            rm -f "$1"
        fi
    }

    # Delete folders and files related to 1Password
    deleteFolder "${supportFolder}1Password*"
    deleteFile "${preferencesFolder}com.agilebits*"
    deleteFolder "${containersFolder}com.agilebits*"
    deleteFolder "${containersFolder}1Password*"
    deleteFolder "${groupContainersFolder}2BUA8C4S2C.com.agilebits*"
    deleteFolder "${groupContainersFolder}2BUA8C4S2C.com.1password*"
else
  # 1Password 7 does not exist, so echo an error message
  echo "1Password 7 does not exist. Continuing..."
fi

# Define the URL of the package to download
echo "Installing 1Password package..."
downloadURL="https://downloads.1password.com/mac/1Password.pkg"

# Define the path where you want to save the downloaded package
outputFile="/tmp/1Password.pkg"

# Download the package in the background using curl
curl -o "$outputFile" "$downloadURL" &

# Get the process ID of the curl command
curlPID=$!

# Wait for the download to complete
wait $curlPID

# Install the package silently using installer
sudo installer -pkg "$outputFile" -target /

# Check the exit status of the installer command
if [ $? -eq 0 ]; then
    echo "Installation completed successfully."
else
    echo "Installation failed."
fi

# Clean up by removing the downloaded package
rm -f "$outputFile"

# Run an inventory check
jamf recon

# Exit the script
exit 0
