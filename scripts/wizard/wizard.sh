#!/bin/bash
set -eu
DIALOG_OPTS="--ascii-lines --clear --output-fd 1 --input-fd 2"

function install_dialog () {
echo "Installing dialog."
sudo yum install -y dialog 2>/dev/null
echo "Dialog successfully installed"
sleep 1
}

function main_dialog () {
choice=$( dialog $DIALOG_OPTS --menu Wizard -1 0 5 1 'Configure network' 2 'Change password' )
case "$choice" in
   1)
      choice=$( network_dialog )
      ;;
   2)
      choice=$( chpass_dialog )
      ;;
esac
}

function chpass_dialog () {
npw1=$(dialog $DIALOG_OPTS --ok-label "Submit" --insecure --passwordbox "New password for $USER" 0 0 )
npw2=$(dialog $DIALOG_OPTS --ok-label "Submit" --insecure --passwordbox "Confirm password for $USER" 0 0 )
echo -e "$npw1\n$npw2" | sudo passwd $USER 2>/dev/null || errorbox "Failed to change password"
}

function network_dialog () {
dialog $DIALOG_OPTS --ok-label "Submit" \
	  --form "Configure network" \
	15 50 0 \
	'IP address v4 (CIDR):' 1 1	"" 	1 22 20 0 \
	"Gateway v4:"		2 1	""  	2 17 15 0 \
	"DNS Nameserver:"	3 1	""  	3 17 15 0 \
| configure_network
}

function configure_network () {
read fullip
read gw
read dns
[ -z $fullip  ] && return
[ -z $gw  ] && return
[ -z $dns ] && return
ip=$(echo $fullip | cut -d"/" -f1 )
prefix=$(echo $fullip | cut -d"/" -f2 )

ifname=`ip l | awk '/^[1-9]/ {sub(":","",$2);if ($2=="lo") next; print $2;nextfile}'`
mac_add=$(ifconfig $ifname | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
sudo tee /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF >/dev/null
# Created by cloud-init on instance boot automatically, do not edit.
#
NM_CONTROLLED=no
BOOTPROTO=none
DEVICE=$ifname
HWADDR=$mac_add
ONBOOT=yes
STARTMODE=auto
TYPE=Ethernet
USERCTL=no
NETMASK=255.255.255.0
IPADDR=$ip
PREFIX=$prefix
GATEWAY=$gw
DNS1=$dns
IPV6INIT=no
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
UUID=a5855473-efea-4ef4-a414-f350e677276
NAME=$ifname
EOF
sudo tee -a /etc/resolv.conf <<EOF
NAMESERVER 8.8.8.8
EOF
sudo systemctl restart network  2>/dev/null || errorbox "Configuration error"
sudo /home/centos/flush_iptables.sh
}

function errorbox () {
dialog $DIALOG_OPTS --msgbox "$1" 0 0
}

 
which dialog || install_dialog
true
while [ "$?" == "0" ] ; do
main_dialog
clear
done

clear
