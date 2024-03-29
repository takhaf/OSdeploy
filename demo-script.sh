#!/bin/bash
set -x
if [ $# -eq 1 ]
	then IP=$1
else IP=`hostname -I |awk '{print $1}'`
fi

gateway_IP=`route -n |awk '/^0.0.0.0.*/ {print $2}'`

source admin-openrc
#The cirros image we use for our VMs
wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare --public

#We create the provider network
openstack network create  --share --external \
 --provider-physical-network provider \
 --provider-network-type flat provider_network

openstack subnet create --network provider_network \
 --allocation-pool start=192.168.122.10,end=192.168.122.100 \
 --dns-nameserver 192.168.122.1 --gateway 192.168.122.1 \
 --subnet-range 192.168.122.0/24 provider_network

#The selfservice network
openstack network create selfservice1
openstack network create selfservice2
#We create two subnets 
openstack subnet create --network selfservice1 \
  --dns-nameserver $IP --gateway 1.1.1.1 \
  --subnet-range 1.1.1.0/24 selfservice1

openstack subnet create --network selfservice2 \
  --dns-nameserver $IP --gateway 2.2.2.1 \
  --subnet-range 2.2.2.0/24 selfservice2

#Creating the router
openstack router create test_router

#Adding the two subnets in te router
openstack router add subnet test_router selfservice1
openstack router add subnet test_router selfservice2

#Setting the gateway to the provider network
openstack router set test_router --external-gateway provider_network


#We create a flavor for our cirros VMS
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano


#Generating a keypair for ssh communication
ssh-keygen -q -N "" -f my_test_key
openstack keypair create --public-key my_test_key.pub my_test_key


#Creating a new security group and adding rules
openstack security group create my_security_group
openstack security group rule create --proto icmp my_security_group
openstack security group rule create --proto tcp --dst-port 22 my_security_group

#Retrieving net-ids
net_id1=`openstack network list |awk '/.*selfservice1/{print $2}'`
net_id2=`openstack network list |awk '/.*selfservice2/{print $2}'`

#We create the servers
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$net_id1 --security-group my_security_group \
  --key-name my_test_key test_selfservice-instance1

openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$net_id2 --security-group my_security_group \
  --key-name my_test_key test_selfservice-instance2
set +x
