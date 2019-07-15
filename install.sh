#!/bin/bash
set +x 

source admin-openrc
#install.sh   "password"    "type"    ["IP"] ["mgt_interface name"]
pass=$1

type=$2

#If the IP address is not given we retrieve it
if [ $# -gt 2 ]
	then IP=$3
else IP=`hostname -I |awk '{print $1}'`
fi


#If the management interface is not specified by the user we retrieve it !
if [ $# -gt 3 ] 
	then mgt_interface=$4
else mgt_interface=`ip addr show | awk '/inet.*brd/{print $NF;exit}'`
fi


#Setting the controller IP for DNS resolution
echo "$IP    controller ">> /etc/hosts

#Adding the OpenStack repository for Ubuntu
apt install software-properties-common -y 
add-apt-repository cloud-archive:queens -y
apt update
apt install python-openstackclient -y

#Tool to manipulate INI files
apt install -y crudini

if   [ "$type" == "controller" ]
	then source controller_actions.sh $pass $IP $mgt_interface
elif [ "$type" == "compute" ]
	then source compute_actions.sh $pass $IP $mgt_interface
elif [ "$type" == "both" ]
	then
 	 source controller_actions.sh $pass $IP $mgt_interface
	 source compute_actions.sh $pass $IP $mgt_interface
else echo "Unknown node type"
fi
