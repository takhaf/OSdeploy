#Default password  for rabbitmq
if [ $# -eq 2 ]
	then
		pass=$1
		mgt_network_address=$2
fi

#Installing chrony for NTP service
echo "Installing chrony ..."
sleep 2
apt install chrony -y 

NTP_SERVER="mouette.rd.francetelecom.fr"
echo "server $NTP_SERVER iburst
allow $mgt_network_address" >> /etc/chrony/chrony.conf
service chrony restart



#Installing Maria-DB for storage
echo "Installing Maria DB ..."
sleep 2

apt install mariadb-server python-pymysql -y

echo "[mysqld]
bind-address = $mgt_network_address
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
" > /etc/mysql/mariadb.conf.d/99-openstack.cnf


service mysql restart

#Automating the mysql_secure_installation script
mysql -u root <<EOF
UPDATE mysql.user SET Password=PASSWORD('${db_root_password}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF


#Installing rabbitmq server

echo "Installing rabbitmq ..."
sleep 2

apt install -y rabbitmq-server 
rabbitmqctl add_user openstack $pass
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#Installing memcached

echo "Installing memcached ..."
sleep 2
apt install -y memcached python-memcache 

echo "-l $mgt_network_address"  > /etc/memcached.conf


service memcached restart

#Installing etcd

echo "Installing etcd ..."
apt install -y etcd
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
"> /etc/default/etcd

systemctl enable etcd
systemctl start etcd
