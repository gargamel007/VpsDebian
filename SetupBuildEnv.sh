#!/bin/bash

###########################
#Doc & Usage 
###########################
#This script is intended for post install on a Debian 7 system on VPS !
:<<'USAGE'
As root run the follwing commands
sed -i '/ackster/d' /etc/apt/sources.list && apt-get -qq update && apt-get -y -qq install git
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
#To prevent dialogs
export DEBIAN_FRONTEND=noninteractive
#Show all commands
set -x

#Install Tools
echo "#############################"
echo "UPGRADE  && INSTAL BUILD TOOLS"
apt-get -qq -y install emdebian-archive-keyring
echo "deb http://www.emdebian.org/debian/ unstable main" >> /etc/apt/sources.list
apt-get -qq update && apt-get -qq -y upgrade
INSTPKG="debootstrap qemu-user-static git build-essential gcc-4.7-arm-linux-gnueabihf u-boot-tools"
INSTPKG+=" qemu libncurses5-dev module-init-tools dialog parted binfmt-support libusb-1.0-0-dev"
INSTPKG+=" libncurses5-dev dosfstools lvm2 ccache zip unzip bison flex gawk gettext texinfo texlive"
INSTPKG+=" uuid-dev zlib1g-dev pkg-config"
#In the doc : linux-headers-generic linux-image-generic 
#Armstrap : kpartx
apt-get install -y -qq $INSTPKG


#FIXME: bellow find/fix why the version-less filename is not created automatically
ln -sf `which arm-linux-gnueabihf-gcc-4.7 ` /usr/local/bin/arm-linux-gnueabihf-gcc


set +x
unset DEBIAN_FRONTEND