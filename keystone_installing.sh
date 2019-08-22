#!/bin/bash
set -x

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

service apache2  restart
service keystone restart
service mysql restart

export OS_USERNAME=admin
export OS_PASSWORD=$pass
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

openstack project create --domain default \
  --description "Service Project" service

openstack token issue
