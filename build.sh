#!/bin/bash

HA_LATEST=true
DOCKER_IMAGE_NAME="lmckenna/rpi-home-assistant"
PYTHON_OPENZWAVE_VERSION=$(curl -L -s 'https://raw.githubusercontent.com/home-assistant/home-assistant/dev/requirements_all.txt' | grep python\_openzwave\=\=)
log() {
   now=$(date +"%Y%m%d-%H%M%S")
   echo "$now - $*" >> /var/log/home-assistant/docker-build.log
}

log ">>--------------------->>"

## #####################################################################
## Home Assistant version
## #####################################################################
if [ "$1" != "" ]; then
   # Provided as an argument
   HA_VERSION=$1
   log "Docker image with Home Assistant $HA_VERSION"
else
   HA_VERSION="$(cat /var/log/home-assistant/docker-build.version)"
   HA_VERSION="$(curl -s 'https://pypi.python.org/pypi/homeassistant/json' | jq '.info.version' | tr -d '"')"
   HA_LATEST=true
   log "Docker image with Home Assistant 'latest' (version $HA_VERSION)"
fi

## #####################################################################
## For hourly (not parameterized) builds (crontab)
## Do nothing: we're trying to build & push the same version again
## #####################################################################
if [ "$HA_LATEST" == true ] && [ "$HA_VERSION" == "$_HA_VERSION" ]; then
   log "Docker image with Home Assistant $HA_VERSION has already been built & pushed"
   log ">>--------------------->>"
   exit 0
fi


## #####################################################################
## Removing Deps folder to ensure the latest stuff gets installed
## #####################################################################
sudo rm -rf homeassistant/configuration/deps/*

## #####################################################################
## Generate the start.sh script
## #####################################################################
cat << _EOF_ > start.sh
#!/bin/sh
set -e
echo "Updating locate DB"
updatedb
echo "Starting Mosquitto"
/etc/init.d/mosquitto start
echo "Updating Meta Tags if needed"
/config/build/setGCMMetaTag.sh
echo "Running Zwave setup"
/config/build/setupZW.sh
echo "Starting HA"
python3 -m homeassistant --config /config
exec "\$@"
_EOF_
## #####################################################################
## Generate the Dockerfile
## #####################################################################
cat << _EOF_ > Dockerfile
FROM resin/rpi-raspbian:stretch
MAINTAINER Ludovic Roguet <code@fourteenislands.io>

###################################
# Base layer
###################################
ENV ARCH=arm
ENV CROSS_COMPILE=/usr/bin/

###################################
# Install Core System Utils
###################################
RUN apt-get update && \
	apt-get install wget aptitude && \
	wget http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key && \
	apt-key add mosquitto-repo.gpg.key && \
	wget -P /etc/apt/sources.list.d/ http://repo.mosquitto.org/debian/mosquitto-stretch.list && \
	wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u7_armhf.deb && \
	dpkg -i libssl1.0.0_1.0.1t-1+deb8u7_armhf.deb && \
	wget http://ftp.nz.debian.org/debian/pool/main/libw/libwebsockets/libwebsockets3_1.2.2-1_armhf.deb && \
	dpkg -i libwebsockets3_1.2.2-1_armhf.deb && \
	aptitude install -y mosquitto mosquitto-clients
RUN apt-get update && \
    apt-get install --no-install-recommends \
      build-essential python3-dev python3-pip python3-setuptools libcap2-bin\
      git libffi-dev libpython-dev libssl-dev \
      libgnutls28-dev libgnutlsxx28 \
      libudev-dev vim\
      bluetooth libbluetooth-dev \
      net-tools nmap \
      libmicrohttpd-dev \
      iputils-ping \
      locate \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###################################
# Mouting point for the user's configuration
###################################
VOLUME /config

###################################
# Install Home Assistant
###################################
RUN pip3 install homeassistant==$HA_VERSION aiohttp_cors websocket-client sqlalchemy pyRFXTRX cython wheel six 'PyDispatcher>=2.0.5'

###################################
# Install Dev Branch of OpenZWave
###################################
RUN rm -f /config/deps/lib/python3.5/site-packages/libopenzwave.cpython-35m-arm-linux*.so && \
pip3 install 'python_openzwave' --install-option="--flavor=ozwdev"

###################################
# SET Emulated HUE  Permissions
###################################
RUN setcap 'cap_net_bind_service=+ep' /usr/bin/python3.5

###################################
#Setup Mosquitto for MQTT
###################################
RUN rm /etc/mosquitto/mosquitto.conf && \
	ln -s /config/mosquitto.conf /etc/mosquitto/mosquitto.conf && \
	adduser mosquitto --system --group && \
	touch /var/run/mosquitto.pid && \
	updatedb

###################################
# Add Start Script to Launch Services on Container Start
###################################
ADD start.sh /
RUN chmod +x /start.sh
CMD ["/start.sh"]
_EOF_

## #####################################################################
## Build the Docker image, tag and push to https://hub.docker.com/
## #####################################################################
log "Building $DOCKER_IMAGE_NAME:$HA_VERSION"
## Force-pull the base image
docker pull resin/rpi-raspbian
docker build -t $DOCKER_IMAGE_NAME:$HA_VERSION .

#log "Pushing $DOCKER_IMAGE_NAME:$HA_VERSION"
#docker push $DOCKER_IMAGE_NAME:$HA_VERSION

#if [ "$HA_LATEST" = true ]; then
#   log "Tagging $DOCKER_IMAGE_NAME:$HA_VERSION with latest"
#   docker tag $DOCKER_IMAGE_NAME:$HA_VERSION $DOCKER_IMAGE_NAME:latest
#   log "Pushing $DOCKER_IMAGE_NAME:latest"
#   docker push $DOCKER_IMAGE_NAME:latest
#   echo $HA_VERSION > /var/log/home-assistant/docker-build.version
#fi

log ">>--------------------->>"
