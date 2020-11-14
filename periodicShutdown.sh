#!/bin/bash

########################################################################################
# This script is designed to be called with no arguments as a periodic cron job. It    #
# will check for instances that have been spun up, and shut them down after a set time #
# period elapses. They will be able to be started back up manually if desired.         #
# To determine an instance's age, the directory timestamp of the instance root folder  #
# is used. When an instance is started up afterwards (or recreated for some reason),   #
# the timestamp should be updated and then automatically not be shut down again by     #
# this script.                                                                         #
########################################################################################

###############
# Basic Setup #
###############

# Echo out what we're doing
echo "Checking for any instances to shut down (current time: $(date))"

# Enter the folder of instances
cd ~/CICD_TestInstances || { echo "Test Instances Folder Missing, Aborting."; exit 1; }

# Save current time
NOW=$(date +"%s")

# Calculate time offset. seconds * minutes * days * 2 weeks
(( TIMEOUT = 60*60*24*14 ))

# Loop through each folder and check if it's time to shut it down
for entry in "."/*
do
    entry=${entry:2}
    echo "$entry"
    INSTANCETIME=$(stat -c %Y "$entry")

    # Compare
    (( DAYSOLD = ( ( NOW - INSTANCETIME ) / ( 60*60*24 ) ) ))
    echo "Instance is $DAYSOLD days old ($(stat -c %y "$entry"))"

    # Check if too old
    if (( ( NOW - INSTANCETIME ) > TIMEOUT )); then
        echo "Shutting down instance"

        # Enter the folder to shut it down
        cd "$entry/PollBuddy" || { echo "Failed to cd into instance, aborting."; exit 1; }
        docker-compose -p "entry" down
        cd ../../ || { echo "Failed to cd out of instance, aborting."; exit 1; }
        echo "Instance has been shut down"
    fi

    echo "---"

done

echo "Instance check complete on $(date)"
echo ""

# Exit
exit 0