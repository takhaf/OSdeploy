#!/bin/bash
set +x

pass=$1

#Creating the keystone database user and granting privileges
mysql <<EOF 
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' 
IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' 
IDENTIFIED BY '$pass';
EOF

#Installing the package
apt install -y keystone  apache2 libapache2-mod-wsgi
cp conf_files/etc_keystone_keystone.conf /etc/keystone/keystone.conf
crudini --set /etc/keystone/keystone.conf database connection  mysql+pymysql://keystone:$pass@controller/keystone

#Configuring INI parameters
crudini --set /etc/keystone/keystone.conf token provider fernet

su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password $pass \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
echo "ServerName controller" >> /etc/apache2/apache2.conf

service apache2 restart
source admin-openrc
openstack project create --domain default \
  --description "Service Project" service
