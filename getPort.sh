#!/bin/bash

########################################################################################
# This script is designed to be called with no arguments, and return a port that is    #
# currently unused, and allocate it so that concurrent runs hopefully don't take it.   #
# This isn't perfectly multi-access safe, but it should be close enough that we likely #
# will never run into any issues (sorry future folks if it does ever happen)           #
########################################################################################

# Ranges are inclusive
PORT_RANGE_START=7001
PORT_RANGE_END=7999

# Folder to store ports
FOLDER="$HOME/dev-site-ports"

CHOSENPORT=0

# Check each port for being in use
for ((PORT=PORT_RANGE_START; PORT<PORT_RANGE_END; PORT++))
do
  if [[ ! -f "$FOLDER/$PORT" ]]; then
    # File does not exist, therefore we found an open port to use
    CHOSENPORT=$PORT
    break
  elif [[ $# -ne 0 ]] && [[ "$(cat "$FOLDER/$PORT")" == "$1" ]]; then
    # File contents have the ID that we are currently getting a port for, reuse that port
    CHOSENPORT=$PORT
    break
  fi
done

# Reserve the port
touch "$FOLDER/$CHOSENPORT"

# Return the port to the caller
echo "$CHOSENPORT"

# Done
exit 0
