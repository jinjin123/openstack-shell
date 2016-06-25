#!/bin/bash
function fn_install_openstack(){
cat <<EOF
0)config Basic environment.
1)install mariadb,nosql,redis,memcache
2)install keystone.
3)install glance.
4)install nova.
5)install neturn.
6)install cinder.
7)install dashboard.
8)quit
EOF

read -p "please input one number :" install_number
expr ${install_number}+0 >/dev/null
if[ $? -eq 0 ]
then
		echo "input is number."
else
	echo "please input one number [0-3]"
	echo "input is string."
	fn_install_openstack
fi	
if [ -z ${install_number} ]
then
	echo "please input one right number[0-3]"
	fn_install_openstack
elif [ ${install_number} -eq 0 ]
then
	yum clean all && yum install net-tools
	/bin/bash $PWD/etc/presystem.sh
	echo "/bin/bash $PWD/etc/presystem.sh."
elif [ ${install_number} -eq 1]
then
	/bin/bash $PWD/etc/install_db.sh
	echo "/bin/bash $PWD/etc/install_db.sh."
	fn_install_openstack
elif [ ${install_number} -eq 2]
then
     /bin/bash $PWD/etc/config-keystone.sh
     echo "/bin/bash $PWD/etc/config-keystone.sh."
     fn_install_openstack
     
	
} 
