#!/bin/bash

function log() {
    if [[ $# == 1 ]]; then
        level="info"
        msg=$1
    elif [[ $# == 2 ]]; then
        level=$1
        msg=$2
    fi
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [controller] [${level}] ${msg}"
}

if ((TOR_INSTANCES < 1 || TOR_INSTANCES > 40)); then
    log "fatal" "Environment variable TOR_INSTANCES has to be within the range of 1...40"
    exit 1
fi

if ((TOR_REBUILD_INTERVAL < 600)); then
    log "fatal" "Environment variable TOR_REBUILD_INTERVAL has to be bigger than 600 seconds"
    # otherwise AWS may complain about it, because http://checkip.amazonaws.com is asked too often
    exit 2
fi

base_tor_socks_port=10000
base_tor_ctrl_port=20000
base_http_port=30000

log "Start creating a pool of ${TOR_INSTANCES} tor instances..."

# "reset" the HAProxy config file because it may contain the previous Privoxy instances information from the previous docker run
cp /etc/haproxy/haproxy.cfg.default /etc/haproxy/haproxy.cfg
# same "reset" logic as above
cp /etc/tor/torrc.default /etc/tor/torrc

if [[ -n $TOR_EXIT_COUNTRY ]]; then
    IFS=', ' read -r -a countries <<< "$TOR_EXIT_COUNTRY"
    value=""
    is_first=1
    for country in "${countries[@]}"
    do
        country=$(xargs <<< "$country")
        length=${#country}
        if [[ $length -ne 2 ]]; then
            continue
        fi
        if [[ $is_first -ne 1 ]]; then
            value="$value,"
        else
            is_first=0
        fi
        value="$value{$country}"
    done
    country_str=$(tr '[:upper:]' '[:lower:]' <<< "$value")
    if [[ -n $country_str ]]; then
        echo ExitNodes "$country_str" StrictNodes 1 >> /etc/tor/torrc
        log "Limited the exit nodes to countries: \"${TOR_EXIT_COUNTRY}\""
    fi
fi

for ((i = 0; i < TOR_INSTANCES; i++)); do
    #
    # start one tor instance
    #
    socks_port=$((base_tor_socks_port + i))
    ctrl_port=$((base_tor_ctrl_port + i))
    tor_data_dir="/var/local/tor/${i}"
    mkdir -p "${tor_data_dir}" && chmod -R 700 "${tor_data_dir}" && chown -R proxy: "${tor_data_dir}"
    # spawn a child process to run the tor server at foreground so that logging to stdout is possible
    (tor --PidFile "${tor_data_dir}/tor.pid" \
      --SocksPort 127.0.0.1:"${socks_port}" \
      --ControlPort 127.0.0.1:"${ctrl_port}" \
      --dataDirectory "${tor_data_dir}" 2>&1 |
      sed -r "s/^(\w+\ [0-9 :\.]+)(\[.*)[\r\n]?$/$(date -u +"%Y-%m-%dT%H:%M:%SZ") [tor#${i}] \2/") &
    #
    # start one privoxy instance connecting to the tor socks
    #
    http_port=$((base_http_port + i))
    privoxy_data_dir="/var/local/privoxy/${i}"
    mkdir -p "${privoxy_data_dir}" && chown -R proxy: "${privoxy_data_dir}"
    cp /etc/privoxy/config.templ "${privoxy_data_dir}/config"
    sed -i \
      -e 's@PLACEHOLDER_CONFDIR@'"${privoxy_data_dir}"'@g' \
      -e 's@PLACEHOLDER_HTTP_PORT@'"${http_port}"'@g' \
      -e 's@PLACEHOLDER_SOCKS_PORT@'"${socks_port}"'@g' \
      "${privoxy_data_dir}/config"
    # spawn a child process
    (privoxy \
      --no-daemon \
      --pidfile "${privoxy_data_dir}/privoxy.pid" \
      "${privoxy_data_dir}/config" 2>&1 |
      sed -r "s/^([0-9\-]+\ [0-9:\.]+\ [0-9a-f]+\ )([^:]+):\ (.*)[\r\n]?$/$(date -u +"%Y-%m-%dT%H:%M:%SZ") [privoxy#${i}] [\L\2] \E\3/") &
    #
    # "register" the privoxy instance to haproxy
    #
    echo "  server privoxy${i} 127.0.0.1:${http_port} check" >>/etc/haproxy/haproxy.cfg
done
#
# start an HAProxy instance
#
(haproxy -db -- /etc/haproxy/haproxy.cfg 2>&1 |
  sed -r "s/^(\[[^]]+]\ )?([\ 0-9\/\():]+)?(.*)[\r\n]?$/$(date -u +"%Y-%m-%dT%H:%M:%SZ") [haproxy] \L\1\E\3/") &
# seems like haproxy starts logging only when the first request processed. We wait 15 seconds to build the first circuit then issue a
# request to "activate" the HAProxy
log "Wait 15 seconds to build the first Tor circuit"
sleep 15
curl -sx "http://127.0.0.1:3128" https://www.apple.com >/dev/null
#
# endless loop to reset circuits
#
while :; do
    log "Wait ${TOR_REBUILD_INTERVAL} seconds to rebuild all the tor circuits"
    sleep "$((TOR_REBUILD_INTERVAL))"
    log "Rebuilding all the tor circuits..."
    for ((i = 0; i < TOR_INSTANCES; i++)); do
        http_port=$((base_http_port + i))
        IP=$(curl -sx "http://127.0.0.1:${http_port}" http://checkip.amazonaws.com)
        log "Current external IP address of proxy #${i}/${TOR_INSTANCES}: ${IP}"
    done
done
