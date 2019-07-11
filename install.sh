#!/bin/bash
set +x 

source admin-openrc
#install.sh   "password"   "IP"   "type"   ["mgt_interface name"]
pass=$1
IP=$2

type=$3
#If the management interface is not specified by the user we retrieve it !
if [ $# -gt 3 ] 
	then mgt_interface=$4
else mgt_interface=`ip addr show | awk '/inet.*brd/{print $NF;exit}'`
fi


#Setting the controller IP for DNS resolution
echo "$IP    controller ">> /etc/hosts

#Adding the OpenStack repository for Ubuntu
apt install software-properties-common -y 
add-apt-repository cloud-archive:queens
apt install python-openstackclient -y



if [ "$type" == "controller" ]
	then source controller_actions.sh $pass $IP $mgt_interface
elif [ "$type" == "compute" ]
	then source compute_actions.sh $pass $IP $mgt_interface

else echo "Unknown node type"
fi
