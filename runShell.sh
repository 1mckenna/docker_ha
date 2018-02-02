#!/bin/sh
CONTAINER=`docker container ls | grep lmckenna/rpi-home-assistant | cut -d " " -f1`
docker exec -it $CONTAINER /bin/bash
