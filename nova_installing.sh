set +x
#Takes password and ip address as parameters
pass=$1
mgt_network_address=$2
#Creating the databases and granting the privileges to the neutron profile
mysql -u root --password=$pass<<EOF
CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' 
IDENTIFIED BY '$pass';

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' 
IDENTIFIED BY '$pass';

GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' 
IDENTIFIED BY '$pass';

GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' 
IDENTIFIED BY '$pass';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' 
IDENTIFIED BY '$pass';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' 
IDENTIFIED BY '$pass';

EOF


#Defining services and endpoints
openstack user create --domain default --password $pass nova

openstack role add --project service --user nova admin

openstack service create --name nova \
  --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1

 openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1

openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1


openstack user create --domain default --password $pass placement

openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement

openstack endpoint create --region RegionOne placement public http://controller:8778

openstack endpoint create --region RegionOne placement internal http://controller:8778

openstack endpoint create --region RegionOne placement admin http://controller:8778


#Installing the packages 
apt install -y nova-api nova-conductor nova-consoleauth \
  nova-novncproxy nova-scheduler nova-placement-api

#Moving in lightened conf files
cp conf_files/etc_nova_nova.conf /etc/nova/nova.conf



#Setting the parameters 
crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$pass@controller/nova_api

crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$pass@controller/nova

crudini --set /etc/nova/nova.conf DEFAULT transport_url  rabbit://openstack:$pass@controller

crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken  auth_url  http://controller:5000/v3
crudini --set /etc/nova/nova.conf keystone_authtoken  memcached_servers  controller:11211
crudini --set /etc/nova/nova.conf keystone_authtoken  auth_type  password
crudini --set /etc/nova/nova.conf keystone_authtoken  project_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken  user_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken  project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken  username nova
crudini --set /etc/nova/nova.conf keystone_authtoken  password $pass

crudini --set /etc/nova/nova.conf DEFAULT my_ip $mgt_network_address

crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver


crudini --set /etc/nova/nova.conf DEFAULT vnc enabled true
crudini --set /etc/nova/nova.conf DEFAULT vnc server_listen '$my_ip'
crudini --set /etc/nova/nova.conf DEFAULT vnc server_proxyclient_address '$my_ip'

crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292	

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp 

crudini --del /etc/nova/nova.conf default log_dir


crudini --set /etc/nova/nova.conf placement os_region_name  RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name  Default
crudini --set /etc/nova/nova.conf placement project_name  service
crudini --set /etc/nova/nova.conf placement auth_type  password
crudini --set /etc/nova/nova.conf placement user_domain_name  Default
crudini --set /etc/nova/nova.conf placement auth_url http://controller:5000/v3
crudini --set /etc/nova/nova.conf placement username  placement

#Setting the refreshing interval for detecting compute nodes
crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300



su -s /bin/sh -c "nova-manage api_db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova


su -s /bin/sh -c "nova-manage db sync" nova

nova-manage cell_v2 list_cells
#Finally we restart all our services..

service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart


