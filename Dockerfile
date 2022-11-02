FROM debian:stable-20221024-slim

LABEL org.opencontainers.image.authors="cloud@thedataflows.com"

ENV container=docker \
    LC_ALL=C
ARG DEBIAN_FRONTEND=noninteractive

ADD dovecot.gpg /etc/apt/trusted.gpg.d
ADD dovecot.list /etc/apt/sources.list.d

RUN apt-get -y update && apt-get -y install --no-install-recommends \
  tini \
  dovecot-core \
  dovecot-gssapi \
  dovecot-imapd \
  dovecot-ldap \
  dovecot-lmtpd \
  dovecot-auth-lua \
  dovecot-managesieved \
  dovecot-mysql \
  dovecot-pgsql \
  dovecot-pop3d \
  dovecot-sieve \
  dovecot-solr \
  dovecot-sqlite \
  dovecot-submissiond \
  ca-certificates \
  ssl-cert \
  rsyslog && \
  rm -rf /var/lib/apt/lists && \
  groupadd -g 1000 vmail && \
  useradd -u 1000 -g 1000 vmail -d /srv/vmail && \
  passwd -l vmail && \
  rm -rf /etc/dovecot && \
  mkdir /srv/mail && \
  chown vmail:vmail /srv/mail && \
  make-ssl-cert generate-default-snakeoil && \
  mkdir /etc/dovecot && \
  ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/dovecot/cert.pem && \
  ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/dovecot/key.pem && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ADD dovecot.conf /etc/dovecot/dovecot.conf
ADD rsyslog.conf /etc/rsyslog.conf

VOLUME ["/etc/dovecot", "/srv/mail"]
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/bash", "-c", "(sleep 3 && dovecot >/dev/null) & rsyslogd -n && wait"]
