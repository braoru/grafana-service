FROM cloudtrust-baseimage:f27

ARG grafana_service_git_tag

WORKDIR /cloudtrust

# Add Grafana repository
RUN echo -e "[grafana]\nname=grafana\nbaseurl=https://packagecloud.io/grafana/stable/el/6/\$basearch\nrepo_gpgcheck=1\nenabled=1\ngpgcheck=1\ngpgkey=https://packagecloud.io/gpg.key https://grafanarel.s3.amazonaws.com/RPM-GPG-KEY-grafana\nsslverify=1\nsslcacert=/etc/pki/tls/certs/ca-bundle.crt" >> /etc/yum.repos.d/grafana.repo && \
# Install which, grafana, monit, haproxy
    dnf -y install which && \
    dnf -y install grafana monit nginx haproxy && \
    dnf clean all && \
    git clone git@github.com:cloudtrust/grafana-service.git && \
    cd grafana-service && \
    git checkout ${grafana_service_git_tag}

# Configure and install
RUN cd /cloudtrust/grafana-service && \
    chown grafana:grafana -R /var/log/grafana && \
    install -v -m0644 deploy/common/etc/security/limits.d/* /etc/security/limits.d/ && \
# Install monit
    install -v -m0644 deploy/common/etc/monit.d/* /etc/monit.d/ && \    
# nginx setup
    install -v -m0644 -D deploy/common/etc/nginx/conf.d/* /etc/nginx/conf.d/ && \
    install -v -m0644 deploy/common/etc/nginx/nginx.conf /etc/nginx/nginx.conf && \
    install -v -m0644 deploy/common/etc/nginx/mime.types /etc/nginx/mime.types && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/nginx.service.d && \
    install -v -o root -g root -m 644 deploy/common/etc/systemd/system/nginx.service.d/limit.conf /etc/systemd/system/nginx.service.d/limit.conf && \
# grafana setup
    install -v -m0755 -d /etc/grafana && \
    install -v -m0744 -d /run/grafana && \
#    install -v -m0755 deploy/common/etc/grafana/* /etc/grafana && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/grafana.service.d && \
    install -v -o root -g root -m 644 deploy/common/etc/systemd/system/grafana.service.d/limit.conf /etc/systemd/system/grafana.service.d/limit.conf && \
# haproxy setup
    install -v -m0755 -d /etc/haproxy && \
    install -v -m0744 -d /run/haproxy && \
    install -v -m0755 deploy/common/etc/haproxy/* /etc/haproxy && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/haproxy.service.d && \
    install -v -o root -g root -m 644 deploy/common/etc/systemd/system/haproxy.service.d/limit.conf /etc/systemd/system/haproxy.service.d/limit.conf && \
# enable services
    systemctl enable nginx.service && \
    systemctl enable grafana-server.service && \
    systemctl enable haproxy.service && \
    systemctl enable monit.service

EXPOSE 80
