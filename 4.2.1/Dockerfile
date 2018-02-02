FROM krallin/centos-tini:centos7
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN yum -y install \
    sudo \
    wget \
    epel-release \
    mod_ssl \
    && wget https://github.com/UtrechtUniversity/davrods/releases/download/4.2.1_1.3.0/davrods-4.2.1_1.3.0-1.rpm \
    && rpm --import https://packages.irods.org/irods-signing-key.asc \
    && wget -qO - https://packages.irods.org/renci-irods.yum.repo | \
    tee /etc/yum.repos.d/renci-irods.yum.repo \
    && yum -y makecache fast \
    && yum -y install jq \
    && yum -y localinstall davrods-4.2.1_1.3.0-1.rpm

# irods_environment.json
ENV IRODS_HOST='localhost'
ENV IRODS_PORT=1247
ENV IRODS_DEFAULT_RESOURCE=''
ENV IRODS_HOME='/tempZone/home/rods'
ENV IRODS_CWD='/tempZone/home/rods'
ENV IRODS_USER_NAME='rods'
ENV IRODS_ZONE_NAME='tempZone'
ENV IRODS_CLIENT_SERVER_NEGOTIATION='request_server_negotiation'
ENV IRODS_CLIENT_SERVER_POLICY='CS_NEG_DONT_CARE'
ENV IRODS_ENCRYPTION_KEY_SIZE=32
ENV IRODS_ENCRYPTION_SALT_SIZE=8
ENV IRODS_ENCRYPTION_NUM_HASH_ROUNDS=16
ENV IRODS_ENCRYPTION_ALGORITHM='AES-256-CBC'
ENV IRODS_DEFAULT_HASH_SCHEME='SHA256'
ENV IRODS_MATCH_HASH_POLICY='compatible'
ENV IRODS_SERVER_CONTROL_PLANE_PORT=1248
ENV IRODS_SERVER_CONTROL_PLANE_KEY='TEMPORARY__32byte_ctrl_plane_key'
ENV IRODS_SERVER_CONTROL_PLANE_ENCRYPTION_NUM_HASH_ROUNDS=16
ENV IRODS_SERVER_CONTROL_PLANE_ENCRYPTION_ALGORITHM='AES-256-CBC'
ENV IRODS_MAXIMUM_SIZE_FOR_SINGLE_BUFFER_IN_MEGABYTES=32
ENV IRODS_DEFAULT_NUMBER_OF_TRANSFER_THREADS=4
ENV IRODS_TRANSFER_BUFFER_SIZE_FOR_PARALLEL_TRANSFER_IN_MEGABYTES=4
ENV IRODS_SSL_VERIFY_SERVER='hostname'
# SSL settings
ENV SSL_ENGINE='off'
ENV SSL_CERTIFICATE_FILE=''
ENV SSL_CERTIFICATE_KEY_FILE=''
# VirtualHost settings
ENV VHOST_SERVER_NAME='dav.example.com'
ENV VHOST_LOCATION='/'
ENV VHOST_DAV_RODS_SERVER='localhost 1247'
ENV VHOST_DAV_RODS_ZONE='tempZone'
ENV VHOST_DAV_RODS_AUTH_SCHEME='Native'
ENV VHOST_DAV_RODS_EXPOSED_ROOT='User'

VOLUME ["/etc/httpd/davrods_conf.d", "/ssl_cert"]

COPY ./davrods_conf.d /etc/httpd/davrods_conf.d
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

# forward request and error logs to docker log collector
# /var/log/httpd/ {access_log  error_log  ssl_access_log  ssl_error_log  ssl_request_log}
RUN ln -sf /dev/stdout /var/log/httpd/access_log \
    && ln -sf /dev/stderr /var/log/httpd/error_log \
    && ln -sf /dev/stderr /var/log/httpd/ssl_access_log \
    && ln -sf /dev/stderr /var/log/httpd/ssl_error_log \
    && ln -sf /dev/stderr /var/log/httpd/ssl_request_log
    
EXPOSE 80 443 1247

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]