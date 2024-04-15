#!/bin/bash

###########################
### CHECK IF INSTALLED ####
###########################

# Check if Homebrew is installed in /usr/local/bin
if command -v /usr/local/bin/brew &>/dev/null; then
  echo "<result>Installed</result>"
elif command -v /opt/homebrew/bin/brew &>/dev/null; then
  # Check if Homebrew is installed in /opt/homebrew/bin
  echo "<result>Installed</result>"
else
  echo "<result>Not Installed</result>"
fi
