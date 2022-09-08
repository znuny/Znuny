#!/usr/bin/env bash

set -o errexit
set -o pipefail

echo "Change Config.pm"
sed -i "s~\$Self->{DatabaseHost}.*~\$Self->{DatabaseHost}  = \"postgresql\";~g" /opt/otrs/Kernel/Config.pm
sed -i "s~\$Self->{DatabaseUser}.*~\$Self->{DatabaseUser}  = \"otrs\";~g" /opt/otrs/Kernel/Config.pm
sed -i "s~DBDSN~DBI:Pg:database=\$Self->{Database};host=\$Self->{DatabaseHost}~g" /opt/otrs/Kernel/Config.pm


SCHEMA_FILE=$(find /opt/otrs/scripts/database -type f -name '*schema.postgresql.sql')
INITIAL_INSERT_FILE=$(find /opt/otrs/scripts/database -type f -name '*initial_insert.postgresql.sql')
SCHEMA_POST_FILE=$(find /opt/otrs/scripts/database -type f -name '*schema-post.postgresql.sql')

echo "Use SCHEMA_FILE: $SCHEMA_FILE"
echo "Use INITIAL_INSERT_FILE: $INITIAL_INSERT_FILE"
echo "Use SCHEMA_POST_FILE: $SCHEMA_POST_FILE"

echo "Create schema"
    PGPASSWORD=$POSTGRESQL_PASSWORD psql -q -h postgresql -U $POSTGRESQL_USER $POSTGRESQL_DATABASE < "$SCHEMA_FILE" || exit 1

echo "Initial data"
PGPASSWORD=$POSTGRESQL_PASSWORD psql -q -h postgresql -U $POSTGRESQL_USER $POSTGRESQL_DATABASE < "$INITIAL_INSERT_FILE" || exit 1

echo "Create post schema"
PGPASSWORD=$POSTGRESQL_PASSWORD psql -q -h postgresql -U $POSTGRESQL_USER $POSTGRESQL_DATABASE < "$SCHEMA_POST_FILE" || exit 1

