# vi: ft=dockerfile
FROM porzione/citest

ARG DEBIAN_FRONTEND=noninteractive

### rabbitmq, erlang

RUN curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | apt-key add - \
    && echo "deb https://dl.bintray.com/rabbitmq-erlang/debian stretch erlang-23.x" | tee /etc/apt/sources.list.d/rabbitmq.list  \
    && echo "deb https://dl.bintray.com/rabbitmq/debian stretch main" | tee -a /etc/apt/sources.list.d/rabbitmq.list \
    && apt-get update -y \
    && apt-get install rabbitmq-server=3.8.14-1 -y --fix-missing

### java https://adoptopenjdk.net/installation.html#x64_linux-jdk

ARG JAVA_SUM=e6e6e0356649b9696fa5082cfcb0663d4bef159fc22d406e3a012e71fce83a5c
ARG JAVA_URL=https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u282-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u282b08.tar.gz
RUN curl -LfsSo /tmp/openjdk.tar.gz $JAVA_URL; \
    echo "$JAVA_SUM /tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

### CCM (Cassandra Cluster Manager)

ARG CASSANDRA_VER=3.11.10
RUN ccm create --version $CASSANDRA_VER --nodes 3 test

### PostgreSQL

ENV PG_VER=11
ENV PG_AUTH=trust
ARG PG_CONF=/etc/postgresql/$PG_VER/main/postgresql.conf
ARG PG_MAXCONN=500 
ARG PG_PORT=5432

RUN apt-get update && apt-get -y --no-install-recommends install postgresql-${PG_VER}
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
