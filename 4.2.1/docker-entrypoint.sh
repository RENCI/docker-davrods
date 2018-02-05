#!/usr/bin/env bash
set -e

_irods_environment_json() {
    local OUTFILE=/etc/httpd/irods/irods_environment.json
    jq -n \
        --arg host "${IRODS_HOST}" \
        --argjson port "${IRODS_PORT}" \
        --arg resc "${IRODS_DEFAULT_RESOURCE}" \
        --arg home "${IRODS_HOME}" \
        --arg cwd "${IRODS_CWD}" \
        --arg user "${IRODS_USER_NAME}" \
        --arg zone "${IRODS_ZONE_NAME}" \
        --arg cneg "${IRODS_CLIENT_SERVER_NEGOTIATION}" \
        --arg cpol "${IRODS_CLIENT_SERVER_POLICY}" \
        --argjson ekey "${IRODS_ENCRYPTION_KEY_SIZE}" \
        --argjson esalt "${IRODS_ENCRYPTION_SALT_SIZE}" \
        --argjson ehash "${IRODS_ENCRYPTION_NUM_HASH_ROUNDS}" \
        --arg ealgo "${IRODS_ENCRYPTION_ALGORITHM}" \
        --arg dhash "${IRODS_DEFAULT_HASH_SCHEME}" \
        --arg mhash "${IRODS_MATCH_HASH_POLICY}" \
        --argjson cpport "${IRODS_SERVER_CONTROL_PLANE_PORT}" \
        --arg cpkey "${IRODS_SERVER_CONTROL_PLANE_KEY}" \
        --argjson cphash "${IRODS_SERVER_CONTROL_PLANE_ENCRYPTION_NUM_HASH_ROUNDS}" \
        --arg cpalgo "${IRODS_SERVER_CONTROL_PLANE_ENCRYPTION_ALGORITHM}" \
        --argjson bmax "${IRODS_MAXIMUM_SIZE_FOR_SINGLE_BUFFER_IN_MEGABYTES}" \
        --argjson nthr "${IRODS_DEFAULT_NUMBER_OF_TRANSFER_THREADS}" \
        --argjson bsize "${IRODS_TRANSFER_BUFFER_SIZE_FOR_PARALLEL_TRANSFER_IN_MEGABYTES}" \
        --arg sslsvr "${IRODS_SSL_VERIFY_SERVER}" \
        '{"irods_host": $host,
        "irods_port": $port,
        "irods_default_resource": $resc,
        "irods_home": $home,
        "irods_cwd": $cwd,
        "irods_user_name": $user,
        "irods_zone_name": $zone,
        "irods_client_server_negotiation": $cneg,
        "irods_client_server_policy": $cpol,
        "irods_encryption_key_size": $ekey,
        "irods_encryption_salt_size": $esalt,
        "irods_encryption_num_hash_rounds": $ehash,
        "irods_encryption_algorithm": $ealgo,
        "irods_default_hash_scheme": $dhash,
        "irods_match_hash_policy": $mhash,
        "irods_server_control_plane_port": $cpport,
        "irods_server_control_plane_key": $cpkey,
        "irods_server_control_plane_encryption_num_hash_rounds": $cphash,
        "irods_server_control_plane_encryption_algorithm": $cpalgo,
        "irods_maximum_size_for_single_buffer_in_megabytes": $bmax,
        "irods_default_number_of_transfer_threads": $nthr,
        "irods_transfer_buffer_size_for_parallel_transfer_in_megabytes": $bsize,
        "irods_ssl_verify_server": $sslsvr}' > $OUTFILE
}

_vhost_conf () {
    if [[ -f /etc/httpd/davrods_conf.d/davrods-vhost.conf ]]; then
        local OUTFILE=/etc/httpd/davrods_conf.d/davrods-vhost.conf
        if [[ "${SSL_ENGINE,,}" == 'on' ]]; then
            # SSL settings
            sed -i 's!#LoadModule ssl_module modules/mod_ssl.so!LoadModule ssl_module modules/mod_ssl.so!' $OUTFILE
            sed -i 's!<VirtualHost \*:80>!<VirtualHost \*:443>!' $OUTFILE
            sed -i 's!#SSLEngine off!SSLEngine on!' $OUTFILE
            sed -i 's!#SSLCertificateFile ""!SSLCertificateFile '"${SSL_CERTIFICATE_FILE}"'!' $OUTFILE
            sed -i 's!#SSLCertificateKeyFile ""!SSLCertificateKeyFile '"${SSL_CERTIFICATE_KEY_FILE}"'!' $OUTFILE
        fi
        # VirtualHost settings
        sed -i 's!ServerName dav.example.com!ServerName '"${VHOST_SERVER_NAME}"'!' $OUTFILE
        sed -i 's!<Location />!<Location '"${VHOST_LOCATION}"'>!' $OUTFILE
        sed -i 's!#DavRodsServer localhost 1247!DavRodsServer '"${VHOST_DAV_RODS_SERVER}"'!' $OUTFILE
        sed -i 's!#DavRodsZone tempZone!DavRodsZone '"${VHOST_DAV_RODS_ZONE}"'!' $OUTFILE
        sed -i 's!#DavRodsAuthScheme Native!DavRodsAuthScheme '"${VHOST_DAV_RODS_AUTH_SCHEME}"'!' $OUTFILE
        sed -i 's!#DavRodsExposedRoot  User!DavRodsExposedRoot  '"${VHOST_DAV_RODS_EXPOSED_ROOT}"'!' $OUTFILE
    fi
}

echo "IncludeOptional /etc/httpd/davrods_conf.d/*.conf" >> /etc/httpd/conf/httpd.conf
_irods_environment_json
_vhost_conf

# start the apache daemon
exec /usr/sbin/apachectl -DFOREGROUND
