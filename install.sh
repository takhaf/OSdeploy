#!/bin/bash
set +x 

source admin-openrc
#install.sh   "password"   "IP"   "type"   ["mgt_interface name"]
pass=$1
IP=$2
if [ $# -eq 3 ]
     then type=$3
fi
if [ $# -eq 4 ]
     then mgt_interface=$4
fi
#controller is the default type of node 
#else type="controller"

#Setting the controller IP for DNS resolution
echo "$IP   controller" >> /etc/hosts

#Adding the OpenStack repository for Ubuntu
apt install software-properties-common
add-apt-repository cloud-archive:queens
apt install python-openstackclient



if [ "$type" == "controller" ]
	then source controller_actions.sh $pass $IP
elif [ "$type" == "compute" ]
	then source compute_actions.sh $pass $IP $mgt_interface

else echo "Unknown node type"
fi
