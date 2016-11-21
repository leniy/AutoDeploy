#!/bin/bash

# By Leniy Tsan @ 2016.
# Install nginx (include proxy_pass) by just one script on a new centos6.8 instalation.
# Already considered corresponding optimization, and turn on the reverse proxy functions.

Nginx_Ver='nginx-1.10.2'
Default_Website_Dir='/usr/local/nginx/html'

echo "[+] Create nginx user and group... "
groupadd nginx
useradd -s /sbin/nologin -g nginx nginx

echo "[+] Install compiling environment... "
grep -q "114.114.114.114" /etc/resolv.conf
if [ "$?" -ne "0" ]; then echo "nameserver 114.114.114.114" >> /etc/resolv.conf; fi
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
cp res/CentOS6-Base-163.repo /etc/yum.repos.d/
yum clean all
yum makecache
yum -y update
yum -y install make zlib zlib-devel gcc gcc-c++ libtool perl pcre-devel openssl-devel

echo "[+] Compile Nginx... "
cd src/
[[ -d "${Nginx_Ver}" ]] && rm -rf ${Nginx_Ver}
tar zxf ${Nginx_Ver}.tar.gz
cd ${Nginx_Ver}
./configure \
	--user=nginx \
	--group=nginx \
	--prefix=/usr/local/nginx \
	--sbin-path=/usr/sbin/nginx \
	--with-http_stub_status_module \
	--with-http_ssl_module \
	--with-http_v2_module \
	--with-http_realip_module \
	--with-stream \
	--with-stream_ssl_module \
	--with-http_gzip_static_module \
	--with-ipv6 \
	--with-http_sub_module \
	--http-proxy-temp-path=/usr/local/nginx/proxy_temp/ 
make && make install
cd ../
[[ -d "${Nginx_Ver}" ]] && rm -rf ${Nginx_Ver}
cd ../

echo "[+] Config nginx... "
[[ ! -d "/usr/local/nginx/conf/vhost" ]] && mkdir /usr/local/nginx/conf/vhost
mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.backup
cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf
cp conf/vhost/* /usr/local/nginx/conf/vhost/
[[ ! -d ${Default_Website_Dir} ]] && mkdir -p ${Default_Website_Dir}
mv ${Default_Website_Dir}/index.html ${Default_Website_Dir}/index.html.backup
cp res/index.html ${Default_Website_Dir}
chmod +w ${Default_Website_Dir}
chown -R nginx:nginx ${Default_Website_Dir}
cp etc/init.d/nginx /etc/init.d/nginx
chmod a+x /etc/init.d/nginx
chkconfig --add /etc/init.d/nginx
chkconfig nginx on
chkconfig iptables off

echo "[+] Provide web safe... "
cat >${Default_Website_Dir}/.user.ini<<EOF
open_basedir=${Default_Website_Dir}:/tmp/:/proc/
EOF
chmod 644 ${Default_Website_Dir}/.user.ini
chattr +i ${Default_Website_Dir}/.user.ini

echo "[+] Start nginx service... "
service iptables stop
service nginx start

echo "[+] Allright ,enjoy your web... "
