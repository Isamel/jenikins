#!/usr/bin/env bash

export COMPOSE_PROJECT_NAME=equifax

# Remove existing containers
docker-compose down --volumes
docker stop $(docker ps -aq --filter name=gitlab_)
docker rm --volumes -f $(docker ps -aq --filter name=gitlab_)
docker stop jenkins_server
docker rm --volumes -f jenkins_server

# create local node image
docker-compose build jenkins_node_1
docker-compose up -d registry

## Start new containers
docker-compose up --build
