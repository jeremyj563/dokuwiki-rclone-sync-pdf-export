#! /bin/bash

# Script Name: rclone-sync.sh
# Author: Jeremy Johnson
# Date Created: 3/6/2019
# Date Updated: 4/17/2019
#
# Purpose: Sync the data folder of DokuWiki to Google Drive.
#          Notify the administrator if the sync fails.
#
# Dependencies: rclone by Nick Craig-Wood (https://github.com/ncw/rclone)
#
# Exit Codes:   0 = success
#               1 = rclone already running
#               2 = rclone sync failed

# IMPORTS
source ~/scripts/vars.sh
source ~/scripts/logfunctions.sh

# FUNCTIONS
function ExitScript {
    local exitCode=$1

    # Append current job to log
    tee -a "$logPath/$log" < "$logPath/$logLastTask"
    rm "$logPath/$logLastTask"

    # Sync process ends here
    WriteLogEvent "END"

    # Copy log to DokuWiki "pages" folder to be viewable at: https://dokuwiki.example.com/doku.php?id=information:dokuwiki:rclone-sync
    cp "$logPath/$log" "$dokuwikiLogPath/"

    # Check the exit code and notify appropriately
    if (($exitCode == 0)); then
        WriteLog "[$scriptName] completed successfully"
    else
        # On error log and email the exit code.
        message="[$scriptName] encountered an error - exit code: $1"
        WriteLog "$message"
        printf "%s" "$message" | mail -r $mailFrom -s "$message" $mailTo1 $mailTo2
    fi

    exit "$exitCode"
}

# MAIN SCRIPT
if ! LogLastModifiedToday; then
    # Log file is not from today so archive it
    mv "$logPath/$log" "$logArchivePath/$log.$logDate"
fi

if pgrep -x "rclone" > /dev/null; then
    # rclone is currently running so call exit function which will also send an email notification
    ExitScript 1
fi

# Sync process starts here
WriteLogEvent "BEGIN"

# Run sync command up to $maxAttempts times
maxAttempts=3
for ((n=1;n<($maxAttempts+1);n++)); do
    WriteLog "Sync attempt: $n of $maxAttempts"

    # Actual command to sync DokuWiki "data" folder to Google Drive - dokuwiki@example.com
    if rclone sync --quiet --size-only --no-update-modtime --exclude-if-present .ignore --drive-use-trash=false --fast-list --log-file "$logPath/$logLastTask" $dokuwikiPath remote:data; then
        exitCode=0
        break
    else
        exitCode=2
    fi

    # Wait for 60 seconds in between attempts
    sleep 60
done

# EOF
ExitScript $exitCode
