FROM registry.access.redhat.com/ubi10/ubi-minimal:latest AS builder

RUN microdnf install -y curl && \
    microdnf update -y brotli && \
    curl -Lo /opensearch-common-2.19.4.jar https://repo1.maven.org/maven2/org/opensearch/opensearch-common/2.19.4/opensearch-common-2.19.4.jar

FROM trinodb/trino:479

USER root

COPY --from=builder /usr/lib64/libbrotlicommon.so.1* /usr/lib64/
COPY --from=builder /usr/lib64/libbrotlidec.so.1* /usr/lib64/
COPY --from=builder /usr/lib64/libbrotlienc.so.1* /usr/lib64/
COPY --from=builder /opensearch-common-2.19.4.jar /usr/lib/trino/plugin/opensearch/org.opensearch_opensearch-common-2.19.4.jar

RUN ldconfig

ENV TRUST_CERTS_DIR=/home/trino/trustcerts
COPY docker/entrypoint.sh /opt/entrypoint.sh

RUN mkdir -p ${TRUST_CERTS_DIR} && \
    chmod 777 ${JAVA_HOME}/lib/security/cacerts && \
    chmod -R 777 /home/trino/trustcerts && \
    chmod 755 /opt/entrypoint.sh && \
    rm -rf /usr/lib/trino/plugin/pinot && \
    rm -rf /usr/lib/trino/plugin/ranger && \
    rm -f /usr/lib/trino/plugin/opensearch/org.opensearch_opensearch-common-2.19.3.jar

USER trino:trino

ENTRYPOINT ["/opt/entrypoint.sh"]