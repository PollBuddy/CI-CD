#!/bin/bash

##############################################################################
# This script is designed to clone the repo and configure and start the app. #
##############################################################################

# Requires packages: docker, docker-compose, procmail, git, sed, tac, potentially others depending on your distro

echo "Starting deployMaster.sh Script..."

#####################
# Exclusivity Check #
#####################

function finish {
  # Remove lock file
  rm -f ~/deployMaster.lock
}
trap finish EXIT

# Try to acquire a lock every 5 seconds, not continuing until then.
# Given that this normally is run by GitHub, this should end up terminated by them if it never gets a lock
echo "Acquiring lock..."
lockfile -5 ~/deployMaster.lock

###############
# Basic Setup #
###############

# Enter the folder to spin up an instance
cd ~/CICD_Master || { echo "CICD_Master Folder Missing, Aborting."; exit 1; }

# For maximum reproducibility, delete the old folder
rm -rf PollBuddy

# Clone the repo
echo "Cloning repo"
git clone --depth 1 https://github.com/PollBuddy/PollBuddy || { echo "Repo Cloning Failed, Aborting."; exit 1; }

# Enter it
cd PollBuddy || { echo "Repo Folder Missing, Aborting."; exit 1; }

############################
# Configure Instance Setup #
############################

# Echo out what we're doing
echo "Configuring environment variables"

# Frontend

# Copy frontend's .env file
cp PollBuddy-Server/frontend/.env.example PollBuddy-Server/frontend/.env || { echo "Frontend .env Copy Failed, Aborting."; exit 1; }

# Modify frontend's .env file
# Update REACT_APP_FRONTEND_URL
sed -i "/REACT_APP_FRONTEND_URL/c\REACT_APP_FRONTEND_URL=https://pollbuddy.app" PollBuddy-Server/frontend/.env  || { echo "Frontend SED Failed, Aborting."; exit 1; }
# Update REACT_APP_BACKEND_URL
sed -i "/REACT_APP_BACKEND_URL/c\REACT_APP_BACKEND_URL=https://pollbuddy.app/api" PollBuddy-Server/frontend/.env  || { echo "Frontend SED Failed, Aborting."; exit 1; }

# Done configuring frontend environment variables
echo "Frontend environment variables configured"

# Backend

# Copy backend's .env file
cp PollBuddy-Server/backend/.env.example PollBuddy-Server/backend/.env || { echo "Backend .env Copy Failed, Aborting."; exit 1; }

# Modify backend's .env file
# Update FRONTEND_URL
sed -i "/FRONTEND_URL/c\FRONTEND_URL=https://pollbuddy.app" PollBuddy-Server/backend/.env  || { echo "Backend SED Failed, Aborting."; exit 1; }
# Configure the custom session secret
sed -i "/SESSION_SECRET/c\SESSION_SECRET=$(cat ../env/SESSION_SECRET)" PollBuddy-Server/backend/.env  || { echo "Backend SED Failed, Aborting."; exit 1; }
# Configure email server access
sed -i "/EMAIL_ADDRESS_INTERNAL/c\EMAIL_ADDRESS_INTERNAL=$(cat ../env/EMAIL_ADDRESS_INTERNAL)" PollBuddy-Server/backend/.env  || { echo "Backend SED Failed, Aborting."; exit 1; }
sed -i "/EMAIL_ADDRESS_EXTERNAL/c\EMAIL_ADDRESS_EXTERNAL=$(cat ../env/EMAIL_ADDRESS_EXTERNAL)" PollBuddy-Server/backend/.env  || { echo "Backend SED Failed, Aborting."; exit 1; }
sed -i "/EMAIL_CLIENT_ID/c\EMAIL_CLIENT_ID=$(cat ../env/EMAIL_CLIENT_ID)" PollBuddy-Server/backend/.env  || { echo "Backend SED Failed, Aborting."; exit 1; }
sed -i "/EMAIL_CLIENT_SECRET/c\EMAIL_CLIENT_SECRET=$(cat ../env/EMAIL_CLIENT_SECRET)" PollBuddy-Server/backend/.env  || { echo "Backend SED Failed, Aborting."; exit 1; }
sed -i "/EMAIL_REFRESH_TOKEN/c\EMAIL_REFRESH_TOKEN=$(cat ../env/EMAIL_REFRESH_TOKEN)" PollBuddy-Server/backend/.env  || { echo "Backend SED Failed, Aborting."; exit 1; }

# Done configuring frontend environment variables
echo "Backend environment variables configured"

# Docker

# Configure port

# Collect a port
PORT=7000

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

#############################
# Create and Start instance #
#############################

# Pull the latest images
echo "Pulling latest Docker images"
docker pull node:current
docker pull node:current-alpine
docker pull mongo:4
docker pull nginx:latest
docker pull influxdb:1.8
docker pull grafana/grafana:latest

# Build containers
echo "Building containers for instance"
docker-compose -p MASTER build --parallel || { echo "Docker-Compose Build Failed, Aborting."; exit 1; }

# Just in case this is a rerun, try to shut down previous containers
echo "Attempting to stop any previous containers"
docker-compose -p MASTER down

# Start it
echo "Starting instance"
docker-compose -p MASTER up -d || { echo "Docker-Compose Up Failed, Aborting."; exit 1; }

# We're done!
echo "Instance is now running"

##########
# Finish #
##########

# We're done!
echo "Deployment completed successfully!"
echo "Deploy Link: https://pollbuddy.app/"

# Exit
exit 0