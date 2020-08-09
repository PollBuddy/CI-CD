#!/bin/bash

##############################################################################
# This script is designed to clone the repo and configure and start the app. #
##############################################################################

echo "Starting deployMaster.sh Script..."

###############
# Basic Setup #
###############

# Enter the folder to spin up an instance
cd ~/CICD_Master || { echo "CICD_Master Folder Missing, Aborting."; exit 1; }

# For maximum reproducibility, delete the old folder
rm -rf PollBuddy

# Clone the repo
echo "Cloning repo"
git clone https://github.com/PollBuddy/PollBuddy || { echo "Repo Cloning Failed, Aborting."; exit 1; }

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
# Update REACT_APP_BACKEND_URL
sed -i "/REACT_APP_BACKEND_URL/c\REACT_APP_BACKEND_URL=https://pollbuddy.app/api" PollBuddy-Server/frontend/.env  || { echo "Frontend SED Failed, Aborting."; exit 1; }

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

##################
# Start instance #
##################

# Talk about it
echo "Starting instance"

# Build containers
docker-compose -p MASTER build --parallel || { echo "Docker-Compose Build Failed, Aborting."; exit 1; }

# Just in case this is a rerun, try to shut down previous containers
docker-compose -p MASTER down

# Start it
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