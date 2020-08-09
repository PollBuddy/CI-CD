#!/bin/bash

########################################################################################
# This script is designed to be called with a commit ID. It will then take that,       #
# clone the repo, check out the commit, and configure and start the app based on that. #
########################################################################################

# Requires packages: docker, docker-compose, procmail, git, sed, tac, potentially others depending on your distro

echo "Starting deployTestInstance.sh Script..."

#######################
# Argument Validation #
#######################

# Name the variable
COMMIT=$1

# Make sure exactly 1 argument is passed
if [ $# -ne 1 ]; then
    echo "Invalid Arguments Specified, Aborting."; exit 1
fi

# Only allowing a-z, 0-9 in commit IDs
if [[ "${COMMIT}" =~ [^abcdefghijklmnopqrstuvwxyz0123456789] ]]; then
    echo "Invalid Commit, Aborting."; exit 1
fi

echo "Argument Validated."

#####################
# Exclusivity Check #
#####################

# Try to acquire a lock every 5 seconds, not continuing until then.
# Given that this normally is run by GitHub, this should end up terminated by them if it never gets a lock
echo "Acquiring lock..."
lockfile -5 ~/deployTestInstance.lock

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

# Make sure the port isn't 0
if [ "$PORT" -eq "0" ]; then
   echo "No ports available, Aborting.";
   exit 1
fi

echo "Acquired port $PORT"

# Store our commit ID in the port file for use in cleanup tasks
echo "$COMMIT" > "$HOME/dev-site-ports/$PORT"

# Write into docker compose file
sed -i "s/7655:80/$PORT:80/g" docker-compose.yml  || { echo "Docker SED Failed, Aborting."; exit 1; }

# Add newlines to docker-compose.yml to fix issue with tac breaking
echo "" >> docker-compose.yml
echo "" >> docker-compose.yml
echo "" >> docker-compose.yml

# Delete other port mappings (temporary until they're removed in the real code)
tac docker-compose.yml | sed "/3000:3000/I,+1 d" | tac > docker-compose.yml.new || { echo "Docker SED Failed, Aborting."; exit 1; }
mv docker-compose.yml.new docker-compose.yml || { echo "Docker SED Failed, Aborting."; exit 1; }
tac docker-compose.yml | sed "/3001:3001/I,+1 d" | tac > docker-compose.yml.new || { echo "Docker SED Failed, Aborting."; exit 1; }
mv docker-compose.yml.new docker-compose.yml || { echo "Docker SED Failed, Aborting."; exit 1; }
tac docker-compose.yml | sed "/3002:3000/I,+1 d" | tac > docker-compose.yml.new || { echo "Docker SED Failed, Aborting."; exit 1; }
mv docker-compose.yml.new docker-compose.yml || { echo "Docker SED Failed, Aborting."; exit 1; }
tac docker-compose.yml | sed "/27017:27017/I,+1 d" | tac > docker-compose.yml.new || { echo "Docker SED Failed, Aborting."; exit 1; }
mv docker-compose.yml.new docker-compose.yml || { echo "Docker SED Failed, Aborting."; exit 1; }

# Done configuring docker environment variables
echo "Docker environment variables configured"

# We're done configuring
echo "Configuring environment variables complete"

##################
# Start instance #
##################

# Talk about it
echo "Starting instance"

# Build containers
docker-compose -p $COMMIT build --parallel || { echo "Docker-Compose Build Failed, Aborting."; exit 1; }

# Just in case this is a rerun, try to shut down previous containers
docker-compose -p $COMMIT down

# Start it
docker-compose -p $COMMIT up -d || { echo "Docker-Compose Up Failed, Aborting."; exit 1; }

# We're done!
echo "Instance is now running"

######################
# Configure Dev Site #
######################

# Talk about it
echo "Configuring dev site"

# Copy example configuration file
cp ~/PollBuddy.app/webserver/conf.d/TEMPLATE.conf.ignore "$HOME/dev-site-configs/$COMMIT.conf" || { echo "Template NGINX Config Copy Failed, Aborting."; exit 1; }

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

# Move over to the website folder
cd ~/PollBuddy.app/ || { echo "CD to PollBuddy.app Folder Failed, Aborting."; exit 1; }

# Restart dev site (instance configs are bind mounted, so we just need to restart nginx)
docker-compose restart

# We're done!
echo "Dev site restarted"

##########
# Finish #
##########

# Remove lock file
rm -f ~/deployTestInstance.lock

# We're done!
echo "Deployment completed successfully!"
echo "Deploy Link: https://dev-$COMMIT.pollbuddy.app/"

# Exit
exit 0