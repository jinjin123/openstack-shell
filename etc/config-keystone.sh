#!/bin/bash
NAMEHOST=$HOSTNAME
line=`cat /var/log/install_log | awk '{print$1}'`
if [ $line -eq 4 ]
then
	echo "db had installed."
else
	echo -e "\033[41;37m you should install mariadb first. \033[0m"
	exit
fi
cat /var/log/install_log | grep keystone
if [ $? -eq 0 ]
then
	echo "you had install keystone ."
	exit
fi

yum clean all &&  yum install openstack-keystone httpd mod_wsgi
function fn_create_keystone_database(){
mysql -e "CREATE DATABASE keystone;" && mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'controller' IDENTIFIED BY 'KEYSTONE_DBPASS';" && mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';"
echo "create DATABASE"
}
[ -f /etc/keystone/keystone.conf ] || cp -a /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak
echo "[ -f /etc/keystone/keystone.conf ] || cp -a /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak"
ADMIN_TOKEN=$(openssl rand -hex 10)
openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN 
echo "openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN "

openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:KEYSTONE_DBPASS@$HOSTNAME/keystone
echo "openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:KEYSTONE_DBPASS@$HOSTNAME/keystone"

openstack-config --set /etc/keystone/keystone.conf token provider fernet
echo "openstack-config --set /etc/keystone/keystone.conf token provider fernet"

su -s /bin/sh -c "keystone-manage db_sync" keystone
echo " su -s /bin/sh -c "keystone-manage db_sync" keystone"

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
echo " keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone"

[ -f /etc/httpd/conf/httpd.conf_bak  ] || cp -a /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_bak
echo "[ -f /etc/httpd/conf/httpd.conf_bak  ] || cp -a /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_bak"

sed  -i  "s/#ServerName www.example.com:80/ServerName ${HOSTNAME}/" /etc/httpd/conf/httpd.conf
echo  "sed  -i  's/#ServerName www.example.com:80/ServerName $HOSTNAME/' /etc/httpd/conf/httpd.conf"

[ -f /etc/httpd/conf.d/wsgi-keystone.conf ] || cp -a /etc/httpd/conf.d/wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf.bak
rm -rf /etc/httpd/conf.d/wsgi-keystone.conf && cp -a $PWD/lib/wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf
echo "cp -a $PWD/lib/wsgi-keystone.conf  /etc/httpd/conf.d/wsgi-keystone.conf "

chown keystone:keystone /var/log/keystone/keystone.log
echo "chown keystone:keystone /var/log/keystone/keystone.log"

systemctl enable httpd.service && systemctl start httpd.service
echo "systemctl enable httpd.service && systemctl start httpd.service"

export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://$HOSTNAME:35357/v3
export OS_IDENTITY_API_VERSION=3

ENDPOINT_LIST=`openstack endpoint list | grep keystone | awk -F "|" '{print$4}' | awk '{if($1=="keystone"){print $1,$2,$3;exit}}'`
if [  ${ENDPOINT_LIST}x  = keystonex  ]
then
	log_info "openstack endpoint had created."
else
	openstack service create --name keystone --description "OpenStack Identity" identity && openstack endpoint create --region RegionOne identity public http://$HOSTNAME:5000/v3 && openstack endpoint create --region RegionOne 
  identity internal http://$HOSTNAME:5000/v3 && openstack endpoint create --region RegionOne identity admin http://$HOSTNAME:35357/v3
	echo "OpenStack endpoint create"
fi
