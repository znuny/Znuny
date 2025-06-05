FROM ubuntu:jammy
LABEL org.opencontainers.image.authors="Bohdan Klymonchuk" \
      org.opencontainers.image.title="znuny" \
      org.opencontainers.image.description="Based on https://doc.znuny.org/"

# Znuny version and environment
ARG ZNUNY_VERSION=7.1.7
ARG ZNUNY_USER=znuny
ENV ZNUNY_HOME=/opt/znuny-${ZNUNY_VERSION} \
    PATH=$PATH:/opt/znuny-${ZNUNY_VERSION}/bin

# Install all system packages and Perl modules, then clean caches
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      wget apache2 mariadb-client cpanminus cron vim \
      libdbd-odbc-perl libapache2-mod-perl2 \
      libdbd-mysql-perl libtimedate-perl libnet-dns-perl libnet-ldap-perl \
      libio-socket-ssl-perl libpdf-api2-perl libsoap-lite-perl \
      libtext-csv-xs-perl libjson-xs-perl libapache-dbi-perl \
      libxml-libxml-perl libxml-libxslt-perl libyaml-perl \
      libarchive-zip-perl libcrypt-eksblowfish-perl libencode-hanextra-perl \
      libmail-imapclient-perl libtemplate-perl libdatetime-perl libmoo-perl \
      bash-completion libyaml-libyaml-perl libjavascript-minifier-xs-perl \
      libcss-minifier-xs-perl libauthen-sasl-perl libauthen-ntlm-perl \
      libdbd-pg-perl libcrypt-jwt-perl libcrypt-openssl-x509-perl \
      libhash-merge-perl libical-parser-perl libspreadsheet-xlsx-perl \
      nullmailer uuid-dev build-essential && \
    echo "smtp.unibas.ch" > /etc/nullmailer/remotes && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest --force Jq Data::UUID && \
    apt-get purge -y uuid-dev build-essential && \
    apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR ${ZNUNY_HOME}
COPY . .

# Create ZNUNY user, configure and set permissions
RUN useradd -d ${ZNUNY_HOME} -c "Znuny user" \
      -g www-data -s /bin/bash -M -N ${ZNUNY_USER} && \
    cp Kernel/Config.pm.dist Kernel/Config.pm && \
    sed -i "s/\$Self->{DatabaseHost} = '127\.0\.0\.1';/\$Self->{DatabaseHost} = 'znuny_db';/" Kernel/Config.pm && \
    bin/znuny.SetPermissions.pl --znuny-user ${ZNUNY_USER}

# Rename default cron jobs
RUN su - znuny -c "cd ${ZNUNY_HOME}/var/cron && for f in *.dist; do cp \$f \$(basename \$f .dist); done "

# Configure Apache for Znuny
RUN a2dismod mpm_event && \
    a2enmod mpm_prefork perl headers deflate filter cgi rewrite && \
    ln -s ${ZNUNY_HOME}/scripts/apache2-httpd.include.conf /etc/apache2/conf-available/zzz_znuny.conf && \
    a2enconf zzz_znuny && \
    echo "RedirectMatch ^/$ /znuny/index.pl" >> /etc/apache2/apache2.conf

# Fix file permissions
RUN find ${ZNUNY_HOME}/var/httpd -type d -exec chmod 775 {} \; && \
    find ${ZNUNY_HOME}/var/httpd -type f -exec chmod 664 {} \; && \
    chown -R ${ZNUNY_USER}:www-data /tmp

RUN ln -s ${ZNUNY_HOME} /opt/znuny && \
    ln -s ${ZNUNY_HOME} /opt/otrs && \
    mv ${ZNUNY_HOME}/Kernel/System/Ticket/CustomExample.pm ${ZNUNY_HOME}/Kernel/System/Ticket/Custom.pm

EXPOSE 80

# Start services and launch Apache in foreground
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["service nullmailer start && service cron start && source /etc/apache2/envvars && apache2 -DFOREGROUND"]
