#!/bin/bash

create_log_dir() {
  mkdir -p ${SQUID_LOG_DIR}
  chmod -R 755 ${SQUID_LOG_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_LOG_DIR}
}

create_cache_dir() {
  mkdir -p ${SQUID_CACHE_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_CACHE_DIR}
}

configure_parent_proxy() {
    for var in $(env | grep -i http.*proxy); do
        # format: http_proxy=http://user:password@proxy:port

       params="no-query default"
       # Get user and password
        if [ "$(echo $var | grep "@")" ]; then
            # Parse user and password
            user_pass="login=$(echo $var | grep -oP "\w+:\w+" | head -n1)"
            params="$params $user_pass"
        fi

        # Get proxy name/IP and port
        proxy_port="$(echo $var | grep -oP "[\w\.]+[:]{0,1}\d*$")"
        proxy="$(echo $proxy_port | grep -oP "^[\w\.]+")"
        port="$(echo $proxy_port | grep -oP ":\d+$" | tr -d ':')"
        [ -z "$proxy" ] && continue
        [ -z "$port" ] && port=80

        parent_proxy="cache_peer $proxy parent $port 0 $params"
        if [ -z "$(cat /etc/squid3/squid.conf | grep "cache_peer $proxy")" ]; then
            echo "Adding $parent_proxy"
            echo $parent_proxy >> /etc/squid3/squid.conf
        fi
    done
}

create_log_dir
create_cache_dir
configure_parent_proxy

# allow arguments to be passed to squid3
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid3 || ${1} == $(which squid3) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    $(which squid3) -N -f /etc/squid3/squid.conf -z
  fi
  echo "Starting squid3..."
  exec $(which squid3) -f /etc/squid3/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi
