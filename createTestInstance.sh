#!/bin/bash

########################################################################################
# This script is designed to be called with a commit ID. It will then take that,       #
# clone the repo, check out the commit, and configure and start the app based on that. #
########################################################################################

echo "Starting createTestInstance.sh Script..."

#######################
# Argument Validation #
#######################

# Name the variable
COMMIT=$2

# Make sure exactly 1 argument is passed
if [ $# -ne 1 ]; then
    echo "Invalid Arguments Specified, Aborting."; exit 1
fi

# Only allowing a-z, 0-9 in commit IDs
if [[ "${COMMIT}" =~ [^abcdefghijklmnopqrstuvwxyz0123456789] ]]; then
    echo "Invalid Commit, Aborting."; exit 1
fi

echo "Argument Validated."

###############
# Basic Setup #
###############

# Echo out what we're doing
echo "Creating instance for commit '$COMMIT'"

# Enter the folder to spin up an instance
cd ~/CICD_TestInstances || { echo "Test Instances Folder Missing, Aborting."; exit 1; }

# If for some reason this job was being rerun, we'll want to delete the old folder. We don't care if it fails of course
rm -rf "$COMMIT"

# Create a folder for this instance
echo "Creating folder for this instance"
mkdir "$COMMIT"

# Enter it
cd "$COMMIT" || { echo "Commit Folder Missing, Aborting."; exit 1; }

# Clone the repo
echo "Cloning repo"
git clone https://github.com/PollBuddy/PollBuddy || { echo "Repo Cloning Failed, Aborting."; exit 1; }

# Enter it
cd PollBuddy || { echo "Repo Folder Missing, Aborting."; exit 1; }

# Checkout the commit
echo "Checking out commit"
git checkout "$COMMIT" || { echo "Commit Checkout Failed, Aborting."; exit 1; }

############################
# Configure Instance Setup #
############################

# Echo out what we're doing
echo "Configuring environment variables"

# Frontend

# Copy frontend's .env file
cp PollBuddy-Server/frontend/.env.example PollBuddy-Server/frontend/.env || { echo "Frontend .env Copy Failed, Aborting."; exit 1; }

# Modify frontend's .env file
# Update REACT_APP_BACKEND_URL
sed -i "/REACT_APP_BACKEND_URL/c\REACT_APP_BACKEND_URL=https://dev-$COMMIT.pollbuddy.app/api" PollBuddy-Server/frontend/.env  || { echo "Frontend SED Failed, Aborting."; exit 1; }

# Done configuring frontend environment variables
echo "Frontend environment variables configured"

# Backend

# Copy backend's .env file
cp PollBuddy-Server/backend/.env.example PollBuddy-Server/backend/.env || { echo "Backend .env Copy Failed, Aborting."; exit 1; }

# Modify frontend's .env file
# Nothing of interest to modify in backend's .env file

# Done configuring frontend environment variables
echo "Backend environment variables configured"

# Docker

# Configure port

# Collect a port
PORT="$(bash ~/CI-CD/getPort.sh)"

# Write into docker compose file
sed -i "s/7655:80/$PORT:80/g" docker-compose.yml  || { echo "Docker SED Failed, Aborting."; exit 1; }

# Done configuring docker environment variables
echo "Docker environment variables configured"

# We're done configuring
echo "Configuring environment variables complete"

##################
# Start instance #
##################

# Talk about it
echo "Starting instance"

# Start it
docker-compose up -d --build || { echo "Docker-Compose Failed, Aborting."; exit 1; }

# We're done!
echo "Instance is now running"

######################
# Configure Dev Site #
######################

# Talk about it
echo "Configuring dev site"

# Copy example configuration file
cp ~/dev-site/dev-webserver/conf.d/TEMPLATE.conf.ignore "$HOME/dev-site-configs/$COMMIT.conf" || { echo "Template NGINX Config Copy Failed, Aborting."; exit 1; }

# Edit configuration file
sed -i "s/TEMPLATE_COMMITID/$COMMIT/g" "$HOME/dev-site-configs/$COMMIT.conf"  || { echo "NGINX SED Failed, Aborting."; exit 1; }
sed -i "s/TEMPLATE_PORT/$PORT/g" "$HOME/dev-site-configs/$COMMIT.conf"  || { echo "NGINX SED Failed, Aborting."; exit 1; }

# We're done!
echo "Dev site configured"

####################
# Restart Dev Site #
####################

# Talk about it
echo "Restarting dev site"

# Move over to the dev site folder
cd ~/dev-site/ || { echo "CD to dev-site Failed, Aborting."; exit 1; }

# Restart/Rebuild dev site
docker-compose down
docker-compose up -d --build

# We're done!
echo "Dev site restarted"

##########
# Finish #
##########

# We're done!
echo "Deployment completed successfully!"

# Exit
exit 0