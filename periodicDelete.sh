#!/bin/bash

########################################################################################
# This script is designed to be called with no arguments as a periodic cron job. It    #
# will check for instances that have been shut down, and delete them after a set time  #
# period elapses (currently, 4 weeks). They would have to be manually/automatically    #
# recreated to be spun up again.                                                       #
########################################################################################

###############
# Basic Setup #
###############

# Echo out what we're doing
echo "Checking for any instances to delete (current time: $(date))."

# Enter the folder of instances
cd ~/CICD_TestInstances || { echo "Test Instances Folder Missing, Aborting."; exit 1; }

# Save current time
NOW=$(date +"%s")

# Calculate time offset. seconds * minutes * days * 4 weeks
(( TIMEOUT = 60*60*24*28 ))

# Loop through each folder and check if it's time to delete it
for entry in "."/*
do
  entry=${entry:2}
  echo "$entry"

  # Check the modified time
  INSTANCETIME=$(stat -c %Y "$entry")  # Checks the modified time of the instance folder

  # Compare
  (( DAYSOLD = ( ( NOW - INSTANCETIME ) / ( 60*60*24 ) ) ))
  echo "Instance is $DAYSOLD days old ($(stat -c %y "$entry"))."

  # Check if too old
  if (( ( NOW - INSTANCETIME ) > TIMEOUT )); then
      echo "Shutting down and deleting instance."

      # Enter the folder
      cd "$entry/PollBuddy" || { echo "Failed to cd into instance, aborting."; exit 1; }
      docker-compose -p "$entry" down -v
      docker-compose -p "$entry" rm -s -f -v

      cd ../../ || { echo "Failed to cd out of instance, aborting."; exit 1; }
      echo "Instance has been shut down and containers removed."

      # Delete the folder
      rm -rf "$entry"
      echo "Instance folder has been deleted."

  else
      echo "Instance does not need to be deleted."
  fi

  echo "---"

done

echo "Instance check complete on $(date)."

echo "Cleaning up Docker Data..."
# Filter makes sure images are at least 2h old to prune (in case any builds are running)
docker image prune -f -a --filter "until=2h"
docker volume prune -f  # Doesn't support the filter for some reason, shouldn't really matter though
docker network prune -f --filter "until=2h"

echo "Docker Data cleanup complete on $(date)."
echo ""

# Exit
exit 0