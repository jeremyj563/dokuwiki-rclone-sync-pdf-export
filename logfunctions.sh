function WriteLog {
    local message=$1

    # Write the message to the log with the current date/time
    local dateTime=$(/bin/date '+%m/%d/%Y %H:%M:%S')
    printf "\\n%s - %s\\n\\n" "$message" "$dateTime" | tee -a "$logPath/$log"
}

function WriteLogRepeatChar {
    local char=$1 # The character to be repeated
    local count=$2 # The number of times to repeat the character
    local newLine=$3 # Boolean for printing a carriage return

    printf "$char"'%.s' $(eval echo "{1..$(($count))}") | tee -a "$logPath/$log"
    if [ $newLine = true ]; then
        printf "\\n" | tee -a "$logPath/$log"
    fi
}

function WriteLogEvent {
    local message=$1

    # This function is used to specify either the beginning or end of the log.
    local dateTime=$(/bin/date '+%m/%d/%Y %H:%M:%S')
    WriteLogRepeatChar "*" "100" true
    WriteLogRepeatChar " " "35" false
    printf "%s TASK - %s\\n" "$message" "$dateTime" | tee -a "$logPath/$log"
    WriteLogRepeatChar "*" "100" true
}

function LogLastModifiedToday {
    # This function returns boolean based on the log last modified date
    local today=$(/bin/date '+%m-%d-%Y')
    if [ "$today" = "$logDate" ]; then
        true;
    else
        false;
    fi
}
