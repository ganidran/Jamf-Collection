#!/bin/bash

###########################
#### SPOTIFY INSTALLER ####
###########################

# Determine the hardware architecture and set the download URL accordingly
if [[ "$(uname -p)" == "arm" ]]; then
    echo "Apple Silicon Mac"
    # URL for ARM architecture (Apple Silicon)
    spotifyURL="https://download.scdn.co/SpotifyARM64.dmg"  
else
    echo "Intel Mac"
    # URL for other architectures (e.g., Intel)
    spotifyURL="https://download.scdn.co/Spotify.dmg"       
fi

# Download and install Spotify
curl -L "$spotifyURL" -o /tmp/spotify.dmg  

# Attach (mount) the DMG file as a virtual disk
hdiutil attach /tmp/spotify.dmg           

# Copy the Spotify application to the /Applications/ directory
cp -R /Volumes/Spotify/Spotify.app /Applications/

# Set ownership and permissions for the copied Spotify application
chown -R root:wheel /Applications/Spotify.app  
chmod -R 755 /Applications/Spotify.app         

# Detach (unmount) the virtual disk
hdiutil detach /Volumes/Spotify/

# Clean up temporary files
rm /tmp/spotify.dmg

# Print a message indicating the successful installation of Spotify
echo "Finished installing $(uname -p) version of Spotify"

exit 0
