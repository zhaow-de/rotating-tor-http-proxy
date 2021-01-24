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
    mv /tor.cfg /etc/tor/torrc && \
    mv /privoxy.cfg /etc/privoxy/config.templ && \
    mv /haproxy.cfg /etc/haproxy/haproxy.cfg.default && \
    chmod +x /start.sh && \
    chmod +x /bom.sh && \
    mkdir -p /var/local/tor && \
    chown -R tor: /var/local/tor && \
    mkdir -p /var/local/privoxy && \
    chown -R privoxy: /var/local/privoxy && \
    #
    # cleanup
    #
    # tor
    rm -rf /etc/tor/torrc.sample && \
    # privoxy
    rm -rf /etc/privoxy/*.action /etc/privoxy/*.filter /etc/privoxy/trust /etc/logrotate.d/privoxy && \
    # files like /etc/shadow-, /etc/passwd-
    find / -xdev -type f -regex '.*-$' -exec rm -f {} + && \
    # suid files
    find / -xdev -type f -a -perm +4000 -delete && \
    # temp and cache
    rm -rf /var/cache/apk/* /usr/share/doc /usr/share/man/ /usr/share/info/* /var/cache/man/* /tmp/* /etc/fstab && \
    # init scripts
    rm -rf /etc/init.d /lib/rc /etc/conf.d /etc/inittab /etc/runlevels /etc/rc.conf && \
    # kernel tunables
    rm -rf /etc/sysctl* /etc/modprobe.d /etc/modules /etc/mdev.conf /etc/acpi

CMD /start.sh
