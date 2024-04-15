#!/bin/bash

# Create a temporary folder
tempDir=$(mktemp -d)
cd "$tempDir"

# Define the URL for the latest version of Google Chrome
chromeUrl="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"

# Define the file name for the downloaded package
chromeFile="googlechrome.pkg"

# Download the latest version of Google Chrome
echo "Downloading Google Chrome..."
curl -L -O "$chromeUrl"

# Install Google Chrome from the downloaded package
echo "Installing Google Chrome..."
installer -pkg "$chromeFile" -target /

# Clean up the downloaded package
rm "$chromeFile"

# Return to the original working directory
cd -

# Remove the temporary folder
rm -r "$tempDir"

echo "Google Chrome has been installed successfully."
