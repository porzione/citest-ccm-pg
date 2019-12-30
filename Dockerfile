# vi: ft=dockerfile
FROM porzione/citest

ARG DEBIAN_FRONTEND=noninteractive

### java https://adoptopenjdk.net/installation.html#x64_linux-jdk

ARG JAVA_SUM=7b7884f2eb2ba2d47f4c0bf3bb1a2a95b73a3a7734bd47ebf9798483a7bcc423
ARG JAVA_URL=https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u232-b09/OpenJDK8U-jdk_x64_linux_hotspot_8u232b09.tar.gz 
RUN curl -LfsSo /tmp/openjdk.tar.gz $JAVA_URL; \
    echo "$JAVA_SUM /tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

### CCM (Cassandra Cluster Manager)

ARG CASSANDRA_VER=3.11.5
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

### daemon

ADD daemon.sh /
CMD /daemon.sh

### cleanup

RUN rm /tmp/*.tar.gz \
    && rm -rf /usr/share/man \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/

ARG SOURCE_BRANCH=""
ARG SOURCE_COMMIT=""
RUN echo $(date +'%y%m%d_%H%M%S_%Z') ${SOURCE_BRANCH} ${SOURCE_COMMIT} > /build.txt
SHELL ["/bin/bash", "-c"]
RUN echo "PATH=$PATH" > /etc/environment
