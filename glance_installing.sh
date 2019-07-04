set +x

pass=$1

#Creating the database and granting the necessary privileges for the glance account

mysql -u root --password=$pass<<END
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO \'glance\'@\'localhost\' \
IDENTIFIED BY \'$pass\';
GRANT ALL PRIVILEGES ON glance.* TO \'glance\'@\'%\' \
IDENTIFIED BY \'$pass\';
END

#creating the glance user and granting the admin privilege in the domain
openstack user create --domain default --password $pass glance

openstack role add --project service --user glance admin

#Create the service and defining the endpoints
openstack service create --name glance \
  --description "OpenStack Image" image

openstack endpoint create --region RegionOne \
  image public http://controller:9292

openstack endpoint create --region RegionOne \
  image internal http://controller:9292

openstack endpoint create --region RegionOne \
  image admin http://controller:9292

#Installing the package
apt install glance

#Setting INI parameters

crudini --set /etc/glance/glance-api.conf database connection \"mysql+pymysql://glance:$pass@controller/glance\"

crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri  http://controller:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url  http://controller:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers  controller:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type  password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name  Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name  Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password $pass

crudini --set /etc/glance/glance-api.conf glance_store stores  "file,http"
crudini --set /etc/glance/glance-api.conf glance_store default_store  file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir  "/var/lib/glance/images/"


crudini --set /etc/glance/glance-registry.conf database connection "mysql+pymysql://glance:$pass@controller/glance"


crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri  http://controller:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url  http://controller:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type  password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name  Default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name  Default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name  service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username  glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password  $pass

crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

su -s /bin/sh -c "glance-manage db_sync" glance

service glance-registry restart
service glance-api restart
