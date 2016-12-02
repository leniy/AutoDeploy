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

echo "[+] 更新仓库及已有软件..."
yum clean all
yum makecache
yum -y update

echo "[+] 添加EPEL..."
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -q epel-release
yum -y install epel-release

echo "[+] 校对本机时间..."
yum -y install ntp ntpdate
ntpdate -u cn.ntp.org.cn

echo "[+] 安装配置MySQL... "
yum -y install mysql-server
chkconfig mysqld on
service mysqld start
mysqladmin -u root password ${MYSQL_ROOT_PASSWORD}
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "create database IF NOT EXISTS ${SYSLOG_NG_DATABASE}"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "grant select on *.* to readonly@'10.66.66.%' identified by '${MYSQL_ROOT_PASSWORD}';"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "grant select on *.* to readonly@'10.66.6.%' identified by '${MYSQL_ROOT_PASSWORD}';"

echo "[+] 安装syslog-ng... "
yum -y install syslog-ng syslog-ng-libdbi libdbi-dbd-mysql libdbi-devel libdbi-drivers
chkconfig syslog-ng on
service syslog-ng start

echo "[+] 配置syslog-ng..."
grep -q "source s_leniynet" /etc/syslog-ng/syslog-ng.conf
if [ "$?" -ne "0" ]; then
echo "source s_leniynet { udp(ip(0.0.0.0) port(514));tcp(ip(0.0.0.0) port(514));udp(ip(0.0.0.0) port(1514));tcp(ip(0.0.0.0) port(1514)); };" >> /etc/syslog-ng/syslog-ng.conf
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
        table("logs_\$R_YEAR\$R_MONTH\$R_DAY")
        columns("sourceip", "host", "r_datetime", "s_datetime", "facility", "priority", "level", "program", "msg")
        values("\$SOURCEIP", "\$HOST","\$R_YEAR-\$R_MONTH-\$R_DAY \$R_HOUR:\$R_MIN:\$R_SEC","\$S_YEAR-\$S_MONTH-\$S_DAY \$S_HOUR:\$S_MIN:\$S_SEC", "\$FACILITY", "\$PRIORITY", "\$LEVEL", "\$PROGRAM", "\$MSG")
        indexes("r_datetime", "sourceip")
    );
};
log { source(s_leniynet); filter(f_leniy_no_debug); destination(d_leniymysql); };
EOF
fi
service syslog-ng restart

echo "[+] 配置防火墙..."
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
iptables -A INPUT -p tcp --dport 514 -j ACCEPT
iptables -A INPUT -p udp --dport 514 -j ACCEPT
iptables -A INPUT -p tcp --dport 1514 -j ACCEPT
iptables -A INPUT -p udp --dport 1514 -j ACCEPT
service iptables save
service iptables stop
chkconfig iptables off

echo "[+] 完工睡觉..."
echo "===================="
echo "= Powered by Leniy ="
echo "===================="
