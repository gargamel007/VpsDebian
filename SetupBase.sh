#!/bin/bash

###########################
#Doc & Usage 
###########################
#This script is intended for post install on a xubuntu 13.10 system on virtual box !
:<<'USAGE'
sudo apt-get -qq update && apt-get -y -qq install git
git clone https://github.com/gargamel007/VpsDebian.git Code/VpsDebian
bash Code/VpsDebian/SetupBase.sh
USAGE

###########################
#Configuration
###########################
BASEDIR=$(dirname $0)


###########################
#Main
###########################
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

#Fix locale issue
sed -i "s/# fr_FR.UTF-8/fr_FR.UTF-8/g" /etc/locale.gen
sed -i "s/# en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
if [ ! -f .locale_is_reset ]; then dpkg-reconfigure locales fi;
touch .locale_is_reset
update-locale


#Fix crappy apt-source list : remove Rackster mirror
sed -i '/ackster/d' /etc/apt/sources.list

#Install Tools
echo "#############################"
echo "UPGRADE  && INSTAL BASE TOOLS"
apt-get -qq update && apt-get -qq -y upgrade
INSTPKG="dialog tree vim less screen git htop software-properties-common mosh"
#Perl is needed for rename command
INSTPKG+=" perl sudo locate toilet"
apt-get install -y -qq $INSTPKG


#Secure the ssh server
sudo addgroup sshlogin
usermod -a -G sshlogin root
mv $BASEDIR/FileSystem/etc/issue.net /etc/issue.net
rm /etc/ssh/ssh_host_*
if [ ! -f .sshd_is_reset ]; then dpkg-reconfigure openssh-server fi;
touch .sshd_is_reset
sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
sed -i "s/#Banner/Banner/g" /etc/ssh/sshd_config
sed -i "s/PrintMotd no/PrintMotd yes/g" /etc/ssh/sshd_config
if ! grep -q AllowGroups /etc/ssh/sshd_config
    then
    echo "AllowGroups sshlogin admin" >> /etc/ssh/sshd_config
  fi
service ssh restart
sleep 3

#Tweak vim 
sed -i "s/\"syntax on/syntax on/g" /etc/vim/vimrc

#Custom MOTD
echo "" > /etc/motd
if ! grep -q toilet /etc/init.d/motd
    then
    ADDMOTD="        toilet -f smmono9 -F gay \`hostname\` > \/var\/run\/motd.dynamic"
    sed -i "s/# Update motd/# Update motd\n$ADDMOTD/g" /etc/init.d/motd
    sed -i "s/uname -snrvm >/uname -srvm >>/g" /etc/init.d/motd
  fi