FROM alpine:latest

ENV \
    # sets the number of tor instances
    TOR_INSTANCES=10 \
    # sets the interval (in seconds) to rebuild tor circuits
    TOR_REBUILD_INTERVAL=1800

EXPOSE 3128/tcp 4444/tcp

COPY tor.cfg privoxy.cfg haproxy.cfg start.sh bom.sh /

RUN apk --no-cache --no-progress --quiet upgrade && \
    # alpine has a POSIX sed from busybox, for the log re-formatting, GNU sed is required to converting a capture group to lowercase
    apk --no-cache --no-progress --quiet add tor bash privoxy haproxy curl sed && \
    #
    # directories and files
    mv /tor.cfg /etc/tor/torrc.default && \
    mv /privoxy.cfg /etc/privoxy/config.templ && \
    mv /haproxy.cfg /etc/haproxy/haproxy.cfg.default && \
    chmod +x /start.sh && \
    chmod +x /bom.sh && \
    #
    # prepare for low-privilege execution \
    addgroup proxy && \
    adduser -S -D -u 1000 -G proxy proxy && \
    touch /etc/haproxy/haproxy.cfg && \
    chown -R proxy: /etc/haproxy/ && \
    mkdir -p /var/lib/haproxy && \
    chown -R proxy: /var/lib/haproxy && \
    mkdir -p /var/local/haproxy && \
    chown -R proxy: /var/local/haproxy && \
    touch /etc/tor/torrc && \
    chown -R proxy: /etc/tor/ && \
    chown -R proxy: /etc/privoxy/ && \
    mkdir -p /var/local/tor && \
    chown -R proxy: /var/local/tor && \
    mkdir -p /var/local/privoxy && \
    chown -R proxy: /var/local/privoxy && \
    chown -R proxy: /var/log/privoxy && \
    #
    # cleanup
    #
    # tor
    rm -rf /etc/tor/torrc.sample && \
    # privoxy
    rm -rf /etc/privoxy/*.new /etc/logrotate.d/privoxy && \
    # files like /etc/shadow-, /etc/passwd-
    find / -xdev -type f -regex '.*-$' -exec rm -f {} \; && \
    # temp and cache
    rm -rf /var/cache/apk/* /usr/share/doc /usr/share/man/ /usr/share/info/* /var/cache/man/* /tmp/* /etc/fstab && \
    # init scripts
    rm -rf /etc/init.d /lib/rc /etc/conf.d /etc/inittab /etc/runlevels /etc/rc.conf && \
    # kernel tunables
    rm -rf /etc/sysctl* /etc/modprobe.d /etc/modules /etc/mdev.conf /etc/acpi

STOPSIGNAL SIGINT

USER proxy

CMD ["/start.sh"]
