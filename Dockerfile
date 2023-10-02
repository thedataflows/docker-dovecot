FROM debian:stable-20230919-slim

LABEL org.opencontainers.image.authors="cloud@thedataflows.com"

ENV container=docker \
    LC_ALL=C
ARG DEBIAN_FRONTEND=noninteractive \
    DOVECOT_RELEASE=2:2.3.21-1+debian11

RUN apt-get update && \
  apt-get -y install --no-install-recommends \
    curl gpg ca-certificates ssl-cert rsyslog tini && \
  curl https://repo.dovecot.org/DOVECOT-REPO-GPG | gpg --import || true && \
  gpg --export ED409DA1 > /etc/apt/trusted.gpg.d/dovecot.gpg && \
  echo "deb https://repo.dovecot.org/ce-2.3-latest/debian/bullseye bullseye main" > /etc/apt/sources.list.d/dovecot.list && \
  apt-get update && \
  apt-get -y install --no-install-recommends \
    dovecot-core=$DOVECOT_RELEASE \
    dovecot-gssapi=$DOVECOT_RELEASE \
    dovecot-imapd=$DOVECOT_RELEASE \
    dovecot-ldap=$DOVECOT_RELEASE \
    dovecot-lmtpd=$DOVECOT_RELEASE \
    dovecot-auth-lua=$DOVECOT_RELEASE \
    dovecot-managesieved=$DOVECOT_RELEASE \
    dovecot-mysql=$DOVECOT_RELEASE \
    dovecot-pgsql=$DOVECOT_RELEASE \
    dovecot-pop3d=$DOVECOT_RELEASE \
    dovecot-sieve=$DOVECOT_RELEASE \
    dovecot-solr=$DOVECOT_RELEASE \
    dovecot-sqlite=$DOVECOT_RELEASE \
    dovecot-submissiond=$DOVECOT_RELEASE && \
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
