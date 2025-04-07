FROM trinodb/trino:474

USER root

ENV TRUST_CERTS_DIR=/home/trino/trustcerts

COPY docker/entrypoint.sh /opt/entrypoint.sh

RUN mkdir ${TRUST_CERTS_DIR} && \
    chmod 777 ${JAVA_HOME}/lib/security/cacerts && \
    chmod -R 777 /home/trino/trustcerts && \
    chmod 755 /opt/entrypoint.sh && \
    curl -k https://repo1.maven.org/maven2/org/freemarker/freemarker/2.3.34/freemarker-2.3.34.jar --output /usr/lib/trino/plugin/pinot/org.freemarker_freemarker-2.3.34.jar && \
    rm /usr/lib/trino/plugin/pinot/org.freemarker_freemarker-2.3.28.jar

USER trino:trino

ENTRYPOINT ["/opt/entrypoint.sh"]
