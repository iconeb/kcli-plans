yum -y install centos-release-scl centos-release-scl-rh epel-release
yum -y install rh-mariadb103-mariadb-server-galera crudini
crudini --set /etc/opt/rh/rh-mariadb103/my.cnf.d/galera.cnf mysqld wsrep_cluster_name my_cluster
crudini --set /etc/opt/rh/rh-mariadb103/my.cnf.d/galera.cnf mysqld wsrep_cluster_address '"gcomm://{{ ["g0{}.{}".format(node + 1, domain) for node in range(0, nodes)] | join(",") }}"'

if [ $(hostname) == "g01" ]; then
  /opt/rh/rh-mariadb103/root/bin/galera_new_cluster
fi
sleep 20
#systemctl enable --now rh-mariadb103-mariadb
systemctl start rh-mariadb103-mariadb
