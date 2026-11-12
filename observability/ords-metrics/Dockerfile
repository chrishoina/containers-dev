FROM container-registry.oracle.com/database/ords:latest

USER root

ARG OCI_CLI_VERSION=3.68.1
RUN dnf install -y curl \
    && curl -fsSL "https://raw.githubusercontent.com/oracle/oci-cli/v${OCI_CLI_VERSION}/scripts/install/install.sh" \
       -o /tmp/oci-cli-install.sh \
    && bash /tmp/oci-cli-install.sh \
       --accept-all-defaults \
       --no-tty \
       --oci-cli-version "${OCI_CLI_VERSION}" \
       --install-dir /opt/oci-cli \
       --exec-dir /usr/local/bin \
       --script-dir /usr/local/lib/oci-cli \
    && rm -f /tmp/oci-cli-install.sh \
    && dnf clean all

COPY --chown=oracle:oinstall ords-entrypoint.d/10-configure-access-logs.sh /ords-entrypoint.d/10-configure-access-logs.sh
COPY --chown=oracle:oinstall run-ords-metrics.sh /usr/local/bin/run-ords-metrics

USER oracle
