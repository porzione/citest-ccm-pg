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
if [ -n "$CORES" ]; then
  ccm start --jvm_arg=-XX:ActiveProcessorCount=$CORES --root
else
  ccm start --root
fi

echo "* Start Redis"
redis-server /etc/redis/redis.conf

echo "* Start RabbitMQ"
if [ -n "$CORES" ]; then
  export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="+S $CORES:$CORES"
fi
/usr/sbin/rabbitmq-server -detached

netstat -tpnl

if [ "$INFINITE_SLEEP" == "true" ]; then
  echo infinite sleep
  sleep infinity
fi

echo "* Exiting"
