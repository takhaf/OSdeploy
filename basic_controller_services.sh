#Default password  for rabbitmq
if [ $# -eq 2 ]
	then
		pass=$1
		mgt_network_address=$2
fi

#Installing chrony for NTP service
echo "Installing chrony ..."
sleep 2
apt install chrony

NTP_SERVER="mouette.rd.francetelecom.fr"
echo "server $NTP_SERVER iburst
allow $mgt_network_address" >> /etc/chrony/chrony.conf
service chrony restart



#Installing Maria-DB for storage
echo "Installing Maria DB ..."
sleep 2

apt install mariadb-server python-pymysql

echo "[mysqld]
bind-address = $mgt_network_address
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
" > /etc/mysql/mariadb.conf.d/99-openstack.cnf


service mysql restart
mysql_secure_installation

#Installing rabbitmq server

echo "Installing rabbitmq ..."
sleep 2

apt install rabbitmq-server
rabbitmqctl add_user openstack $pass
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#Installing memcached

echo "Installing memcached ..."
sleep 2
apt install memcached python-memcache

<<<<<<< HEAD
echo "-l $mgt_network_address"  > /etc/memcached.conf
=======
echo "-l $mgt_network_address" > /etc/memcached.conf
>>>>>>> dce5593dda28bf4ea461bfa48cdc8beb8447b383

service memcached restart

#Installing etcd

echo "Installing etcd ..."
apt install etcd
echo "
ETCD_NAME=\"controller\"
ETCD_DATA_DIR=\"/var/lib/etcd\"
ETCD_INITIAL_CLUSTER_STATE=\"new\"
ETCD_INITIAL_CLUSTER_TOKEN=\"etcd-cluster-01\"
ETCD_INITIAL_CLUSTER=\"controller=http://$mgt_network_address:2380\"
ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http://$mgt_network_address:2380\"
ETCD_ADVERTISE_CLIENT_URLS=\"http://$mgt_network_address:2379\"
ETCD_LISTEN_PEER_URLS=\"http://0.0.0.0:2380\"
ETCD_LISTEN_CLIENT_URLS=\"http://$mgt_network_address:2379\"
" > /etc/default/etcd

systemctl enable etcd
systemctl start etcd


#Installing crudini

apt install crudini

