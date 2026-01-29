FROM alpine:latest AS unpacker
ENV MAVEN_REPO=https://repo1.maven.org/maven2


RUN apk add --no-cache curl
RUN mkdir -p /patchedlibs && \
    curl -k -L ${MAVEN_REPO}/org/opensearch/opensearch-common/2.19.4/opensearch-common-2.19.4.jar --output  /patchedlibs/opensearch-common-2.19.4.jar
    
FROM trinodb/trino:479

USER root

ENV TRUST_CERTS_DIR=/home/trino/trustcerts
COPY docker/entrypoint.sh /opt/entrypoint.sh
COPY --from=unpacker /patchedlibs/opensearch-common-2.19.4.jar \
     /usr/lib/trino/plugin/opensearch/org.opensearch_opensearch-common-2.19.4.jar

RUN mkdir ${TRUST_CERTS_DIR} && \
    chmod 777 ${JAVA_HOME}/lib/security/cacerts && \
    chmod -R 777 /home/trino/trustcerts && \
    chmod 755 /opt/entrypoint.sh && \
    rm -rf /usr/lib/trino/plugin/pinot && \
    rm -rf /usr/lib/trino/plugin/ranger && \
    rm -f /usr/lib/trino/plugin/opensearch/org.opensearch_opensearch-common-2.19.3.jar

USER trino:trino

ENTRYPOINT ["/opt/entrypoint.sh"]