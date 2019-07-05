set +x
pass=$1
IP=$2
#Launching the basic services installation and configuration
source basic_controller_services.sh $pass $IP

source keystone_installing.sh $pass 

source nova_installing.sh $pass $IP

source neutron_installing.sh $pass


