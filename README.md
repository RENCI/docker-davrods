# docker-davrods

An Apache WebDAV interface to iRODS in Docker

This work is based on [UtrechtUniversity/davrods](https://github.com/UtrechtUniversity/davrods).

- Davrods provides access to iRODS servers using the WebDAV protocol. It is a bridge between the WebDAV protocol and the iRODS API, implemented as an Apache HTTPD module.

- Davrods leverages the Apache server implementation of the WebDAV protocol, mod\_dav, for compliance with the WebDAV Class 2 standard.

## Contents

- [Example of running environment](#example)
- [Environment variable descriptions](#envvar)
- [WebDAV mount instructions](#mount)
  - macOS
  - Windows
  - CentOS 7
  - Ubuntu 16.04
- [SSL how-to](#ssl)

## <a name="example"></a>Example of running environment

### Setup

The provided [docker-compose.yml](/docker-compose.yml) file specifies an example using three containers.

1. davrods
	- DavRODS server running at [http://localhost:8080/tempzone](http://localhost:8080/tempzone)
	- User: **rods**, Pass: **rods**
2. datamount
	- Data container with webdav mount at `/mnt/davrods`
3. irods
	- iRODS Catalog Provider to support DavRODS

Build:

```
docker-compose build
```

Run:

```
docker-compose up -d
```

Verify containers are running:

```
$ docker-compose ps
  Name                 Command               State                                            Ports
--------------------------------------------------------------------------------------------------------------------------------------------
datamount   /docker-entrypoint.sh            Up      443/tcp, 0.0.0.0:32786->80/tcp
davrods     /docker-entrypoint.sh tail ...   Up      1247/tcp, 443/tcp, 0.0.0.0:8080->80/tcp
irods       /irods-docker-entrypoint.s ...   Up      1247/tcp, 1248/tcp, 20000/tcp, 20001/tcp, 20002/tcp, 20003/tcp, 20004/tcp, 20005/tcp,
                                                     20006/tcp, 20007/tcp, 20008/tcp, 20009/tcp, 20010/tcp, 20011/tcp, 20012/tcp, 20013/tcp,
                                                     20014/tcp, 20015/tcp, 20016/tcp, 20017/tcp, 20018/tcp, 20019/tcp, 20020/tcp, 20021/tcp,
                                                     ...
                                                     20190/tcp, 20191/tcp, 20192/tcp, 20193/tcp, 20194/tcp, 20195/tcp, 20196/tcp, 20197/tcp,
                                                     20198/tcp, 20199/tcp, 5432/tcp
```

Test DavRODS connection via browser: [http://localhost:8080/tempzone](http://localhost:8080/tempzone)

- Username: **rods**
- Password: **rods**

<img width="80%" alt="DavRODS initial" src="https://user-images.githubusercontent.com/5332509/35699223-68de5c90-075d-11e8-895e-7c042dbede33.png">

Once signed in as the iRODS **rods** user, you should see an empty directory listing.

<img width="80%" alt="DavRODS signed in" src="https://user-images.githubusercontent.com/5332509/35699253-7c73bd9a-075d-11e8-839d-477de3dcc0f7.png">

This can also be confirmed from the `irods` and `datamount` docker container.

- On `irods`:

	```
	$ docker exec -u irods irods ils -Lr
	/tempZone/home/rods:
	```
- On `datamount `:

	```
	$ docker exec datamount ls -alh /mnt/davrods
	total 512
	drwxr-xr-x 3 root root 72 Feb  1 19:31 .
	drwx------ 2 root root  0 Feb  1 19:31 lost+found
	```

### Add data

Validate that data can be added to iRODS and be accessible to available mount points.

1. From the `irods` container: Get onto the `irods` container as the **irods** user and add a file to `/tempZone/home/rods`

	- Use `iput` to add the `VERSION.json` file to `/tempZone/home/rods`
	
		```
		$ docker exec -ti -u irods irods /bin/bash
		irods@irods:~$ ls
		clients		       iRODS	 msiExecCmd_bin  test
		config		       irodsctl  packaging	 VERSION.json
		configuration_schemas  log	 scripts	 VERSION.json.dist
		irods@irods:~$ iput VERSION.json
		irods@irods:~$ ils -Lr
		/tempZone/home/rods:
		  rods              0 demoResc          224 2018-02-01.19:47 & VERSION.json
		        generic    /var/lib/irods/iRODS/Vault/home/rods/VERSION.json
		```
	
	- Verify in the browser by refreshing it
	
	<img width="80%" alt="Add VERSION.json" src="https://user-images.githubusercontent.com/5332509/35699804-20516452-075f-11e8-8ada-bb7214bba06f.png">
	
	- Verify on the `datamount` container
	
		```
		$ docker exec datamount ls -alh /mnt/davrods
		total 1.0K
		drwxr-xr-x 3 root root 112 Feb  1 19:31 .
		-rw-r--r-- 1 root root 224 Feb  1 19:47 VERSION.json
		drwx------ 2 root root   0 Feb  1 19:31 lost+found
		```

2. From the `datamount` container: Get onto the `datamount` container as the **root** user, generate a 10 MB file, and copy it to the `/mnt/davrods` directory

	- Use `dd` to create a 10 MB file and `cp` to copy it

		```
		$ docker exec -ti datamount /bin/bash
		[root@datamount /]# dd if=/dev/zero of=output.dat  bs=1M  count=10
		10+0 records in
		10+0 records out
		10485760 bytes (10 MB) copied, 0.00690478 s, 1.5 GB/s
		[root@datamount /]# ls -alh output.dat
		-rw-r--r-- 1 root root 10M Feb  1 19:58 output.dat
		[root@datamount /]# cp output.dat /mnt/davrods/
		[root@datamount /]# ls -alh /mnt/davrods/
		total 11M
		drwxr-xr-x 3 root root 152 Feb  1 19:31 .
		-rw-r--r-- 1 root root 224 Feb  1 19:47 VERSION.json
		drwx------ 2 root root   0 Feb  1 19:31 lost+found
		-rw-r--r-- 1 root root 10M Feb  1 19:58 output.dat
		```

	- Verify from the `irods` container

		```
		irods@irods:~$ ils -Lr
		/tempZone/home/rods:
		  rods              0 demoResc     10485760 2018-02-01.19:58 & output.dat
		        generic    /var/lib/irods/iRODS/Vault/home/rods/output.dat
		  rods              0 demoResc          224 2018-02-01.19:47 & VERSION.json
		        generic    /var/lib/irods/iRODS/Vault/home/rods/VERSION.json
		```

	- Verify in the browser by refreshing it

	<img width="80%" alt="Add output.dat" src="https://user-images.githubusercontent.com/5332509/35700406-e49a4332-0760-11e8-9447-0aadf295cb40.png">
	
	- Download `output.dat` from browser to local machine
	
	<img width="80%" alt="Download output.dat" src="https://user-images.githubusercontent.com/5332509/35700615-7e29da12-0761-11e8-8d49-40201af17e4f.png">
	
	- Verify size of file on local machine

		```
		$ ls -alh ~/Downloads/output.dat
		-rw-r--r--@ 1 stealey  staff    10M Feb  1 15:05 /Users/stealey/Downloads/output.dat
		```

## Clean up

Clean up the environment using `docker-compose`

```
$ docker-compose stop
Stopping datamount ... done
Stopping davrods   ... done
Stopping irods     ... done

$ docker-compose rm -f
Going to remove datamount, davrods, irods
Removing datamount ... done
Removing davrods   ... done
Removing irods     ... done

$ docker-compose ps
Name   Command   State   Ports
------------------------------

```

## <a name="envvar"></a>Environment variable descriptions

This implementation makes use of many environment varialbes to set or modify the contents of `/etc/httpd/irods/irods_environment.json` and `/etc/httpd/conf.d/davrods.conf`

- The `irods_environment.json` file is generated at runtime as a JSON stanza and the default settings are based on the [source repository](https://github.com/UtrechtUniversity/davrods/blob/master/irods_environment.json)
- The `davrods.conf` file is copied at build time and then modified at runtime in the Apache `/etc/httpd/conf.d` directory. Attributes outside of the scope altered by the runtime script can be altered directly in the [source file](/4.2.1/httpd_conf/davrods-vhost.conf) prior to building the image.

Default settings:

```bash
# irods_environment.json
IRODS_HOST='localhost'
IRODS_PORT=1247
IRODS_DEFAULT_RESOURCE=''
IRODS_HOME='/tempZone/home/rods'
IRODS_CWD='/tempZone/home/rods'
IRODS_USER_NAME='rods'
IRODS_ZONE_NAME='tempZone'
IRODS_CLIENT_SERVER_NEGOTIATION='request_server_negotiation'
IRODS_CLIENT_SERVER_POLICY='CS_NEG_DONT_CARE'
IRODS_ENCRYPTION_KEY_SIZE=32
IRODS_ENCRYPTION_SALT_SIZE=8
IRODS_ENCRYPTION_NUM_HASH_ROUNDS=16
IRODS_ENCRYPTION_ALGORITHM='AES-256-CBC'
IRODS_DEFAULT_HASH_SCHEME='SHA256'
IRODS_MATCH_HASH_POLICY='compatible'
IRODS_SERVER_CONTROL_PLANE_PORT=1248
IRODS_SERVER_CONTROL_PLANE_KEY='TEMPORARY__32byte_ctrl_plane_key'
IRODS_SERVER_CONTROL_PLANE_ENCRYPTION_NUM_HASH_ROUNDS=16
IRODS_SERVER_CONTROL_PLANE_ENCRYPTION_ALGORITHM='AES-256-CBC'
IRODS_MAXIMUM_SIZE_FOR_SINGLE_BUFFER_IN_MEGABYTES=32
IRODS_DEFAULT_NUMBER_OF_TRANSFER_THREADS=4
IRODS_TRANSFER_BUFFER_SIZE_FOR_PARALLEL_TRANSFER_IN_MEGABYTES=4
IRODS_SSL_VERIFY_SERVER='hostname'
# SSL settings
SSL_ENGINE='off'
SSL_CERTIFICATE_FILE=''
SSL_CERTIFICATE_KEY_FILE=''
# VirtualHost settings
VHOST_SERVER_NAME='dav.example.com'
VHOST_LOCATION='/'
VHOST_DAV_RODS_SERVER='localhost 1247'
VHOST_DAV_RODS_ZONE='tempZone'
VHOST_DAV_RODS_AUTH_SCHEME='Native'
VHOST_DAV_RODS_EXPOSED_ROOT='User'
```

Default settings can be overwritten by:

- Altering the Dockerfile or source files directly prior to build
- Adding `-e ENV_VAR_KEY=ENV_VAR_VALUE` to the docker run call (or corresponding docker-compose.yml file)
- Adding `-env-file ENV_FILE_NAME` pointing to a file with one or more variable definitions to the docker run call (or corresponding docker-compose.yml file)

## <a name="webdav"></a>WebDAV mount instructions

Web Distributed Authoring and Versioning (WebDAV) is an extension of the Hypertext Transfer Protocol (HTTP) that allows clients to perform remote Web content authoring operations.

### macOS
### Windows
### CentOS 7
### Ubuntu 16.04

## <a name="ssl"></a>SSL

To avoid cleartext password communication we strongly recommend to enable DavRODS only over SSL.

