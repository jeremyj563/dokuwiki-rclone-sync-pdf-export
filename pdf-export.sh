#! /bin/bash

# Script Name: pdf-export.sh
# Author: Jeremy Johnson
# Date Created: 5/23/2018
# Date Updated: 3/7/2019
#
# Purpose: Export every DokuWiki page into PDF and store in a
#          folder structure that matches the wiki layout.
#
# Dependencies: cURL by Daniel Stenberg (https://curl.haxx.se)
#               DW2PDF Plugin by Andreas Gohr (https://github.com/splitbrain/dokuwiki-plugin-dw2pdf)
#
# Exit Codes:   0 = success
#               1 = kerberos ticket verification failed
#               2 = curl download failed

# IMPORTS
source ~/scripts/vars.sh
source ~/scripts/logfunctions.sh

# FUNCTIONS
function CreatePagesList {
    local searchPath=$1 # The path to begin searching
    local outputPath=$2 # The output file for the list

    # Create a list of pages formatted to match the namespaces in dokuwiki
    WriteLog "Creating list of pages"
    find "$searchPath" -type f -printf "%P\\n" -name "*.txt" | sed "s/\\//:/g;s/.txt//g" | tee "$outputPath" | tee -a "$logPath/$log"
}

function DownloadPage {
    local url=$1 # The base url to download from
    local uri=$2 # The uri that identifies the resource to download
    local path=$3 # The export path

    # Use cURL to download a page from the dokuwiki site
    # cURL authenticates using the Kerberos apache module
    WriteLog "Downloading page - $uri"
    if ! curl -k --negotiate -u : "$url" -d "id=$uri&do=export_pdf" -o "$path/${2##*:}".pdf 2>&1 | tee -a "$logPath/$log"; then
        # En error is encountered during cURL download so abort
        ExitScript 2
    fi
    printf "\\n" | tee -a "$logPath/$log"
}

function ExitScript {
    local exitCode=$1

    # Revoke Kerberos ticket
    WriteLog "Destroying Kerberos cache"
    kdestroy

    # Export process ends here
    WriteLogEvent "END"

    # Copy log to DokuWiki folder to be viewable at:
    # https://dokuwiki.example.com/doku.php?id=information:dokuwiki:pdf-export
    cp "$logPath/$log" "$dokuwikiLogPath"/

    # Check the exit code and notify accordingly
    if (($exitCode == 0)); then
        WriteLog "[$scriptName] completed successfully"
    else
        # On error log and email the exit code
        message="[$scriptName] encountered an error - exit code: $exitCode"
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

# Export process starts here
WriteLogEvent "BEGIN"

# Request a new Kerberos ticket
WriteLog "Requesting Kerberos ticket"
kinit dokusso@EXAMPLE.COM -kt /etc/dokusso.keytab

# Verify Kerberos ticket was received
WriteLog "Verifying Kerberos environment"
if ! klist | tee -a "$logPath/$log"; then
    # Kerberos ticket not received so abort
    ExitScript 1
fi

# Delete previous export
WriteLog "Deleting previous export"
exportPath="$dokuwikiPath/pdf"
rm -rf ${exportPath:?}/*

# Create a formatted list of all the pages found in the dokuwiki folder
pagesList="$workingPath/tmp/pageslist.txt"
CreatePagesList "$dokuwikiPath/pages" "$pagesList"

# Loop through the pages list. Each line in the list is a page
while read -r pageUri; do

    # Build the path to export each page to
    buildPath=$exportPath
    IFS=':' read -ra DIRS <<< "$pageUri" # Split uri string and store in array
    for dir in "${DIRS[@]::${#DIRS[@]}-1}"; do # Loop through all but the last element (filename)
        buildPath+=/$dir # Concatenate namespaces to build each export path
    done

    # Create folder only if it doesn't already exist
    WriteLog "Creating folder - $buildPath"
    mkdir -p "$buildPath" | tee -a "$logPath/$log"

    # Download the pdf export from dokuwiki site with cURL
    DownloadPage "$dokuwikiUrl" "$pageUri" "$buildPath"

done <"$pagesList"

# Delete pages list file
rm "$pagesList"

# EOF
ExitScript 0
