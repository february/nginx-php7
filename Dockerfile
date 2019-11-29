FROM centos:7
MAINTAINER Skiychan <dev@skiy.net>

ENV NGINX_VERSION 1.17.6
ENV PHP_VERSION 5.6.40

ENV PRO_SERVER_PATH=/data/server
ENV NGX_WWW_ROOT=/data/wwwroot
ENV NGX_LOG_ROOT=/data/wwwlogs
ENV PHP_EXTENSION_SH_PATH=/data/server/php/extension
ENV PHP_EXTENSION_INI_PATH=/data/server/php/ini

## mkdir folders
RUN mkdir -p /data/{wwwroot,wwwlogs,server/php/ini,server/php/extension,}

## install libraries
RUN set -x && \
yum install -y gcc \
gcc-c++ \
autoconf \
automake \
libtool \
make \
cmake \
#
# install PHP libraries
## libmcrypt-devel DIY
# rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
zlib \
zlib-devel \
openssl \
openssl-devel \
pcre-devel \
libxml2 \
libxml2-devel \
libcurl \
libcurl-devel \
libpng-devel \
libjpeg-devel \
freetype-devel \
libmcrypt-devel \
openssh-server && \ 
#
# make temp folder
mkdir -p /home/nginx-php && \
# install nginx
curl -Lk https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
# RUN curl -Lk http://172.17.0.1/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
cd /home/nginx-php/nginx-$NGINX_VERSION && \
./configure --prefix=/usr/local/nginx \
--user=www --group=www \
--error-log-path=${NGX_LOG_ROOT}/nginx_error.log \
--http-log-path=${NGX_LOG_ROOT}/nginx_access.log \
--pid-path=/var/run/nginx.pid \
--with-pcre \
--with-http_ssl_module \
--with-http_v2_module \
--without-mail_pop3_module \
--without-mail_imap_module \
--with-http_gzip_static_module && \
make && make install && \
# add user
useradd -r -s /sbin/nologin -d ${NGX_WWW_ROOT} -m -k no www && \
# ln nginx
cd ${PRO_SERVER_PATH} && ln -s /usr/local/nginx/conf nginx && \
#
# install php
curl -Lk https://php.net/distributions/php-$PHP_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
# curl -Lk http://172.17.0.1/distributions/php-$PHP_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
cd /home/nginx-php/php-$PHP_VERSION && \  
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--with-config-file-scan-dir=${PHP_EXTENSION_INI_PATH} \
--with-fpm-user=www \
--with-fpm-group=www \
--with-mysql \
--with-mysqli \
--with-pdo-mysql \
--with-openssl \
--with-gd \
--with-iconv \
--with-zlib \
--with-gettext \
--with-curl \
--with-png-dir \
--with-jpeg-dir \
--with-freetype-dir \
--with-xmlrpc \
--with-mhash \
--enable-fpm \
--enable-xml \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--enable-mbregex \
--enable-mbstring \
--enable-ftp \
--enable-mysqlnd \
--enable-pcntl \
--enable-sockets \
--enable-soap \
--enable-session \
--enable-opcache \
--enable-bcmath \
--enable-exif \
--enable-fileinfo \
--disable-rpath \
--enable-ipv6 \
--disable-debug \
--without-pear \
--enable-zip --without-libzip && \
make && make install && \
#
# install php-fpm
cd /home/nginx-php/php-$PHP_VERSION && \
cp php.ini-production /usr/local/php/etc/php.ini && \
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 60M/g' /usr/local/php/etc/php.ini && \
sed -i 's/post_max_size = 8M/post_max_size = 60M/g' /usr/local/php/etc/php.ini && \
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/php/etc/php.ini && \
rm -rf /home/nginx-php && \
#
# remove temp folder
rm -rf /home/nginx-php && \
#
# clean os
# RUN yum remove -y gcc \
# gcc-c++ \
# autoconf \
# automake \
# libtool \
# make \
# cmake && \
yum clean all && \
rm -rf /tmp/* /var/cache/{yum,ldconfig} /etc/my.cnf{,.d} && \
mkdir -p --mode=0755 /var/cache/{yum,ldconfig} && \
find /var/log -type f -delete

VOLUME ["/data/wwwroot", "/data/wwwlogs", "/data/server/php/ini", "/data/server/php/extension", "/data/server/nginx"]

# NGINX
ADD nginx.conf /usr/local/nginx/conf/
ADD vhost /usr/local/nginx/conf/vhost

ADD www ${NGX_WWW_ROOT}

# Start
ADD entrypoint.sh /
RUN chown -R www:www ${NGX_WWW_ROOT} && \
chmod +x /entrypoint.sh

# Set port
EXPOSE 80 443

# CMD ["/usr/local/php/sbin/php-fpm", "-F", "daemon off;"]
# CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]

# Start it
ENTRYPOINT ["/entrypoint.sh"]
