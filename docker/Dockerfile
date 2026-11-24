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

# Temurin JDK that replaces the one bundled in the Trino image, to fix CVE.
# Remove this stage on the next trino update.
FROM --platform=$BUILDPLATFORM alpine:latest AS jdk-download

ARG TARGETARCH
ARG TEMURIN_VERSION=25.0.5.1
ARG TEMURIN_BUILD=2
ARG TEMURIN_SHA256_AMD64=760f91b22c3efc9bd1b64ff950598231be82928cc807e30691a0e7a2995a62c0
ARG TEMURIN_SHA256_ARM64=c37879e0d08eeb1baa69fcbb7758cd455b7b1c0ceab1e2a136ccb1713c530984

RUN set -eu; \
    case "${TARGETARCH}" in \
        amd64) arch=x64; sha256="${TEMURIN_SHA256_AMD64}" ;; \
        arm64) arch=aarch64; sha256="${TEMURIN_SHA256_ARM64}" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    apk add --no-cache curl; \
    curl -fsSL --retry 8 -o /jdk.tar.gz \
        "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-${TEMURIN_VERSION}%2B${TEMURIN_BUILD}/OpenJDK25U-jdk_${arch}_linux_hotspot_${TEMURIN_VERSION}_${TEMURIN_BUILD}.tar.gz"; \
    echo "${sha256}  /jdk.tar.gz" | sha256sum -c -; \
    mkdir /jdk; \
    tar -xzf /jdk.tar.gz --strip-components=1 -C /jdk

FROM trinodb/trino:484

USER root

# Replace the bundled JDK in place, so JAVA_HOME and the launcher keep working unchanged.
# The directory name in JAVA_HOME still shows the old version; check `java -version` for the real one.
# Remove this stage on the next trino update.
RUN --mount=type=bind,from=jdk-download,source=/jdk,target=/mnt/jdk \
    rm -rf "${JAVA_HOME}" && \
    cp -a /mnt/jdk "${JAVA_HOME}" && \
    "${JAVA_HOME}/bin/java" -version

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