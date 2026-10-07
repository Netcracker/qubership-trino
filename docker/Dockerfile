ARG SEAWEEDFS_VERSION=4.38

FROM alpine:latest AS unpacker

ARG SEAWEEDFS_VERSION
ENV MAVEN_REPO=https://repo1.maven.org/maven2

RUN apk add --no-cache curl && \
    mkdir -p /opt/seaweedfs && \
    curl -k -L $MAVEN_REPO/com/seaweedfs/seaweedfs-hadoop3-client/$SEAWEEDFS_VERSION/seaweedfs-hadoop3-client-$SEAWEEDFS_VERSION.jar --output /opt/seaweedfs/seaweedfs-hadoop3-client-$SEAWEEDFS_VERSION.jar

FROM trinodb/trino:483

USER root

# The SeaweedFS jar is copied once into the hive plugin and symlinked from the other plugins to save image size.
ARG SEAWEEDFS_VERSION
COPY --from=unpacker --chmod=0644 /opt/seaweedfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar /usr/lib/trino/plugin/hive/hdfs/

RUN for plugin in iceberg delta-lake hudi lakehouse; do \
        ln -s /usr/lib/trino/plugin/hive/hdfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar \
              /usr/lib/trino/plugin/${plugin}/hdfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar && \
        test -f /usr/lib/trino/plugin/${plugin}/hdfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar \
        || exit 1; \
    done

ENV TRUST_CERTS_DIR=/home/trino/trustcerts
COPY docker/entrypoint.sh /opt/entrypoint.sh


RUN mkdir ${TRUST_CERTS_DIR} && \
    chmod 777 ${JAVA_HOME}/lib/security/cacerts && \
    chmod -R 777 /home/trino/trustcerts && \
    chmod 755 /opt/entrypoint.sh && \
    rm -rf /usr/lib/trino/plugin/pinot && \
    rm -rf /usr/lib/trino/plugin/ranger

USER trino:trino

ENTRYPOINT ["/opt/entrypoint.sh"]