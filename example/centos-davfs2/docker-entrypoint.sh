#!/usr/bin/env bash
set -e

sleep 2
echo "${DAVRODS_MOUNT} ${DAVRODS_USERNAME} ${DAVRODS_PASSWORD}" >> /etc/davfs2/secrets
[[ -d ${LOCAL_MOUNT} ]] || mkdir -p ${LOCAL_MOUNT}
sleep 2
# mount -t davfs http(s)://addres:<port>/path /mount/point
mount -t davfs ${DAVRODS_MOUNT} ${LOCAL_MOUNT}

tail -f /dev/null
