# Environment
me=$(basename "$0")
scriptName=${me%.*}

# DokuWiki
dokuwikiUrl=https://dokuwiki.example.com/doku.php
dokuwikiPath=/var/lib/dokuwiki/data
dokuwikiLogPath=$dokuwikiPath/pages/information/dokuwiki

# Path
workingPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
logPath=$workingPath/log
logArchivePath=$logPath/archive

# Log
log=$scriptName.txt
logLastTask=$scriptName.lasttask.txt
logDate=$(/bin/date -d "$(/usr/bin/stat -c %y "$logPath"/"$log")" '+%m-%d-%Y')

# Email
mailFrom=dokuwiki@example.com
mailTo1=admin@example.com
mailTo2=itnotification@example.com

# Exit
exitCode=0
