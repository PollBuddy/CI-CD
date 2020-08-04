#!/bin/bash

# Arg conversion
BRANCH=$1
COMMIT=$2

###############
# Basic Setup #
###############

# Some input validation to be safe
if [[ "${BRANCH}" =~ [^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/-_] ]]; then
    echo "Invalid Branch, Aborting."; exit 1
fi
if [[ "${COMMIT}" =~ [^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/-_] ]]; then
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
