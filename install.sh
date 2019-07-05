#!/bin/bash
set +x 

#install.sh   "password"   "IP"   "type"   ["mgt_interface name"]
pass=$1
IP=$2
if [ $# -eq 3 ]
     then type=$3

if [ $# -eq 4 ]
     then mgt_interface=$4

#controller is the default type of node 
else type="controller"
fi 
#Setting the controller IP for DNS resolution
echo "controller      $IP" >> /etc/hosts

if [ "$type" == "controller" ]
	then source controller_actions.sh $pass $IP
elif [ "$type" == "compute" ]
	then source compute_actions.sh $pass $IP $mgt_interface

else echo "Unknown node type"
fi

