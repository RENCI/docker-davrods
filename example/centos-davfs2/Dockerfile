FROM krallin/centos-tini:centos7
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN yum -y install epel-release \
    && yum -y install davfs2

ENV LOCAL_MOUNT='/mnt/davrods'
ENV DAVRODS_MOUNT='davrods'
ENV DAVRODS_USERNAME='rods'
ENV DAVRODS_PASSWORD='rods'

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
