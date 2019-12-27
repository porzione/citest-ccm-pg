#!/bin/bash

cat /pg_hba.conf | envsubst > /etc/postgresql/$PG_VER/main/pg_hba.conf

echo "* Start PostgreSQL"
sudo -u postgres pg_ctlcluster $PG_VER main start
while ! sudo -u postgres pg_isready; do sleep 0.5; done
if [ "$PG_AUTH" != "trust" ] && [ -n "$PG_USER" ] && [ -n "$PG_PASS" ]; then
  echo "CREATE USER $PG_USER PASSWORD '$PG_PASS'" | sudo -u postgres psql
  echo "CREATE DATABASE $PG_DBNAME WITH OWNER=$PG_USER" | sudo -u postgres psql
fi

echo "* Start CCM"
ccm start --root

netstat -tpnl

if [ "$DAEMON" == "true" ]; then
  echo infinite sleep
  sleep infinity
fi