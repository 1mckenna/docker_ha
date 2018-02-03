# Home Assistant Docker Container for Raspi (docker_ha)

1. On your clean install RPI (I used raspbian) install docker using this command
   - **curl -sSL https://get.docker.com | sh**
2. Clone the docker_ha repo
   - **cd /home/pi && git clone https://github.com/1mckenna/docker_ha.git**

   **/home/pi/docker_ha/homeassistant/configuration** will be the shared folder structure between all the HA contianers and where your confs will live. This is the only part of the docker conatiner that will live on when its restarted.
   
   Copy your confs out to here now. If you are using mqtt, copy the mosquitto_pwfile from your working system so you dont have to run the command then save it later and copy it into the configuration directory

3. Run the fail2ban setup script prior to running the docker build this will get fail2ban installed and the correct configs in place.
  - This script is located at
    - **/home/pi/docker_ha/homeassistant/configuration/ban/setupF2B.sh**

4. Get an SSL Cert for your HA Instance by running the following  
   - **/home/pi/docker_ha/homeassistant/configuration/certbot/certbot-auto certonly --standalone --preferred-challenges http-01 --email <email address> -d YOURDOMAIN.duckdns.org**

5. After you have run that command add this to the root accounts crontab to auto renew the cert
  - **30 2 * * 1 /home/pi/docker_ha/homeassistant/configuration/certbot/certbot-auto renew --quiet --no-self-upgrade --standalone --preferred-challenges http-01**

6. Open **build.sh** and edit the following lines 
    - **Line 4:** to change it to your name
    - **Line 40:** Here is where you will want to change the startup script to launch the HA stuff you are using. I am using just mqtt, so i start that before HA and run update DB so I can be lazy and use locate later on
     - **Line 67:** add in other sys utils you need/use here to be installed via APT
     - If you have any other files that you need copied into the build image so it will exist outside of the conf dir, then use the COPY command as seen on **lines 98 and 99**.   
       
7. Once finished editing the build.sh script you can kick it off to go ahead and build the docker image
     - **./build.sh**

8. Once the image is build we need to actually create the container you want to use with the image to do this edit the **createContainer.sh** script to have the last line match the image you just built using the build script
   - **./createContainer.sh**
   - **YOU HAVE TO DO THIS EACH TIME YOU BUILD A NEW IMAGE**
   - If you forgot to look you can see what images you have by running 
        - **docker ps -a**
   
9. As soon as you run **createContainer.sh** docker will start the image and HA will start and bind to the rpi network address and pass the traffic normally. If you need to do something on the command line in there run the **runShell.sh** script and it will connect you to the image that is specified. You will need to edit if you changed the name of your image from hass
    - **./runShell.sh**


# Sample Secrets file
In my configs you will see a lot of references to **!secret someIdentifier**. This tells Home Assistant to pull the value for that config from the secrets.yaml file. Below is my secrets.yaml file without the sensitive info to make it easier to re-create your own
```
####################################################################
#secrets.yaml (/home/pi/docker_ha/configuration/secrets.yaml)
####################################################################
#MAIN CONFIG FILE SECRETS (configuration.yaml)
haname:
latitude:
longitude:
elevation:

#HOME ASSISTANT HTTP SETTINGS (config/http.yaml)
ha_api_password: 
ha_ssl_certificate:
ha_ssl_key: 
ha_base_url:

# MEDIA DEVICE SETTINGS (config/media.yaml)
onkyo_host:
samsung_host:
samsung_port:
samsung_mac:

# MQTT SERVER SETTINGS (config/mqtt.yaml
mqtt_username: 
mqtt_password: 

#GOOGLE ASSISTANT SECRETS (config/gassistant.yaml)
ga_project_id:
ga_client_id: 
ga_access_token:  
ga_agent_user_id:
ga_api_key:

#GOOGLE CLOUD NOTIFICATION SETTINGS (config/notify.yaml)
gcm_api_key:
gcm_sender_id: 

#ZWAVE SECURITY KEY SETTING (config/zwave.yaml)
zwave_key:

#SENSOR SETTINGS (config/sensors.yaml)
wu_api_key:

# PHONE DETAILS (various configs)
adminPhone: 
```
