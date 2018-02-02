# docker_ha
Home Assistant Docker Container for Raspi

1. On your clean install RPI (i used raspbian) 
   Install docker using this command
	curl -sSL https://get.docker.com | sh

2. Run the fail2ban setup script prior to running the docker build this will get fail2ban installed and the correct configs in place.
   This script is located at /home/pi/homeassistant/configuration/ban/setupF2B.sh

3. Get an SSL Cert for your HA Instance by running the following  
   /home/pi/homeassistant/configuration/certbot/certbot-auto certonly --standalone --preferred-challenges http-01 --email <email address> -d YOURDOMAIN.duckdns.org

4. After you have run that command add this to the root accounts crontab to auto renew the cert
   30 2 * * 1 /home/pi/homeassistant/configuration/certbot/certbot-auto renew --quiet --no-self-upgrade --standalone --preferred-challenges http-01

5. In the /home/pi folder run
	mkdir -p /home/pi/homeassistant/configuration

	This will be the shared folder structure between all the HA contianers and where your confs will live. This is the only part of the docker conatiner that will live on when its restarted. Copy your confs out to here now. If you are not using mqtt you can del the mosquitto.conf and the mosquitto_pwfile. If you are using mqtt, copy the pwfile from your working system so you dont have to run the command then save it later. 

6. Open build.sh and edit line 
	#4 to change it to your name
	#40 - Here is where you will want to change the startup script to launch the HA stuff you are using. I am using just mqtt, so i start that before HA and run update DB so i can be lazy and use locate later on
	#67 add in other sys utils you need/use here to be installed via APT

If you have any other files that you need copied into the build image so it will exist outside of the conf dir, then use the COPY command as seen on lines #98 and #99.   
       
7. Once finished editing the build.sh script you can kick it off to go ahead and build the docker image
	./build.sh

8. Once the image is build we need to actually create the container you want to use with the image to do this edit the createContainer.sh script to have the last line match the image you just built using the build script
	./createContainer.sh
   If you forgot to look you can see what images you have by running 
	docker ps -a


9. As soon as you run createContainer docker will start the image and HA will start and bind to the rpi network address and pass the traffic normally. If you need to do something on the command line in there run the runShell.sh script and it will connect you to the image that is specified. You will need to edit if you changed the name of your image, which i asusme you will :)
	./runShell.sh



COMMON DOCKER COMMANDS/TASKS

BUILD: ./build.sh
STOP Docker Container: docker stop <name from createContainer.sh>
	i.e. docker stop hass
START Docker Container: docker start <name from createContainer.sh>
	i.e. docker start hass

Connect to running container
	./runShell.sh

Remove broken container and rebuild container
	docker stop hass
	docker rm hass
	./build
Remove Dangling Docker Images no longer in use
	docker rmi $(docker images -f dangling=true -q)

List Docker Images
	docker ps -a

Remove Docker Image
	docker rmi <imagename>

START OVER AND REMOVE ALL DOCKER CONTAINERS AND IMAGES
	docker rmi $(docker images -f dangling=true -q)
	docker -f dangling=true -q
	docker stop $(docker ps -a -q)
	docker rm $(docker ps -a -q)

