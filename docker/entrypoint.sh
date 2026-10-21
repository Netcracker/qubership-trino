#!/usr/bin/env bash

attempt_setup_fake_passwd_entry() {
  # Check whether there is a passwd entry for the container UID
  local myuid; myuid="$(id -u)"
  # If there is no passwd entry for the container UID, attempt to fake one.
  # It's to resolve the OpenShift random UID case. The approach is the same as in the Qubership Spark image.
  # The library is installed by the nss_wrapper-libs package at a fixed path, see the Dockerfile.
  # See also: https://github.com/docker-library/postgres/pull/448
  local wrapper="/usr/lib64/libnss_wrapper.so"
  if ! getent passwd "$myuid" &> /dev/null && [ -s "$wrapper" ]; then
      NSS_WRAPPER_PASSWD="$(mktemp)"
      NSS_WRAPPER_GROUP="$(mktemp)"
      export LD_PRELOAD="$wrapper" NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
      local mygid; mygid="$(id -g)"
      printf 'trino:x:%s:%s:%s:/home/trino:/bin/false\n' "$myuid" "$mygid" "anonymous uid" > "$NSS_WRAPPER_PASSWD"
      printf 'trino:x:%s:\n' "$mygid" > "$NSS_WRAPPER_GROUP"
  fi
}

attempt_setup_fake_passwd_entry

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

exec /usr/lib/trino/bin/launcher run --etc-dir /etc/trino