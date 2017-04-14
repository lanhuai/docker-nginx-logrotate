# 支持日志分割的 Nginx 镜像

* 基于 [baseimage-docker](https://github.com/phusion/baseimage-docker)
* 根据情况，可能需要自定义的配置文件：

  > 自定义的配置文件需要使用 docker volume 方式
  
  - 如果你的 `nginx.pid` 和 `nginx日志` 的路径与 `./conf/logrotate` 中的不一样，则需要自定义 `logrotate`
  - `nginx.conf` 也可以自定义，注意日志路径配置

  例子：`docker-compose.yml`

```yml
version: '2'
services:
  web:
    build: .
    ports:
      - "80:80"
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logrotate.conf:/etc/logrotate.d/nginx:ro
      - /root/nginx_logs:/data/wwwlogs/
```

* 使用方法：
  
  - 启动：
    
     ```bash
	  docker-compose up -d
	  ```
  - 停止：
  
     ```bash
	  docker-compose stop
	  ```
	  
	- 停止并删除 containers：
  
     ```bash
	  docker-compose down
	  ```
	  
	- 查看正在运行的 containers：
  
     ```bash
	  docker-compose ps
	  ```


## Nginx 配置

* `/var/www/html`: The actual web content, which by default only consists of the default Nginx page you saw earlier, is served out of the `/var/www/html` directory. This can be changed by altering Nginx configuration files.
* `/etc/logrotate.d/nginx`: Nginx 的日志分割配置
* `/etc/nginx/nginx.conf`: Nginx 全局配置
* `/etc/nginx/sites-available`: Ubuntu 中 `apt-get` 安装的 Nginx 特有的目录，其他 Linux 发行版没有，The directory where per-site "server blocks" can be stored. Nginx will not use the configuration files found in this directory unless they are linked to the `sites-enabled` directory (see below). Typically, all server block configuration is done in this directory, and then enabled by linking to the other directory.
* `/etc/nginx/sites-enabled/`: Ubuntu 中 `apt-get` 安装的 Nginx 特有的目录，其他 Linux 发行版没有，The directory where enabled per-site "server blocks" are stored. Typically, these are created by linking to configuration files found in the `sites-available` directory.
* `/etc/nginx/snippets`: Ubuntu 中 `apt-get` 安装的 Nginx 特有的目录，其他 Linux 发行版没有， This directory contains configuration fragments that can be included elsewhere in the Nginx configuration. Potentially repeatable configuration segments are good candidates for refactoring into snippets.

## Nginx 日志

* `/var/log/nginx/access.log`: Every request to your web server is recorded in this log file unless Nginx is configured to do otherwise.
* `/var/log/nginx/error.log`: Any Nginx errors will be recorded in this log.

## logrotate 配置说明

[完整说明](http://www.linuxcommand.org/man_pages/logrotate8.html)

[被遗忘的Logrotate](https://huoding.com/2013/04/21/246)

* logrotate 依靠 `/var/lib/logrotate/status` 中的记录来决定日志是否需要 rotate，第一次执行时 `/var/lib/logrotate/status` 不存在，或者其中没有信息，不知道上次 rotation 发生在什么时候，它就在 `/var/lib/logrotate/status` 写入一条状态，表示今天自己运行过一次，等到第二天运行时，日志文件就会正常 rotate 了
* 如果不想多等一天，可以手动在 `/var/lib/logrotate/status` 中加入 ` "/var/log/httpd/access_log" 2012-5-11` 这样的信息

```
# Rotate logs
/path/to/your/current/log/*.log {
  daily
  dateext
  missingok
  rotate 30
  compress
  delaycompress
  notifempty
  # copytruncate
  sharedscripts
  postrotate
    if [ -f /usr/local/nginx/logs/nginx.pid ]; then
        kill -USR1 `cat /usr/local/nginx/logs/nginx.pid`
    fi
  endscript
}
```

- 其中 daily 表示每天整理，也可以改成 weekly 或 monthly
- dateext 表示檔案補上 rotate 的日期
- missingok 表示如果找不到 log 檔也沒關係
- rotate 30 表示保留30份
- compress 表示壓縮起來，預設用 gzip。不過如果硬碟空間多，不壓也沒關係。
- delaycompress 表示延後壓縮直到下一次 rotate
- notifempty 表示如果 log 檔是空的，就不 rotate
- copytruncate 先複製 log 檔的內容後，在清空的作法，因為有些程式一定 log 在本來的檔名，例如 rails。另一種方法是 create。
- copytruncate 方式在日志太大的时候，复制很慢，而且导致丢失一些日志，可以使用 postrotate 方式，日志文件重命名后，给 nginx 进程发送 USR1 信号，nginx 会自己重新生成日志文件
- sharedscripts 在前面Nginx的例子里声明日志文件的时候用了星号通配符，也就是说这里可能涉及多个日志文件，比如：access.log和error.log。说到这里大家或许就明白了，sharedscripts的作用是在所有的日志文件都轮转完毕后统一执行一次脚本。如果没有配置这条指令，那么每个日志文件轮转完毕后都会执行一次脚本。

設定好之後，可以等明天，或是執行 `/usr/sbin/logrotate -f /etc/logrotate.conf` 看看。


