
set +x
source admin-openrc
pass=$1
IP=$2
interface_name=$3

mysql -u root --password=$pass	<<END
CREATE DATABASE neutron;

GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' 
IDENTIFIED BY '$pass';

GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' 
IDENTIFIED BY '$pass';
END

openstack user create --domain default --password $pass neutron
openstack role add --project service --user neutron admin	

openstack service create --name neutron \
  --description "OpenStack Networking" network

openstack endpoint create --region RegionOne \
  network public http://controller:9696

openstack endpoint create --region RegionOne \
  network internal http://controller:9696

openstack endpoint create --region RegionOne \
  network admin http://controller:9696

#Installing packages and configuring network option 2
apt install -y neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent

#Using the lightened conf files instead 
cp conf_files/etc_neutron_neutron.conf /etc/neutron/neutron.conf
cp conf_files/etc_neutron_plugins_ml2_ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
cp conf_files/etc_neutron_plugins_ml2_linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
cp conf_files/etc_neutron_l3_agent.ini /etc/neutron/l3_agent.ini
cp conf_files/etc_neutron_dhcp_agent.ini /etc/neutron/dhcp_agent.ini
cp conf_files/etc_neutron_metadata_agent.ini /etc/neutron/metadata_agent.ini


crudini --set /etc/neutron/neutron.conf database connection  mysql+pymysql://neutron:$pass@controller/neutron

crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$pass@controller
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $pass

crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true


crudini --set /etc/neutron/neutron.conf nova auth_url http://controller:5000
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name default
crudini --set /etc/neutron/neutron.conf nova user_domain_name default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password $pass

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
crudini --set  /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true


crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$interface_name
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $IP
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini security_group enable_security_group true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini security_group firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

#Done configuring Option networking

crudini --set  /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
crudini --set  /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $pass

crudini --set  /etc/nova/nova.conf neutron url http://controller:9696
crudini --set  /etc/nova/nova.conf neutron auth_url http://controller:5000
crudini --set  /etc/nova/nova.conf neutron auth_type  password
crudini --set  /etc/nova/nova.conf neutron project_domain_name default
crudini --set  /etc/nova/nova.conf neutron user_domain_name default
crudini --set  /etc/nova/nova.conf neutron region_name  RegionOne
crudini --set  /etc/nova/nova.conf neutron project_name  service
crudini --set  /etc/nova/nova.conf neutron username  neutron
crudini --set  /etc/nova/nova.conf neutron password  $pass
crudini --set  /etc/nova/nova.conf neutron service_metadata_proxy true
crudini --set  /etc/nova/nova.conf neutron metadata_proxy_shared_secret $pass

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

