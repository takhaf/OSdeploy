#!/bin/bash
set +x 

source admin-openrc
#install.sh   "password"   "IP"   "type"   ["mgt_interface name"]
pass=$1
IP=$2

type=$3
mgt_interface=$4

#controller is the default type of node 
#else type="controller"

#Setting the controller IP for DNS resolution
echo "$IP   controller" >> /etc/hosts

#Adding the OpenStack repository for Ubuntu
apt install software-properties-common
add-apt-repository cloud-archive:queens
apt install python-openstackclient



if [ "$type" == "controller" ]
	then source controller_actions.sh $pass $IP $mgt_interfac
elif [ "$type" == "compute" ]
	then source compute_actions.sh $pass $IP $mgt_interface

else echo "Unknown node type"
fi
