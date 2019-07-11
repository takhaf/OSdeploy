set +x

pass=$1
IP=$2

#Name of the management interface
interface_name=$3

#Installing packages and setting parameters
apt install neutron-linuxbridge-agent

#We move in the lightened conf file
mv conf_files/etc_neutron_plugins_ml2_linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini

crudini --set /etc/neutron/neutron.conf DEFAULT	transport_url rabbit://openstack:$pass@controller
crudini --set /etc/neutron/neutron.conf DEFAULT	auth_strategy keystone


crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $pass

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp


crudini --set /etc/nova/nova.conf neutron url http://controller:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://controller:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $pass

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$interface_name

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $IP
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini security_group enable_security_group true

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini security_group firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

service nova-compute restart

service neutron-linuxbridge-agent restart
