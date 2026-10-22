ARG SEAWEEDFS_VERSION=4.38
ARG JACKSON_VERSION=2.22.4

FROM alpine:latest AS unpacker

ARG SEAWEEDFS_VERSION
ARG JACKSON_VERSION
ENV MAVEN_REPO=https://repo1.maven.org/maven2

RUN apk add --no-cache curl && \
    mkdir -p /opt/seaweedfs && \
    curl -k -L $MAVEN_REPO/com/seaweedfs/seaweedfs-hadoop3-client/$SEAWEEDFS_VERSION/seaweedfs-hadoop3-client-$SEAWEEDFS_VERSION.jar --output /opt/seaweedfs/seaweedfs-hadoop3-client-$SEAWEEDFS_VERSION.jar

RUN mkdir -p /opt/jackson && \
    for coords in \
        core:jackson-core \
        core:jackson-databind \
        dataformat:jackson-dataformat-smile \
        datatype:jackson-datatype-guava \
        datatype:jackson-datatype-jdk8 \
        datatype:jackson-datatype-joda \
        datatype:jackson-datatype-jsr310 \
        module:jackson-module-blackbird \
        module:jackson-module-parameter-names \
        jakarta.rs:jackson-jakarta-rs-base \
        jakarta.rs:jackson-jakarta-rs-json-provider; do \
        group=com.fasterxml.jackson.${coords%%:*}; \
        artifact=${coords#*:}; \
        curl -fsSL $MAVEN_REPO/$(echo $group | tr . /)/$artifact/$JACKSON_VERSION/$artifact-$JACKSON_VERSION.jar \
            --output /opt/jackson/${group}_$artifact-$JACKSON_VERSION.jar || exit 1; \
    done

# The Trino image has no package manager, so take just the files of the nss_wrapper-libs package
# from UBI, with the same paths. The entrypoint uses the library to fake a passwd entry when the
# container runs with an arbitrary UID (for example, in OpenShift). Hadoop fails to log in without
# a passwd entry for the UID. The library depends only on libc, which is already present in the Trino image.
FROM redhat/ubi10:latest AS nss-wrapper

# --no-recursion keeps tar from adding the whole content of directories shared with other packages.
RUN \
    set -xeuo pipefail && \
    dnf install --setopt install_weak_deps=false -y nss_wrapper-libs && \
    mkdir -p /rootfs && \
    rpm -ql nss_wrapper-libs | tar --no-recursion -cf - -T - | tar -xf - -C /rootfs

FROM trinodb/trino:484

USER root

COPY --from=nss-wrapper /rootfs/ /

# The SeaweedFS jar is copied once into the hive plugin and symlinked from the other plugins to save image size.
ARG SEAWEEDFS_VERSION
COPY --from=unpacker --chmod=0644 /opt/seaweedfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar /usr/lib/trino/plugin/hive/hdfs/

RUN for plugin in iceberg delta-lake hudi lakehouse; do \
        ln -s /usr/lib/trino/plugin/hive/hdfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar \
              /usr/lib/trino/plugin/${plugin}/hdfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar && \
        test -f /usr/lib/trino/plugin/${plugin}/hdfs/seaweedfs-hadoop3-client-${SEAWEEDFS_VERSION}.jar \
        || exit 1; \
    done

ARG JACKSON_VERSION
COPY --from=unpacker --chmod=0644 /opt/jackson/ /usr/lib/trino/lib/
RUN rm -f /usr/lib/trino/lib/*jackson*-2.22.3.jar

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