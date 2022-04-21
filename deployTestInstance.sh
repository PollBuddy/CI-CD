#!/bin/bash

##############################################################################
# Transitional script to forward old dev instance requests to the new system #
##############################################################################

# Requires packages: docker, docker-compose, procmail, git, sed, tac, potentially others depending on your distro

echo "Starting deployTestInstance.sh Script..."


#######################
# Argument Validation #
#######################

# Name the variables
ID=$1
MODE=$2

# Make sure exactly 2 arguments are passed
if [ $# -ne 2 ]; then
  # 2 args not passed, see if 1 was
  if [ $# -ne 1 ]; then
    # 1 arg was not passed
    echo "Invalid Number Of Arguments Specified, Aborting."; exit 1
  else
    # 1 arg was passed, use compatibility mode
    echo "1 Argument specified, running in compatibility mode"
    MODE="ISSUE"
  fi
fi

# Validate MODE and ID (depending on MODE)
if [ "${MODE}" = "ISSUE" ]; then

   # Only allow a-z, 0-9 in commit IDs
  if [[ "${ID}" =~ [^abcdefghijklmnopqrstuvwxyz0123456789] ]]; then
      echo "Invalid Commit ID, Aborting."; exit 1
  fi

elif [ "${MODE}" = "PR" ]; then

  # Only allow 0-9 in PR Numbers
  if [[ "${ID}" =~ [^0123456789] ]]; then
      echo "Invalid PR Number, Aborting."; exit 1
  fi

else
  echo "Invalid Mode Specified, Aborting."; exit 1
fi

echo "Arguments Validated."



#####################
# Exclusivity Check #
#####################

function finish {
  # Remove lock files
  echo "Trapped EXIT, removing lockfiles"
  rm -f ~/deployTestInstance.lock
  rm -f ~/deployTestInstance-"${ID}".lock
}
trap finish EXIT

# Try to acquire a lock every 5 seconds, not continuing until then.
# Given that this normally is run by GitHub, this should end up terminated by them if it never gets a lock
echo "Acquiring unique lock..."

# Acquire unique lock so that we can have parallel builds that don't interfere with each other
lockfile -5 ~/deployTestInstance-"${ID}".lock
echo "Unique lock acquired"



###############
# Basic Setup #
###############

# Echo out what we're doing
echo "Forwarding instance creation request for '${TYPE}' with ID '${ID}' to new system"
curl --location --request POST 'https://dev.pollbuddy.app/api/deployment/new' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode "dev_instance_type=${MODE}" \
--data-urlencode "dev_instance_id=${ID}" \
--data-urlencode "key=$(cat ~/CICD_SECRET)"


##########
# Finish #
##########

# We're done!
echo "Forwarding complete"

# Exit and release locks
exit 0
