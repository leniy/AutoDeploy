# Install Nginx

## Description

By Leniy Tsan @ 2016.

Install nginx (include proxy_pass) by just one script on a new centos6.8 instalation.

Already considered corresponding optimization, and turn on the reverse proxy functions.

## Usage

clone and use root account, just run this command:

    cd sources
    chmod +x Install_Nginx.sh
    ./Install_Nginx.sh

Then login your server and edit /usr/local/nginx/conf/nginx.conf

    vi /usr/local/nginx/conf/nginx.conf

1. You will find `resolver 114.114.114.114;` and you should change this IP to your own DNS server.

2. Also `proxy_cache_path  ...... max_size=2g;` you can change `max_size=2g` depended on your disk size, such as `max_size=999g`.
