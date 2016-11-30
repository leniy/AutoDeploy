#!/bin/bash

# By Leniy Tsan @ 2016.
# Install Syslog-ng with Mysql by just one script on a new centos6.8 instalation.
# Already considered corresponding optimization.

MYSQL_ROOT_PASSWORD='leniyroot'
SYSLOG_NG_DATABASE='leniylogs'

echo "[+] 停止可能有的rsyslog和SELinux服务"
service rsyslog stop
chkconfig rsyslog off
sed -i "s/^SELINUX\=enforcing/SELINUX\=disabled/g" /etc/selinux/config
setenforce 0
getenforce

echo "[+] 添加EPEL..."
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -q epel-release

echo "[+] 更新仓库及已有软件..."
yum clean all
yum makecache
yum -y update

echo "[+] 安装配置MySQL... "
yum -y install mysql-server
chkconfig mysqld on
service mysqld start
mysqladmin -u root password ${MYSQL_ROOT_PASSWORD}
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "create database IF NOT EXISTS ${SYSLOG_NG_DATABASE}"

echo "[+] 安装syslog-ng... "
yum -y install syslog-ng syslog-ng-libdbi libdbi-dbd-mysql libdbi-devel libdbi-drivers
service syslog-ng start
chkconfig syslog-ng on

echo "[+] 配置syslog-ng..."
grep -q "source s_leniynet" /etc/syslog-ng/syslog-ng.conf
if [ "$?" -ne "0" ]; then
echo "source s_leniynet { udp(ip(0.0.0.0) port(514)); };" >> /etc/syslog-ng/syslog-ng.conf
fi
grep -q "filter f_leniy_no_debug" /etc/syslog-ng/syslog-ng.conf
if [ "$?" -ne "0" ]; then
echo "filter f_leniy_no_debug { not level(debug); };" >> /etc/syslog-ng/syslog-ng.conf
fi
grep -q "destination d_leniymysql" /etc/syslog-ng/syslog-ng.conf
if [ "$?" -ne "0" ]; then
cat >>/etc/syslog-ng/syslog-ng.conf<<EOF
destination d_leniymysql {
    sql(
         type(mysql)
         host("localhost")
         username("root")
         password("${MYSQL_ROOT_PASSWORD}")
         database("${SYSLOG_NG_DATABASE}")
         table("logs")
         columns("host", "facility", "priority", "level", "tag", "datetime", "program", "msg")
         values("\$HOST", "\$FACILITY", "\$PRIORITY", "\$LEVEL", "\$TAG","\$YEAR-\$MONTH-\$DAY \$HOUR:\$MIN:\$SEC","\$PROGRAM", "\$MSG")
         indexes("datetime", "host", "program", "pid", "message")
    );
};
log { source(s_leniynet); filter(f_leniy_no_debug); destination(d_leniymysql); };
EOF
fi
service syslog-ng restart

echo "[+] 配置防火墙..."
#iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 3306 -j ACCEPT
service iptables stop

echo "[+] 完工睡觉..."
