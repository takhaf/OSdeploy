IP=$1

#THe cirros image we use for our VMs
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public

#We create the provider network
openstack network create  --share --external \
 --provider-physical-network provider \
 --provider-network-type flat provider

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
openstack router create router

#Adding the two subnets in te router
openstack router add subnet router selfservice1
openstack router add subnet router selfservice2

#Setting the gateway to the provider network
openstack router set router --external-gateway provider


#We create a flavor for our cirros VMS
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano


#Generating a keypair for ssh communication
ssh-keygen -q -N "" -f mykey
openstack keypair create --public-key mykey mykey


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
  --key-name mykey selfservice-instance1

openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$net_id2 --security-group my_security_group \
  --key-name mykey selfservice-instance2


