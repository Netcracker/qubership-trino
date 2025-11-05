FROM alpine:latest AS unpacker
ENV MAVEN_REPO=https://repo1.maven.org/maven2


RUN apk add --no-cache curl
RUN mkdir -p /patchedlibs

FROM trinodb/trino:478

USER root

ENV TRUST_CERTS_DIR=/home/trino/trustcerts

COPY docker/entrypoint.sh /opt/entrypoint.sh

RUN mkdir ${TRUST_CERTS_DIR} && \
    chmod 777 ${JAVA_HOME}/lib/security/cacerts && \
    chmod -R 777 /home/trino/trustcerts && \
    chmod 755 /opt/entrypoint.sh && \
    rm -rf /usr/lib/trino/plugin/pinot && \
    rm -rf /usr/lib/trino/plugin/ranger && \
    rm -rf /usr/lib/trino/plugin/clickhouse

USER trino:trino

ENTRYPOINT ["/opt/entrypoint.sh"]
