#!/bin/bash
set +x 

pass=$1
IP=$2
#Installing nova compute package
apt install -y nova-compute

#Moving in lightened conf files
cp conf_files/etc_nova_nova-compute.conf /etc/nova/nova-compute.conf


crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:$pass@controller
crudini --set /etc/nova/nova.conf api auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url  http://controller:5000/v3
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers  controller:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type  password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name  default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password $pass
crudini --set /etc/nova/nova.conf DEFAULT my_ip  $IP
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf vnc enabled True
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address '$my_ip'
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://controller:6080/vnc_auto.html
crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement os_region_name  RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name  Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://controller:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password $pass

crudini --set /etc/nova/nova-compute.conf libvirt virt_type qemu

service nova-compute restart


