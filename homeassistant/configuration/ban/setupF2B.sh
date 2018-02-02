#!/bin/sh
#Install fail2ban
apt-get install -y fail2ban
#Copy new CONF to modify the Log Location
cp fail2ban.conf /etc/fail2ban/fail2ban.conf
#Create log dir
mkdir /etc/fail2ban/log
#Move HA Jail Info
cp jail.local /etc/fail2ban/jail.local
#Move HA Filter Info
cp hass.local /etc/fail2ban/filter.d/hass.local
#Move old ssh jail
mv /etc/fail2ban/jail.d/defaults-debian.conf /etc/fail2ban/jail.d/defaults-debian.conf.old
#Make start on boot
systemctl enable fail2ban.service
