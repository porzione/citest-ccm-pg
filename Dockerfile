# vi: ft=dockerfile
FROM porzione/citest

ARG DEBIAN_FRONTEND=noninteractive

### java https://adoptopenjdk.net/installation.html#x64_linux-jdk

ARG JAVA_TAR=OpenJDK8U-jdk_x64_linux_hotspot_8u292b10.tar.gz
ARG JAVA_SUM=${JAVA_TAR}.sha256.txt
ARG JAVA_BASE_URL=https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10
ARG JAVA_URL=${JAVA_BASE_URL}/${JAVA_TAR}
ARG JAVA_SUM_URL=${JAVA_BASE_URL}/${JAVA_SUM}
RUN cd /tmp ; \
    curl -LfsS $JAVA_SUM_URL -o $JAVA_SUM ; \
    curl -LfsS $JAVA_URL -o $JAVA_TAR ; \
    ls -l /tmp ; \  
    sha256sum -c $JAVA_SUM ; \
    mkdir -p /opt/java/openjdk ; \
    cd /opt/java/openjdk ; \
    tar -xf /tmp/$JAVA_TAR --strip-components=1
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

### rabbitmq, erlang https://rabbitmq.com/install-debian.html#supported-debian-distributions

RUN true \
    && curl -1sLf https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/gpg.E495BB49CC4BBE5B.key | sudo apt-key add - \
    && curl -1sLf https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/gpg.9F4587F226208342.key | sudo apt-key add - \
    && echo "deb https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/debian buster main" | tee /etc/apt/sources.list.d/erlang.list \
    && echo "deb https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/debian buster main" | tee /etc/apt/sources.list.d/rabbitmq.list \
    && apt-get update -y \
    && apt-get install rabbitmq-server=3.8.16-1 -y --fix-missing

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
