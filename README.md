# docker-squid

Squid proxy which avoids sending local network trafic to a remote proxy

Simplifies proxy configuration for local development

+ Configure a remote (parent) proxy with standard environment variables
+ Connections to local servers go directly to them
+ External connections go through the parent proxy

# Getting started

## Build docker image

Behind another proxy
```bash
docker build -t roicostas/squid \
             --build-arg http_proxy=http://myproxy.com:port \
             --build-arg https_proxy=https://myproxy.com:port \
             github.com/roicostas/docker-squid                                  
```

Without proxy
```bash
docker build -t roicostas/squid github.com/roicostas/docker-squid
```

## Quickstart

Start proxy with docker run:

```bash
docker run --name squid -d --restart=always \
  --publish 3128:3128 \
  -e http_proxy=http://user:password@myproxy.com:1234 \
  -e https_proxy=https://user:password@myproxy.com:1234 \
  --volume squid-cache:/var/spool/squid3 \
  roicostas/squid
```

Start proxy with docker-compose in local machine:

```bash
export http_proxy=http://user:password@myproxy.com:1234
export https_proxy=https://user:password@myproxy.com:1234
docker-compose up -d
```

For running docker-compose remotely set http_proxy and https_proxy variables y docker-compose.yml file

## Command-line arguments

You can customize the launch command of the Squid server by specifying arguments to `squid3` on the `docker run` command, e.g print help:

```bash
docker run --rm roicostas/squid -h
```

## Configuration

http_proxy and https_proxy environment vars are used to configure parent servers which generate cache_peer configuration lines. If no proxy configuration is provided it works as a normal proxy

A custom configuration file can be provided with a volume `--volume /path/to/squid.conf:/etc/squid3/squid.conf` 

```bash
docker run --name squid -d --restart=always \
  --publish 3128:3128 \
  --volume /path/to/squid.conf:/etc/squid3/squid.conf \
  --volume squid-cache:/var/spool/squid3 \
  roicostas/squid
```

To reload the Squid configuration on a running instance you can send the `HUP` signal to the container.

```bash
docker kill -s HUP squid
```

To add/edit/remove connections which skip the parent proxy edit `acl privnet` in the configuration file:

- Make connections to 10.0.0.0/8 network go directly without going through the parent proxy  => add `acl privnet dst 10.0.0.0/8` line

```bash
# Connections to local networks
acl privnet dst 172.16.0.0/12
acl privnet dst 192.168.0.0/16
acl privnet dst 10.0.0.0/8
```

## Usage

Configure environment variables and programs to connect to roicostas/squid proxy instead of the parent proxy

Example with roicostas/squid running on 192.168.10.10:3128 and a parent proxy on 10.10.10.10:3128

- Parent proxy on 10.10.10.10:3128
```bash
docker run --name squid -d --restart=always \
  --publish 3128:3128 \
  --volume squid-cache:/var/spool/squid3 \
  roicostas/squid
```

- Run squid with parent proxy 10.10.10.10:3128
```bash
docker run --name squid -d --restart=always \
  --publish 3128:3128 \
  -e http_proxy=http://10.10.10.10:3128 \
  -e https_proxy=https://10.10.10.10:3128 \
  --volume squid-cache:/var/spool/squid3 \
  roicostas/squid
```

- Configure terminal for using local proxy
```bash
export ftp_proxy=http://192.168.10.10:3128
export http_proxy=http://192.168.10.10:3128
export https_proxy=http://192.168.10.10:3128
```

## Logs

To access the Squid logs, located at `/var/log/squid3/`, you can use `docker exec`. For example, if you want to tail the access logs:

```bash
docker exec -it squid tail -f /var/log/squid3/access.log
```

## Authentication to parent proxy

Authentication parameters are taken from environment variables from docker run, e.g. `-e http_proxy="user:password@myproxy:port"`
