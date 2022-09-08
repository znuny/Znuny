#!/usr/bin/env bash

set -o errexit
set -o pipefail

if [ "$#" -eq "0" ]; then
    # wait for database initialization
    DBOK=1
    while [ "$DBOK" -eq 1 ]; do
        echo exit | sqlplus64 -L system/oracle@oracle:1521/xe
        DBOK=$?
        sleep 30
    done
    echo Create oracle database user
    sqlplus64 -S system/oracle@oracle:1521/xe > /dev/null << EOSQL
ALTER DATABASE datafile 1 AUTOEXTEND ON MAXSIZE 5G;
CREATE USER $ORACLE_USER IDENTIFIED by "$ORACLE_PASSWORD";
GRANT CONNECT TO $ORACLE_USER;
GRANT ALL PRIVILEGES TO $ORACLE_USER;
EXIT;
EOSQL


echo "Change Config.pm"
sed -i 's~DBDSN~DBI:Oracle://oracle:1521/XE~g' /opt/otrs/Kernel/Config.pm

SCHEMA_FILE=$(find /opt/otrs/scripts/database -type f -name '*schema.oracle.sql')
INITIAL_INSERT_FILE=$(find /opt/otrs/scripts/database -type f -name '*initial_insert.oracle.sql')
SCHEMA_POST_FILE=$(find /opt/otrs/scripts/database -type f -name '*schema-post.oracle.sql')

echo "Use SCHEMA_FILE: $SCHEMA_FILE"
echo "Use INITIAL_INSERT_FILE: $INITIAL_INSERT_FILE"
echo "Use SCHEMA_POST_FILE: $SCHEMA_POST_FILE"

echo "Create schema"
sqlplus64 -S $ORACLE_USER/"$ORACLE_PASSWORD"@oracle:1521/xe @"$SCHEMA_FILE" > /dev/null || exit 1

echo "Initial data"
sqlplus64 -S $ORACLE_USER/"$ORACLE_PASSWORD"@oracle:1521/xe @"$INITIAL_INSERT_FILE" > /dev/null || exit 1

echo "Create post schema"
sqlplus64 -S $ORACLE_USER/"$ORACLE_PASSWORD"@oracle:1521/xe @"$SCHEMA_POST_FILE" > /dev/null  || exit 1

