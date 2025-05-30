FROM trinodb/trino:475

USER root

ENV TRUST_CERTS_DIR=/home/trino/trustcerts

COPY docker/entrypoint.sh /opt/entrypoint.sh

RUN mkdir ${TRUST_CERTS_DIR} && \
    chmod 777 ${JAVA_HOME}/lib/security/cacerts && \
    chmod -R 777 /home/trino/trustcerts && \
    chmod 755 /opt/entrypoint.sh && \
    rm -rf /usr/lib/trino/plugin/pinot && \
    rm -rf /usr/lib/trino/plugin/ranger && \
    rm -rf /usr/lib/trino/plugin/iceberg && \
    rm -rf /usr/lib/trino/plugin/clickhouse
    

USER trino:trino

ENTRYPOINT ["/opt/entrypoint.sh"]
