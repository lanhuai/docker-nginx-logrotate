# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.21

MAINTAINER lanhuai <lanhuai@gmail.com>

ENV NGINX_VERSION 1.10.0-0ubuntu0.16.04.4

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get -y update \
    && apt-get -y upgrade \
    && apt-cache madison nginx \
    && apt-get install --no-install-recommends --no-install-suggests -y \
                        ca-certificates \
                        nginx=${NGINX_VERSION} \
                        
    && rm -rf /var/lib/apt/lists/* \
    && groupadd nginx \
    && useradd -d /var/www -g nginx nginx \
    && usermod -s /usr/sbin/nologin nginx \
    && chown -R nginx:nginx /var/www \
# 设置时区 http://stackoverflow.com/questions/40234847/docker-timezone-in-ubuntu-16-04-image
    && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
# 将 cron 的 daily 时间改为每日 00:00
    && cat /etc/crontab \
    && sed -i 's/25 6/0 0/g' /etc/crontab \	

# forward request and error logs to docker log collector
    && mkdir -p /var/log/nginx 
#   && ln -sf /dev/stdout /var/log/nginx/access.log \
#   && ln -sf /dev/stderr /var/log/nginx/error.log


# config nginx
ADD conf/logrotate /etc/logrotate.d/nginx

# Daemons
ADD daemons/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80 443
# VOLUME ["/etc/nginx", "/etc/logrotate.d", "/var/log"]

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]