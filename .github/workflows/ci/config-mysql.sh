#!/usr/bin/env bash

set -o errexit
set -o pipefail

echo "Change Config.pm"
sed -i 's/\(.*{DatabaseHost}.*\)127.0.0.1/\1'"mariadb"'/' /opt/otrs/Kernel/Config.pm
sed -i 's/\(.*{Database}.*\)otrs/\1'"${MYSQL_DATABASE}"'/' /opt/otrs/Kernel/Config.pm
sed -i 's/\(.*{DatabaseUser}.*\)otrs/\1'"${MYSQL_USER}"'/' /opt/otrs/Kernel/Config.pm
sed -i 's/\(.*{DatabasePw}.*\)some-pass/\1'"${MYSQL_PASSWORD}"'/' /opt/otrs/Kernel/Config.pm

SCHEMA_FILE=$(find /opt/otrs/scripts/database -type f -name '*schema.mysql.sql')
INITIAL_INSERT_FILE=$(find /opt/otrs/scripts/database -type f -name '*initial_insert.mysql.sql')
SCHEMA_POST_FILE=$(find /opt/otrs/scripts/database -type f -name '*schema-post.mysql.sql')

echo "Use SCHEMA_FILE: $SCHEMA_FILE"
echo "Use INITIAL_INSERT_FILE: $INITIAL_INSERT_FILE"
echo "Use SCHEMA_POST_FILE: $SCHEMA_POST_FILE"

echo "Change character set"
mysql -h mariadb -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" -e "ALTER DATABASE otrs DEFAULT CHARACTER SET utf8;ALTER DATABASE otrs DEFAULT COLLATE utf8_unicode_ci;" || exit 1

echo "Create schema"
mysql -h mariadb -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" otrs < "$SCHEMA_FILE" || exit 1

echo "Initial data"
mysql -h mariadb -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" otrs < "$INITIAL_INSERT_FILE" || exit 1

echo "Create post schema"
mysql -h mariadb -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" otrs < "$SCHEMA_POST_FILE" || exit 1

