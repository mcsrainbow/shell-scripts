#!/bin/bash
# Copyright 2013 Percona LLC and/or its affiliates

USER=""
PASS=""

set -e
if [ -z "$3" ]; then
    echo "${0} <server> <database> <new_database>"
    exit 1
fi
db_exists=`mysql -u$USER -p$PASS -h $1 -e "show databases like '$3'" -sss`
if [ -n "$db_exists" ]; then
    echo "ERROR: New database already exists $3"
    exit 1
fi
TIMESTAMP=`date +%s`
character_set=`mysql -u$USER -p$PASS -h $1 -e "show create database $2\G" -sss | grep ^Create | awk -F'CHARACTER SET ' '{print $2}' | awk '{print $1}'`
TABLES=`mysql -u$USER -p$PASS -h $1 -e "select TABLE_NAME from information_schema.tables where table_schema='$2' and TABLE_TYPE='BASE TABLE'" -sss`
STATUS=$?
if [ "$STATUS" != 0 ] || [ -z "$TABLES" ]; then
    echo "Error retrieving tables from $2"
    exit 1
fi
echo "create database $3 DEFAULT CHARACTER SET $character_set"
mysql -u$USER -p$PASS -h $1 -e "create database $3 DEFAULT CHARACTER SET $character_set"
TRIGGERS=`mysql -u$USER -p$PASS -h $1 $2 -e "show triggers\G" | grep Trigger: | awk '{print $2}'`
VIEWS=`mysql -u$USER -p$PASS -h $1 -e "select TABLE_NAME from information_schema.tables where table_schema='$2' and TABLE_TYPE='VIEW'" -sss`
if [ -n "$VIEWS" ]; then
    mysqldump -u$USER -p$PASS -h $1 $2 $VIEWS > /tmp/${2}_views${TIMESTAMP}.dump
fi
mysqldump -u$USER -p$PASS -h $1 $2 -d -t -R -E > /tmp/${2}_triggers${TIMESTAMP}.dump
for TRIGGER in $TRIGGERS; do
    echo "drop trigger $TRIGGER"
    mysql -u$USER -p$PASS -h $1 $2 -e "drop trigger $TRIGGER"
done
for TABLE in $TABLES; do
    echo "rename table $2.$TABLE to $3.$TABLE"
    mysql -u$USER -p$PASS -h $1 $2 -e "SET FOREIGN_KEY_CHECKS=0; rename table $2.$TABLE to $3.$TABLE"
done
if [ -n "$VIEWS" ]; then
    echo "loading views"
    mysql -u$USER -p$PASS -h $1 $3 < /tmp/${2}_views${TIMESTAMP}.dump
fi
echo "loading triggers, routines and events"
mysql -u$USER -p$PASS -h $1 $3 < /tmp/${2}_triggers${TIMESTAMP}.dump
TABLES=`mysql -u$USER -p$PASS -h $1 -e "select TABLE_NAME from information_schema.tables where table_schema='$2' and TABLE_TYPE='BASE TABLE'" -sss`
if [ -z "$TABLES" ]; then
    echo "Dropping database $2"
    mysql -u$USER -p$PASS -h $1 $2 -e "drop database $2"
fi
if [ `mysql -u$USER -p$PASS -h $1 -e "select count(*) from mysql.columns_priv where db='$2'" -sss` -gt 0 ]; then
    COLUMNS_PRIV="    UPDATE mysql.columns_priv set db='$3' WHERE db='$2';"
fi
if [ `mysql -u$USER -p$PASS -h $1 -e "select count(*) from mysql.procs_priv where db='$2'" -sss` -gt 0 ]; then
    PROCS_PRIV="    UPDATE mysql.procs_priv set db='$3' WHERE db='$2';"
fi
if [ `mysql -u$USER -p$PASS -h $1 -e "select count(*) from mysql.tables_priv where db='$2'" -sss` -gt 0 ]; then
    TABLES_PRIV="    UPDATE mysql.tables_priv set db='$3' WHERE db='$2';"
fi
if [ `mysql -u$USER -p$PASS -h $1 -e "select count(*) from mysql.db where db='$2'" -sss` -gt 0 ]; then
    DB_PRIV="    UPDATE mysql.db set db='$3' WHERE db='$2';"
fi
if [ -n "$COLUMNS_PRIV" ] || [ -n "$PROCS_PRIV" ] || [ -n "$TABLES_PRIV" ] || [ -n "$DB_PRIV" ]; then
    echo "IF YOU WANT TO RENAME the GRANTS YOU NEED TO RUN ALL OUTPUT BELOW:"
    if [ -n "$COLUMNS_PRIV" ]; then echo "$COLUMNS_PRIV"; fi
    if [ -n "$PROCS_PRIV" ]; then echo "$PROCS_PRIV"; fi
    if [ -n "$TABLES_PRIV" ]; then echo "$TABLES_PRIV"; fi
    if [ -n "$DB_PRIV" ]; then echo "$DB_PRIV"; fi
    echo "    flush privileges;"
fi
