FROM krallin/ubuntu-tini:16.04
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN apt-get update \
    && cat <<EOF | debconf-set-selections \
davfs2 davfs2/suid_file boolean false \
EOF \
    && apt install -y davfs2

ENV LOCAL_MOUNT='/mnt/davrods'
ENV DAVRODS_MOUNT='davrods'
ENV DAVRODS_USERNAME='rods'
ENV DAVRODS_PASSWORD='rods'

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
