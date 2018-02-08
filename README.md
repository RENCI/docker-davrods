# docker-davrods

### An Apache WebDAV interface to iRODS in Docker

This work is based on [UtrechtUniversity/davrods](https://github.com/UtrechtUniversity/davrods).

- Davrods provides access to iRODS servers using the WebDAV protocol. It is a bridge between the WebDAV protocol and the iRODS API, implemented as an Apache HTTPD module.

- Davrods leverages the Apache server implementation of the WebDAV protocol, mod\_dav, for compliance with the WebDAV Class 2 standard.

## Supported tags and respective Dockerfile links

- 4.2.1, latest ([4.2.1/Dockerfile](/4.2.1/Dockerfile))

### Pull image from dockerhub

```
$ docker pull renci/docker-davrods:4.2.1
```

### Build locally

```
$ cd 4.2.1
$ docker build -t docker-davrods:4.2.1 .
```

## Contents

- [Usage](#usage)
- [Example of running environment](#example)
- [Environment variable descriptions](#envvar)
- [WebDAV mount instructions](#mount)
  - macOS
  - Windows
  - CentOS 7
  - Ubuntu 16.04
- [SSL how-to](#ssl)

## <a name="usage"></a>Usage

Provide the iRODS, VirtualHost and SSL settings to the `docker run` or `docker-compose` call using environment variables or an environment file.

- Possible environment variables (and their default values):

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
	# VirtualHost settings
	VHOST_SERVER_NAME='dav.example.com'
	VHOST_LOCATION='/'
	VHOST_DAV_RODS_SERVER='localhost 1247'
	VHOST_DAV_RODS_ZONE='tempZone'
	VHOST_DAV_RODS_AUTH_SCHEME='Native'
	VHOST_DAV_RODS_EXPOSED_ROOT='User'
	# SSL settings
	SSL_ENGINE='off'
	SSL_CERTIFICATE_FILE=''
	SSL_CERTIFICATE_KEY_FILE=''
	```

Minimally the following variables are likely candidates to be updated prior to running against a non-generic deployment of iRODS.

```
IRODS_CLIENT_SERVER_POLICY=CS_NEG_REFUSE
IRODS_SERVER_CONTROL_PLANE_KEY=<USE_REAL_KEY_FROM_IRODS_SERVER>
VHOST_SERVER_NAME=<FQDN_OR_IP_OF_VHOST>
VHOST_DAV_RODS_SERVER=<FQDN_OR_IP_OF_IRODS_SERVER> 1247
VHOST_DAV_RODS_ZONE=<IRODS_ZONE_NAME>
```

- Run a davrods container at [http://localhost:8080](http://localhost:8080) (replacing `<USE_REAL_KEY_FROM_IRODS_SERVER>`, `<FQDN_OR_IP_OF_IRODS_SERVER>`, and `<IRODS_ZONE_NAME>` with appropriate values):

	```
	docker run -d --name davrods \
		-e IRODS_CLIENT_SERVER_POLICY=CS_NEG_REFUSE
		-e IRODS_SERVER_CONTROL_PLANE_KEY=<USE_REAL_KEY_FROM_IRODS_SERVER>
		-e VHOST_SERVER_NAME=localhost
		-e VHOST_DAV_RODS_SERVER='<FQDN_OR_IP_OF_IRODS_SERVER> 1247'
		-e VHOST_DAV_RODS_ZONE=<IRODS_ZONE_NAME>
		-p 8080:80 \
		renci/docker-davrods:4.2.1
	```

- Using the same environment variables as above, but placed into a file named `sample.env`.

	```
	docker run -d --name davrods \
		--env-file sample.env \
		-p 8080:80 \
		renci/docker-davrods:4.2.1
	```

## <a name="example"></a>Example of running environment

### Configure/Build/Run

The provided [docker-compose.yml](/docker-compose.yml) file specifies an example using four containers.

1. davrods
	- DavRODS server running at [http://localhost:8080/tempzone](http://localhost:8080/tempzone)
	- User: **rods**, Pass: **rods**
2. centos-davfs2
	- CentOS 7 based data container with webdav mount at `/mnt/davrods`
3. ubuntu-davfs2
	- Ubuntu 16.04 based data container with webdav mount at `/mnt/davrods`
4. irods
	- iRODS Catalog Provider to support DavRODS

**Configure**:

Under the `environment:` section of the [docker-compose.yml](docker-compose.yml) file we can set a few parameters to be used by the container serving DavRODS. We want to ensure that the `IRODS_*` settings correspond to what is found in the iRODS server we'll be attaching to and so set the connection parameters for the Virtual Host that will run in Apache. Here we are choosing to default to starting at the `Zone` level of the iRODS deployment. The default here would generally be `User`, and a description of these settings can be found in [davrods-vhost.conf](https://github.com/UtrechtUniversity/davrods/blob/master/davrods-vhost.conf).

```yaml
...
environment:
  - IRODS_CLIENT_SERVER_POLICY=CS_NEG_REFUSE
  - IRODS_SERVER_CONTROL_PLANE_KEY=TEMPORARY__32byte_ctrl_plane_key
  - VHOST_SERVER_NAME=davrods.local
  - VHOST_LOCATION=/tempzone
  - VHOST_DAV_RODS_SERVER=irods 1247
  - VHOST_DAV_RODS_ZONE=tempZone
  - VHOST_DAV_RODS_AUTH_SCHEME=Native
  - VHOST_DAV_RODS_EXPOSED_ROOT=Zone
...
```

**Build**:

```
docker-compose build
```

**Run**:

- If you wish to view `STDOUT` of the containers as they run, do not use the `-d` parameter.

```
docker-compose up -d
```

Verify containers are running:

```
$ docker-compose ps
    Name                   Command               State                                          Ports
--------------------------------------------------------------------------------------------------------------------------------------------
centos-davfs2   /usr/local/bin/tini -- /do ...   Up      443/tcp, 80/tcp
davrods         /usr/local/bin/tini -- /do ...   Up      1247/tcp, 0.0.0.0:8443->443/tcp, 0.0.0.0:8080->80/tcp
irods           /irods-docker-entrypoint.s ...   Up      1247/tcp, 1248/tcp, 20000/tcp, 20001/tcp, 20002/tcp, 20003/tcp, 20004/tcp,
                                                         20005/tcp, 20006/tcp, 20007/tcp, 20008/tcp, 20009/tcp, 20010/tcp, 20011/tcp,
                                                         ...
                                                         20187/tcp, 20188/tcp, 20189/tcp, 20190/tcp, 20191/tcp, 20192/tcp, 20193/tcp,
                                                         20194/tcp, 20195/tcp, 20196/tcp, 20197/tcp, 20198/tcp, 20199/tcp, 5432/tcp
ubuntu-davfs2   /usr/local/bin/tini -- /do ...   Up      443/tcp, 80/tcp
```

Test DavRODS connection via browser: [http://localhost:8080/tempzone](http://localhost:8080/tempzone)

- Username: **rods**
- Password: **rods**

<img width="80%" alt="DavRODS initial" src="https://user-images.githubusercontent.com/5332509/35748992-0266f6f4-081e-11e8-8a15-0a6f0994d8c7.png">

Once signed in as the iRODS **rods** user, you should see an empty directory listing.

<img width="80%" alt="DavRODS signed in" src="https://user-images.githubusercontent.com/5332509/35749076-56656286-081e-11e8-8aa2-27ff67412e77.png">

This can also be confirmed from the `irods`, `centos-davfs2` and `ubuntu-davfs2` docker containers.

- From `irods` as the irods user:

	```
	$ docker exec -u irods irods ils /tempZone
	/tempZone:
	  C- /tempZone/home
	  C- /tempZone/trash
	```
- From `centos-davfs2`:

	```
	$ docker exec centos-davfs2 ls -alh /mnt/davrods
	total 512
	drwxr-xr-x 5 root root 136 Feb  2 18:28 .
	drwxr-xr-x 4 root root   0 Feb  2 18:28 home
	drwx------ 2 root root   0 Feb  2 18:28 lost+found
	drwxr-xr-x 3 root root   0 Feb  2 18:28 trash
	```
- From `ubuntu-davfs2`:

	```
	$ docker exec ubuntu-davfs2 ls -alh /mnt/davrods
	total 512
	drwxr-xr-x 5 root root 136 Feb  2 18:28 .
	drwxr-xr-x 4 root root   0 Feb  2 18:28 home
	drwx------ 2 root root   0 Feb  2 18:28 lost+found
	drwxr-xr-x 3 root root   0 Feb  2 18:28 trash
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
		irods@irods:~$ ils -Lr /tempZone/home/rods
		/tempZone/home/rods:
		  rods              0 demoResc          224 2018-02-02.18:45 & VERSION.json
		        generic    /var/lib/irods/iRODS/Vault/home/rods/VERSION.json
		```
	
	- Verify in the browser by navigating to [http://localhost:8080/tempzone/home/rods/](http://localhost:8080/tempzone/home/rods/)
	
	<img width="80%" alt="Add VERSION.json" src="https://user-images.githubusercontent.com/5332509/35749433-8306aa9c-081f-11e8-8327-286da7214864.png">
	
	- Verify on the `centos-davfs2` container

		```
		$ docker exec centos-davfs2 ls -alh /mnt/davrods/home/rods
		total 1.0K
		drwxr-xr-x 2 root root 104 Feb  2 18:28 .
		drwxr-xr-x 4 root root   0 Feb  2 18:28 ..
		-rw-r--r-- 1 root root 224 Feb  2 18:45 VERSION.json
		```
	- Verify on the `ubuntu-davfs2` container
	
		```
		$ docker exec ubuntu-davfs2 ls -alh /mnt/davrods/home/rods
		total 1.0K
		drwxr-xr-x 2 root root 104 Feb  2 18:28 .
		drwxr-xr-x 4 root root   0 Feb  2 18:28 ..
		-rw-r--r-- 1 root root 224 Feb  2 18:45 VERSION.json
		```

2. From the `centos-davfs2` container: Get onto the `datamount` container as the **root** user, generate a 10 MB file, and copy it to the `/mnt/davrods/home/rods` directory

	- Use `dd` to create a 10 MB file and `cp` to copy it

		```
		$ docker exec -ti centos-davfs2 /bin/bash
		[root@centos-davfs2 /]# dd if=/dev/zero of=output.dat  bs=1M  count=10
		10+0 records in
		10+0 records out
		10485760 bytes (10 MB) copied, 0.00735935 s, 1.4 GB/s
		[root@centos-davfs2 /]# ls -alh output.dat
		-rw-r--r-- 1 root root 10M Feb  2 18:51 output.dat
		[root@centos-davfs2 /]# cp output.dat /mnt/davrods/home/rods/
		[root@centos-davfs2 /]# ls -alh /mnt/davrods/home/rods/
		total 11M
		drwxr-xr-x 2 root root 144 Feb  2 18:28 .
		drwxr-xr-x 4 root root 128 Feb  2 18:28 ..
		-rw-r--r-- 1 root root 224 Feb  2 18:45 VERSION.json
		-rw-r--r-- 1 root root 10M Feb  2 18:52 output.dat
		```

	- Verify from the `irods` container

		```
		$ docker exec -u irods irods ils -Lr /tempZone/home/rods
		/tempZone/home/rods:
		  rods              0 demoResc     10485760 2018-02-02.18:52 & output.dat
		        generic    /var/lib/irods/iRODS/Vault/home/rods/output.dat
		  rods              0 demoResc          224 2018-02-02.18:45 & VERSION.json
		        generic    /var/lib/irods/iRODS/Vault/home/rods/VERSION.json
		```
	- Verify from the `ubuntu-davfs2` container

	```
	$ docker exec ubuntu-davfs2 ls -alh /mnt/davrods/home/rods/
	total 11M
	drwxr-xr-x 2 root root 144 Feb  2 18:28 .
	drwxr-xr-x 4 root root   0 Feb  2 18:28 ..
	-rw-r--r-- 1 root root 224 Feb  2 18:45 VERSION.json
	-rw-r--r-- 1 root root 10M Feb  2 18:52 output.dat
	```
	- Verify in the browser by refreshing it

	<img width="80%" alt="Add output.dat" src="https://user-images.githubusercontent.com/5332509/35749775-b55ac0b8-0820-11e8-9cd2-df839ee7d1e5.png">
	
	- Download `output.dat` from browser to local machine
	
	<img width="80%" alt="Download output.dat" src="https://user-images.githubusercontent.com/5332509/35749820-e092fd72-0820-11e8-8224-254edc3e46c4.png">
	
	- Verify size of file on local machine

		```
		$ ls -alh ~/Downloads/output.dat
		-rw-rw-rw-@ 1 stealey  staff    10M Feb  2 13:56 /Users/stealey/Downloads/output.dat
		```

## Clean up

Clean up the environment using `docker-compose`

```
$ docker-compose stop
Stopping ubuntu-davfs2 ... done
Stopping centos-davfs2 ... done
Stopping davrods       ... done
Stopping irods         ... done

$ docker-compose rm -f
Going to remove ubuntu-davfs2, centos-davfs2, davrods, irods
Removing ubuntu-davfs2 ... done
Removing centos-davfs2 ... done
Removing davrods       ... done
Removing irods         ... done

$ docker-compose ps
Name   Command   State   Ports
------------------------------

```

## <a name="envvar"></a>Environment variable descriptions

This implementation makes use of many environment varialbes to set or modify the contents of `/etc/httpd/irods/irods_environment.json` and `/etc/httpd/conf.d/davrods.conf`

- The iRODS environment file:
	- The binary distribution installs the `irods_environment.json` file in `/etc/httpd/irods`. In most iRODS setups, this file can be used as is.
	- Importantly, the first seven options (from `irods_host` up to and including `irods_zone_name`) are not read from this file. These settings are taken from their equivalent Davrods configuration directives in the vhost file instead.
	- The options in the provided environment file starting from `irods_client_server_negotiation` do affect the behaviour of Davrods. See the official documentation for help on these settings at: [https://docs.irods.org/4.2.1/system\_overview/configuration/#irodsirods_environmentjson](https://docs.irods.org/4.2.1/system_overview/configuration/#irodsirods_environmentjson)
	- For instance, if you want Davrods to connect to iRODS 3.3.1, the `irods_client_server_negotiation` option must be set to "none".
	- The default settings are based on the [source repository](https://github.com/UtrechtUniversity/davrods/blob/master/irods_environment.json)

- HTTPD vhost configuration
	- The `davrods.conf` file is copied at build time and then modified at runtime in the Apache `/etc/httpd/conf.d` directory. Attributes outside of the scope altered by the runtime script can be altered directly in the [source file](/4.2.1/httpd_conf/davrods-vhost.conf) prior to building the image.
	- The Davrods RPM distribution installs two vhost template files:
		- `/etc/httpd/conf.d/davrods-vhost.conf`
		- `/etc/httpd/conf.d/davrods-anonymous-vhost.conf`
	- These files are provided completely commented out. To enable either configuration, simply remove the first column of `#` signs, and then tune the settings to your needs.
	- The normal vhost configuration ([1](https://github.com/UtrechtUniversity/davrods/blob/master/davrods-vhost.conf)) provides sane defaults for authenticated access.
	- The anonymous vhost configuration ([2](https://github.com/UtrechtUniversity/davrods/blob/master/davrods-anonymous-vhost.conf)) allows password-less public access using the anonymous iRODS account.
	- You can enable both configurations simultaneously, as long as their ServerName values are unique (for example, you might use [dav.example.com]() for authenticated access and [public.dav.example.com]() for anonymous access).


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

## <a name="mount"></a>WebDAV mount instructions

Web Distributed Authoring and Versioning (WebDAV) is an extension of the Hypertext Transfer Protocol (HTTP) that allows clients to perform remote Web content authoring operations.

Linux Note:

- Uses [davfs2](http://savannah.nongnu.org/projects/davfs2) package.
- Ubuntu warning: The file `/sbin/mount.davfs` must have the SUID bit set if you want to allow unprivileged (non-root) users to mount WebDAV resources.
- If using Docker, the following `run` parameters should be set

	```
	--privileged 
	--cap-add=SYS_ADMIN 
	--device /dev/fuse
	```

### macOS

Open the **Connect to Server** dialogue

- Finder: Go > Connect to Server, or `command` + `k`

Set 

- Server Address: [http://localhost:8080/tempzone]()

<img width="80%" alt="Connect to Server" src="https://user-images.githubusercontent.com/5332509/35828172-925a24fa-0a8c-11e8-8add-9e7ea49fe9a8.png">

Connect:

- Name: **rods**
- Password: **rods**

<img width="80%" alt="Name and Password" src="https://user-images.githubusercontent.com/5332509/35828220-b8573918-0a8c-11e8-9016-a11d865a2963.png">

Access

- Volume mount from Finder named **tempzone**

<img width="80%" alt="Finder volume mount" src="https://user-images.githubusercontent.com/5332509/35828266-dfe928e2-0a8c-11e8-8a9a-64a2516c3182.png">

### Windows

TODO

### CentOS 7

Install:

```
sudo yum install epel-release
sudo yum makecache fast
sudo yum install davfs2
```

Mount:

- Format: `mount -t davfs http(s)://addres:<port>/path /mount/point`
	- `REMOTE_URL` - URL to reflect as local mount point, i.e. [http://localhost:8080/tempzone/](http://localhost:8080/tempzone/) 
	- `LOCAL_MOUNT` - local mount point, i.e. `/mnt/davrods`

	```
	sudo mkdir LOCAL_MOUNT
	sudo mount -t davfs REMOTE_URL LOCAL_MOUNT
	```

Unmount:

- Format: `umount -t davfs /mount/point`
	- `LOCAL_MOUNT` - local mount point, i.e. `/mnt/davrods`

	```
	sudo umount -t davfs LOCAL_MOUNT
	```

Storing credentials:

- Create a secrets file to store credentials for a WebDAV-service using `~/.davfs2/secrets` for user, and `/etc/davfs2/secrets` for root:

	- Format:

		```
		https://webdav.example/path davusername davpassword
		```

- Make sure the secrets file contains the correct permissions, for root mounting:

	```
	# chmod 600 /etc/davfs2/secrets
	# chown root:root /etc/davfs2/secrets
	```

- And for user mounting:

	```
	$ chmod 600 ~/.davfs2/secrets
	```

See [centos-davfs2/Dockerfile](/example/centos-davfs2/Dockerfile) for example implementation.

### Ubuntu 16.04

Install:

```
sudo apt install davfs2
```

Mount:

- Format: `mount -t davfs http(s)://addres:<port>/path /mount/point`
	- `REMOTE_URL` - URL to reflect as local mount point, i.e. [http://localhost:8080/tempzone/](http://localhost:8080/tempzone/) 
	- `LOCAL_MOUNT` - local mount point, i.e. `/mnt/davrods`

	```
	sudo mkdir LOCAL_MOUNT
	sudo mount -t davfs REMOTE_URL LOCAL_MOUNT
	```

Unmount:

- Format: `umount -t davfs /mount/point`
	- `LOCAL_MOUNT` - local mount point, i.e. `/mnt/davrods`

	```
	sudo umount -t davfs LOCAL_MOUNT
	```

Storing credentials:

- Create a secrets file to store credentials for a WebDAV-service using `~/.davfs2/secrets` for user, and `/etc/davfs2/secrets` for root:

	- Format:

		```
		https://webdav.example/path davusername davpassword
		```

- Make sure the secrets file contains the correct permissions, for root mounting:

	```
	# chmod 600 /etc/davfs2/secrets
	# chown root:root /etc/davfs2/secrets
	```

- And for user mounting:

	```
	$ chmod 600 ~/.davfs2/secrets
	```

See [ubuntu-davfs2/Dockerfile](/example/ubuntu-davfs2/Dockerfile) for example implementation.

## <a name="ssl"></a>SSL

To avoid cleartext password communication we strongly recommend to enable DavRODS only over SSL.

### Example: Serving NWM data

**Goal** - Expose NWM data starting at `/nwmZone/home/nwm/data/nomads` as [https://apps-ffs.renci.org:8443/nwm/daily](https://apps-ffs.renci.org:8443/nwm/daily)

Ensure a valid certificate pair exists on the server and is shareable via volume mount with the container.

We'll map `/root/cert` to `/ssl_cert` of the container which contains

- `star_renci_org.crt`: certificate
- `star_renci_org.key`: key

Update the `docker-compose.yml` file

- `IRODS_*` and `VHOST_*` settings get applied
- `SSL_ENGINE=` set to `on`
- `SSL_CERTIFICATE_FILE=` set to `/ssl_cert/star_renci_org.crt`
- `SSL_CERTIFICATE_KEY_FILE=` set to `/ssl_cert/star_renci_org.key`

	```yaml
	version: '3.1'
	services:
	  davrods:
	    image: renci/docker-davrods:4.2.1
	    container_name: davrods
	    hostname: davrods-local
	    ports:
	      - '8080:80'
	      - '8443:443'
	    environment:
	      - IRODS_CWD=/nwmZone/home/nwm/data/nomads
	      - IRODS_CLIENT_SERVER_POLICY=CS_NEG_REFUSE
	      - IRODS_SERVER_CONTROL_PLANE_KEY=<USE_REAL_KEY_FROM_IRODS_SERVER>
	      - VHOST_SERVER_NAME=apps-ffs.renci.org
	      - VHOST_LOCATION=/nwm/daily
	      - VHOST_DAV_RODS_SERVER=nwm.renci.org 1247
	      - VHOST_DAV_RODS_ZONE=nwmZone
	      - VHOST_DAV_RODS_AUTH_SCHEME=Native
	      - VHOST_DAV_RODS_EXPOSED_ROOT=/nwmZone/home/nwm/data/nomads
	      - SSL_ENGINE=on
	      - SSL_CERTIFICATE_FILE=/ssl_cert/star_renci_org.crt
	      - SSL_CERTIFICATE_KEY_FILE=/ssl_cert/star_renci_org.key
	    restart: always
	    volumes:
	      - './4.2.1/davrods_conf.d:/etc/httpd/davrods_conf.d'
	      - '/root/cert:/ssl_cert'
	```

Run the container using `docker-compose`

```
docker-compose up -d
```
Validate use of SSL certs at: [https://apps-ffs.renci.org:8443/nwm/daily](https://apps-ffs.renci.org:8443/nwm/daily)

<img width="80%" alt="SSL NWM deploy" src="https://user-images.githubusercontent.com/5332509/35827339-99d24efe-0a89-11e8-95f3-d61bf7cb344d.png">