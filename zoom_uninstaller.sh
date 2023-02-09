#!/usr/bin/env zsh
#
# Script to uninstall the Zoom client.
#
#
# Uninstall Zoom version 4.4.53932.0709 and higher
#
# Open the Zoom desktop application.
# Select zoom.us at the top of your screen and select Uninstall Zoom.
# Select OK to confirm uninstalling the Zoom desktop application and all of its components.
# Once completed, reinstall Zoom on our download center.
#
#
# Uninstall Zoom version 4.4.53909.0617 and below
#
# Open Finder.
# Select Go at the top of your screen.
# Select Go to Folder...
# Once opened, input ~/.zoomus/
# Move ZoomOpener to your trash.
# Once completed, repeat steps 3 through 5 for the following folders and files:
# Folder: /Applications/ Move to Trash: zoom.us.app
# Folder: ~/Applications/ Move to Trash: zoom.us.app
# Folder: /System/Library/Extensions/ Move to Trash: ZoomAudioDevice.kext
# Folder: ~/Library/Application\ Support/ Move to Trash: zoom.us
# Note: Zoom may not be installed in both the /Applications and ~/Applications folders.
# Once completed, download Zoom from our download center and reinstall. 
#
# Package receipts:
# us.zoom.pkg.videomeeting.plist
# us.zoom.pkg.videomeeting.bom -- ./zoom.us.app
# zoom.us.plist
# zoom.us.bom --  /Applications/zoom.us.app
#

# Checks if the first positional argument has a "/" discard the first three positional command line arguments
if [[ "$1" == "/" ]]; then
  echo "$0 is running from  Jamf shifting arguments"
  shift 3
fi

# Variable with command line help information
usage=(
    "$0 [-h|--help]"
    "$0 [-d|--dryrun]"
  )

# -D pulls parsed flags out of $@
# -E allows flags/args and positionals to be mixed, which we don't want in this example
# -F says fail if we find a flag that wasn't defined
# -M allows us to map option aliases (ie: h=flag_help -help=h)
# -K allows us to set default values without zparseopts overwriting them
# Remember that the first dash is automatically handled, so long options are -opt, not --opt
zmodload zsh/zutil
zparseopts -D -F -K -- {h,-help}=flag_help {d,-dryrun}=flag_dryrun || exit 1

# Print usage if help flag is provided
if [[ -n "$flag_help" ]]; then
  print -l $usage && exit 1
fi

# Print message informing of a dry run
if [[ -n "$flag_dryrun" ]]; then
  print "$0 is running in Dry Run Mode"
fi

# global variables
message=""
previous_message=""
timestamp=$(date -u +%F\ %T)
logrepeat=0
active_user=""

function get_active_user() {
    #	Collect current logged in user
    active_user=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')
}

function print_log() {
    #	Print a log message to standard output and system log
    message="${*}"
    timestamp=$(date -u +%F\ %T)

    get_active_user
    if [[ -z "${message}" ]]; then
      return
    elif [[ "${message}" == "${previous_message}" ]]; then
        ((logrepeat = logrepeat + 1))
        return
    elif [[ (${logrepeat} -gt 0) && ("${message}" != "${previous_message}") ]]; then
        echo "${timestamp}:${active_user}[$$] : Last message repeated {$logrepeat} times"
        logger -i "Last message repeated {$logrepeat} times"
        logrepeat=0
    elif [[ $logrepeat -eq 0 ]]; then
        echo "${timestamp}:${active_user}[$$] : ${message}"
        logger -i "${message}"
        previous_message="${message}"
    fi
}
function uninstall() {
  # Path to the files to delete
  artifact_paths=("/Applications/zoom.us.app" "/System/Library/Extensions/ZoomAudioDevice.kext" "/var/db/receipts/us.zoom.pkg.videmeeting.bom" "/var/db/receipts/us.zoom.pkg.videmeeting.plist" "/var/db/receipts/us.zoom.pkg.videomeeting.bom" "/var/db/receipts/us.zoom.pkg.videomeeting.plist")
  # Name of the binaries to terminate
  artifact_binaries=("[z]oom.us")

  # Process to terminate active binaries
  for artifact in $artifact_binaries; do
    for pid in $(ps -axo pid,args | grep -i "$artifact" | awk '{print $1}'); do
      print_log "Terminating $artifact process: $pid"
      kill -9 "$pid"
    done
  done

  # Process to delete files
  for artifact in $artifact_paths; do
    if [[ -e "$artifact" ]]; then
      if [[ ! -w "$artifact" ]]; then
        print_log "No access unable to delete $artifact"
      else
          print_log "Deleting $artifact"
        if [[ -z "$flag_dryrun" ]]; then
          rm -fr "$artifact"
        fi
      fi
    else
      print_log "$artifact doesn't exists"
    fi
  done
}

function main() {
  # Main function to control program flow
  uninstall
  print_log
}

# Runs program onluy
if [[ "${(%):-%N}" -ef "$0" ]]; then
  main
fi
