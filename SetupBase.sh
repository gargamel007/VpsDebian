#!/bin/bash

###########################
#Doc & Usage
###########################
#This script is intended for post install on a Debian 8 system on VPS !
:<<'USAGE'
As root run the follwing commands
apt-get -qq update && apt-get -y -qq upgrade && apt-get -y -qq install git
git clone https://github.com/gargamel007/VpsDebian.git Code/VpsDebian
bash Code/VpsDebian/SetupBase.sh
USAGE

###########################
#Configuration
###########################
BASEDIR=$(dirname $0)
USERNAME="gargamel"


###########################
#Main
###########################
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi
#To prevent dialogs
export DEBIAN_FRONTEND=noninteractive
#Show all commands
set -x

#Fix locale issue
sed -i "s/# fr_FR.UTF-8/fr_FR.UTF-8/g" /etc/locale.gen
sed -i "s/# en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
if [ ! -f /tmp/is_reset_locale ]; then dpkg-reconfigure locales; fi
touch /tmp/is_reset_locale
update-locale

#Install Tools
echo "#############################"
echo "UPGRADE  && INSTAL BASE TOOLS"
apt-get -qq update && apt-get -qq -y upgrade
INSTPKG="dialog tree vim less screen git htop software-properties-common mosh rsync ncdu curl wget"
#Perl is needed for rename command
INSTPKG+=" perl sudo locate toilet ufw fail2ban autojump zsh"
INSTPKG+=" tmux"

apt-get install -y -qq $INSTPKG

#Packages from backports
#apt-get install -y -qq -t wheezy-backports "tmux"

#Cleanup
apt-get -y -qq clean

#Add new user
adduser $USERNAME
usermod -s /bin/zsh $USERNAME
local GROUPS="adm,sudo,users,sshlogin"
sudo addgroup sshlogin
usermod -a -G $GROUPS $USERNAME

#Cleanup
apt-get -y -qq clean

#Secure the ssh server
mv $BASEDIR/FileSystem/etc/issue.net /etc/issue.net
if [ ! -f /tmp/is_reset_sshd ]; then
 rm /etc/ssh/ssh_host_*
 dpkg-reconfigure openssh-server
fi
touch /tmp/is_reset_sshd
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
sed -i "s/#Banner/Banner/g" /etc/ssh/sshd_config
sed -i "s/PrintMotd no/PrintMotd yes/g" /etc/ssh/sshd_config
if ! grep -q AllowGroups /etc/ssh/sshd_config
    then
    echo "AllowGroups sshlogin admin" >> /etc/ssh/sshd_config
  fi
service ssh restart
sleep 3

#Custom MOTD
if ! grep -q toilet /etc/init.d/motd
  then
  echo "" > /etc/motd
  ADDMOTD="        toilet -f smmono9 -F gay \`hostname -s\` > \/var\/run\/motd.dynamic"
  sed -i "s/# Update motd/# Update motd\n$ADDMOTD/g" /etc/init.d/motd
  sed -i "s/uname -snrvm >/uname -srvm >>/g" /etc/init.d/motd
  /etc/init.d/motd start
fi

### SETUP FIREWALL
#Disable Ipv6 if found
if `ifconfig|grep -q inet6`
  then
  echo "#Disable IPv6"|tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.all.disable_ipv6 = 1"|tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.default.disable_ipv6 = 1"|tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.lo.disable_ipv6 = 1"|tee -a /etc/sysctl.conf
  sleep 2
  sysctl -p
fi
sed -i "s/IPV6=yes/IPV6=no/g" /etc/default/ufw
sed -i "s/^IPT_MODULES/#IPT_MODULES/g" /etc/default/ufw
#sed -i '/#/!{/BROADCAST/{s/^/#/g}}' /etc/ufw/after.rules
#sed -i '/#/!{/ ufw-not-local/{s/^/#/g}}' /etc/ufw/before.rules
ufw allow ssh
ufw allow 60000:61000/udp #for mosh
ufw --force enable
sleep 2

#Cleanup
set +x
unset DEBIAN_FRONTEND
