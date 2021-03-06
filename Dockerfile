# vi: ft=dockerfile
FROM porzione/citest

ARG DEBIAN_FRONTEND=noninteractive

### rabbitmq, erlang https://rabbitmq.com/install-debian.html#supported-debian-distributions

RUN true \
    && curl -1sLf https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/gpg.E495BB49CC4BBE5B.key | apt-key add - \
    && curl -1sLf https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/gpg.9F4587F226208342.key | apt-key add - \
    && echo "deb https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/debian buster main" | tee /etc/apt/sources.list.d/erlang.list \
    && echo "deb https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/debian buster main" | tee /etc/apt/sources.list.d/rabbitmq.list \
    && apt-get update -y \
    && apt-get install rabbitmq-server=3.8.16-1 -y --fix-missing

### CCM (Cassandra Cluster Manager)

ARG CASSANDRA_VER=3.11.10
RUN ccm create --version $CASSANDRA_VER --nodes 3 test

### PostgreSQL https://wiki.postgresql.org/wiki/Apt

ENV PG_VER=12
ENV PG_AUTH=trust
ARG PG_CONF=/etc/postgresql/$PG_VER/main/postgresql.conf
ARG PG_MAXCONN=500 
ARG PG_PORT=5432

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list \
    && apt-get -y update \
    && apt-get -y install postgresql-${PG_VER}
RUN test -d $PG_TMP || sudo -u postgres mkdir -p $PG_TMP \
    && echo "max_connections = $PG_MAXCONN" >> $PG_CONF \
    && echo sed -i -E "s/#?port = [[:digit:]]+/port = $PG_PORT/" $PG_CONF
ADD pg_hba.conf /

### redis

RUN apt-get -y --no-install-recommends install redis-server

### daemon

ADD daemon.sh /
CMD /daemon.sh

### cleanup

RUN rm -rf /tmp/*.tar.gz /usr/share/man /var/lib/apt/lists \
    && apt-get clean

ARG SOURCE_BRANCH=""
ARG SOURCE_COMMIT=""
RUN echo $(date +'%y%m%d_%H%M%S_%Z') ${SOURCE_BRANCH} ${SOURCE_COMMIT} > /build.txt
SHELL ["/bin/bash", "-c"]
RUN echo "PATH=$PATH" > /etc/environment
