#!/usr/bin/env bash

if [[ "$(ls ${TRUST_CERTS_DIR})" ]]; then
    for filename in ${TRUST_CERTS_DIR}/*; do
        echo "Import $filename certificate to Java cacerts"
        ${JAVA_HOME}/bin/keytool -import -trustcacerts -keystore ${JAVA_HOME}/lib/security/cacerts -storepass changeit -noprompt -alias ${filename} -file ${filename}
    done;
fi

/usr/lib/trino/bin/run-trino