#!/bin/bash

#######################
# Argument Validation #
#######################

BRANCH=$1
COMMIT=$2

if [ $# -ne 2 ]; then
    echo "Invalid Arguments Specified, Aborting."; exit 1
fi

###############
# Basic Setup #
###############

# Echo out what we're doing
echo "Creating instance for $BRANCH at $COMMIT..."

# Some input validation to be safe
if [[ "${BRANCH}" =~ [^-_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/] ]]; then
    echo "Invalid Branch, Aborting."; exit 1
fi
if [[ "${COMMIT}" =~ [^-_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/] ]]; then
    echo "Invalid Commit, Aborting."; exit 1
fi

# Enter the folder to spin up an instance
cd ~/CICD_TestInstances || { echo "Test Instances Folder Missing, Aborting."; exit 1; }

# Create a folder for this instance
mkdir "$BRANCH.$COMMIT"

# Enter it
cd "$BRANCH.$COMMIT" || { echo "Branch.Commit Folder Missing, Aborting."; exit 1; }

# Clone the repo
git clone https://github.com/PollBuddy/PollBuddy || { echo "Repo Cloning Failed, Aborting."; exit 1; }

# Enter it
cd PollBuddy || { echo "Branch.Commit Folder Missing, Aborting."; exit 1; }

# Checkout the commit
git checkout "COMMIT" || { echo "Commit Checkout Failed, Aborting."; exit 1; }

############################
# Configure Instance Setup #
############################
