
set +x

pass=$1
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

#Installing packages 
apt install neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent

crudini --set  /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
crudini --set  /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $pass

crudini --set  /etc/nova/nova.conf neutron 
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

