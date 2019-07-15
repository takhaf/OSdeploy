set +x 

#Installing and configuring the NTP service
apt install -y chrony
echo "server controller iburst" >> /etc/chrony/chrony.conf
service chrony restart
pass=$1
IP=`hostname -I |awk '{print $1}'`
mgt_interface=$3

source nova_compute_installing.sh $pass $IP
source neutron_compute_installing.sh $pass $IP $mgt_interface

