FROM alpine:latest AS unpacker
ENV MAVEN_REPO=https://repo1.maven.org/maven2


RUN apk add --no-cache curl
RUN mkdir -p /patchedlibs && \
    curl -k -L ${MAVEN_REPO}/org/postgresql/postgresql/42.7.7/postgresql-42.7.7.jar --output  /patchedlibs/postgresql-42.7.7.jar && \
    curl -k -L ${MAVEN_REPO}/org/eclipse/jetty/http2/jetty-http2-common/12.0.25/jetty-http2-common-12.0.25.jar --output /patchedlibs/jetty-http2-common-12.0.25.jar && \
    curl -k -L ${MAVEN_REPO}/io/netty/netty-codec-http2/4.2.4.Final/netty-codec-http2-4.2.4.Final.jar --output /patchedlibs/netty-codec-http2-4.2.4.Final.jar 

FROM trinodb/trino:476

USER root

ENV TRUST_CERTS_DIR=/home/trino/trustcerts

COPY docker/entrypoint.sh /opt/entrypoint.sh

RUN mkdir ${TRUST_CERTS_DIR} && \
    chmod 777 ${JAVA_HOME}/lib/security/cacerts && \
    chmod -R 777 /home/trino/trustcerts && \
    chmod 755 /opt/entrypoint.sh && \
    rm -rf /usr/lib/trino/plugin/pinot && \
    rm -rf /usr/lib/trino/plugin/ranger && \
    rm -rf /usr/lib/trino/plugin/clickhouse && \
    rm /usr/lib/trino/plugin/iceberg/org.postgresql_postgresql-42.7.6.jar && \
    rm /usr/lib/trino/lib/org.eclipse.jetty.http2_jetty-http2-common-12.0.22.jar && \
    rm /usr/lib/trino/plugin/delta-lake/io.netty_netty-codec-http2-4.2.1.Final.jar


COPY --from=unpacker /patchedlibs/postgresql-42.7.7.jar /usr/lib/trino/plugin/iceberg/     
COPY --from=unpacker /patchedlibs/jetty-http2-common-12.0.25.jar /usr/lib/trino/lib/
COPY --from=unpacker /patchedlibs/netty-codec-http2-4.2.4.Final.jar /usr/lib/trino/plugin/delta-lake/

USER trino:trino

ENTRYPOINT ["/opt/entrypoint.sh"]
