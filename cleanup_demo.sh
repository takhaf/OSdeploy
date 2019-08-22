#!/bin/bash
set -x

source admin-openrc

openstack server delete test_selfservice-instance2
openstack server delete test_selfservice-instance1

openstack keypair delete my_test_key
openstack image delete cirros
openstack security group delete my_security_group
ports=`openstack port list --router test_router | awk '/ip_address=.*/ {print $2}'`

port1=`echo $ports | awk '{print $1}'`
port2=`echo $ports | awk '{print $2}'`
port3=`echo $ports | awk '{print $3}'`


openstack router remove port test_router $port1
openstack router remove port test_router $port2
openstack router remove port test_router $port3

openstack router delete test_router

openstack network delete provider_network
openstack network delete selfservice1
openstack network delete selfservice2

openstack flavor delete m1.nano
 
rm cirros-0.4.0-x86_64-disk.img
rm my_test_key my_test_key.pub
 


echo "Cleanup done !!!"
