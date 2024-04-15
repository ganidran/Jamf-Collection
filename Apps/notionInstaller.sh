#!/bin/bash

###########################
#### NOTION INSTALLER #####
###########################

# Determine the hardware architecture and set the download URL accordingly
if [[ "$(uname -p)" == "arm" ]]; then
    echo "Apple Silicon Mac"
    # URL for ARM architecture (Apple Silicon)
    notionURL="https://www.notion.so/desktop/apple-silicon/download"  
else
    echo "Intel Mac"
    # URL for other architectures (e.g., Intel)
    notionURL="https://www.notion.so/desktop/mac/download"           
fi

# Download and install Notion
curl -L "$notionURL" -o /tmp/notion.dmg  

# Attach (mount) the DMG file as a virtual disk
hdiutil attach /tmp/notion.dmg           

# Copy the Notion application to the /Applications/ directory
cp -R "/Volumes/Notion/Notion.app" /Applications/

# Set ownership and permissions for the installed Notion application
chown -R root:wheel "/Applications/Notion.app"  
chmod -R 775 "/Applications/Notion.app"

# Detach (unmount) the virtual disk
hdiutil detach "/Volumes/Notion/"

# Clean up temporary files
rm /tmp/notion.dmg

# Print a message indicating the successful installation of Notion
echo "Finished installing $(uname -p) version of Notion"

exit 0
