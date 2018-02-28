#!/bin/sh
docker run -d --name hass --net=host --privileged --restart always --device /dev/ttyACM0:rwm -v /etc/localtime:/etc/localtime:ro -v /etc/fail2ban:/etc/fail2ban:rw -v /etc/letsencrypt:/etc/letsencrypt:ro -v /home/pi/docker_ha/homeassistant/configuration:/config lmckenna/rpi-home-assistant:0.64.0
