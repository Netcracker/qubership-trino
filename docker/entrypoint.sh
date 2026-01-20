#!/usr/bin/env bash

WRITABLE_CACERTS="/java-security/cacerts"
ORIGINAL_CACERTS="${JAVA_HOME}/lib/security/cacerts"
mkdir -p /java-security
cp "${ORIGINAL_CACERTS}" "${WRITABLE_CACERTS}"
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS} -Djavax.net.ssl.trustStore=${WRITABLE_CACERTS} -Djavax.net.ssl.trustStorePassword=changeit"

if [[ "$(ls ${TRUST_CERTS_DIR})" ]]; then
    for filename in ${TRUST_CERTS_DIR}/*; do
        echo "Import $filename certificate to Java cacerts"
        ${JAVA_HOME}/bin/keytool -import -trustcacerts -keystore "${WRITABLE_CACERTS}" -storepass changeit -noprompt -alias "$(basename ${filename})" -file "${filename}"
    done;
fi

/usr/lib/trino/bin/run-trino