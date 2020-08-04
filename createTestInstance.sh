#!/bin/bash

echo "Starting createTestInstance.sh Script..."

#######################
# Argument Validation #
#######################

# Name the variables
BRANCH=$1
COMMIT=$2

# Make sure exactly 2 arguments are passed
if [ $# -ne 2 ]; then
    echo "Invalid Arguments Specified, Aborting."; exit 1
fi

# Only allowing A-Z, a-z, 0-9, -, _, / in branch names
if [[ "${BRANCH}" =~ [^-_/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789] ]]; then
    echo "Invalid Branch, Aborting."; exit 1
fi

# Only allowing a-z, 0-9 in commit IDs
if [[ "${COMMIT}" =~ [^abcdefghijklmnopqrstuvwxyz0123456789] ]]; then
    echo "Invalid Commit, Aborting."; exit 1
fi

echo "Arguments Validated."

###############
# Basic Setup #
###############

# Echo out what we're doing
echo "Creating instance for branch '$BRANCH' at commit '$COMMIT'"

# Enter the folder to spin up an instance
cd ~/CICD_TestInstances || { echo "Test Instances Folder Missing, Aborting."; exit 1; }

# If for some reason this job was being rerun, we'll want to delete the old folder. We don't care if it fails of course
rm -rf "$BRANCH.$COMMIT"

# Create a folder for this instance
echo "Creating folder for this instance"
mkdir "$BRANCH.$COMMIT"

# Enter it
cd "$BRANCH.$COMMIT" || { echo "Branch.Commit Folder Missing, Aborting."; exit 1; }

# Clone the repo
echo "Cloning repo"
git clone https://github.com/PollBuddy/PollBuddy || { echo "Repo Cloning Failed, Aborting."; exit 1; }

# Enter it
cd PollBuddy || { echo "Branch.Commit Folder Missing, Aborting."; exit 1; }

# Checkout the commit
echo "Checking out commit"
git checkout "$COMMIT" || { echo "Commit Checkout Failed, Aborting."; exit 1; }

############################
# Configure Instance Setup #
############################

