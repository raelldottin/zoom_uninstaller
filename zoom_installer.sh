#!/usr/bin/env zsh
#
# Zoom installer using the Installomator submodule
#
./installomator/Installomator.sh label="zoomclient" DEBUG=0 NOTIFY=silent BLOCKING_PROCESS_ACTION=kill LOGO=jamf IGNORE_APP_STORE_APPS=yes INSTALL=force REOPEN=yes 
