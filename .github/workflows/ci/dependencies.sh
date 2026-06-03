#!/usr/bin/env bash

set -o errexit
set -o pipefail

apt-get update
apt-get upgrade -y
apt-get install -y libapache2-mod-perl2 \
  libtimedate-perl libnet-dns-perl libnet-ldap-perl \
  libio-socket-ssl-perl libpdf-api2-perl libdbi-perl libdbd-mysql-perl \
  libsoap-lite-perl libtext-csv-xs-perl libjson-xs-perl \
  libapache-dbi-perl libxml-libxml-perl libxml-libxslt-perl \
  libspreadsheet-xlsx-perl libyaml-perl libyaml-libyaml-perl libarchive-zip-perl \
  libcrypt-eksblowfish-perl libencode-hanextra-perl \
  libauthen-sasl-perl libdata-uuid-perl libdigest-sha-perl \
  libscalar-list-utils-perl libwww-perl libtime-piece-perl \
  libmail-imapclient-perl libtemplate-perl libdatetime-perl \
  libmoo-perl liblocale-po-perl libhash-merge-perl \
  libxml2-utils libical-parser-perl libexpat1-dev \
  libssl-dev libxml2-dev zlib1g-dev \
  apache2 gnupg2 mariadb-client cpanminus make gcc git npm gettext gnupg

# Net::SAML2 (no Debian/Ubuntu package, install via CPAN)
cpanm --notest Net::SAML2
