# Start from the same pinned ORDS release used by the lab.
FROM container-registry.oracle.com/database/ords:26.3.0

# Pin and verify the Java agent during the image build so startup does not depend on a
# separate downloader container or a shared agent volume.
ARG OTEL_AGENT_VERSION=2.33.1
ARG OTEL_AGENT_SHA256=e43a270df53c6f423e0ab157be9c27ccc01d5dc3232e162fe54777573db2f149
ARG JMX_EXPORTER_VERSION=1.7.0
ARG JMX_EXPORTER_SHA256=0ad843261c567d1924a017d542e14c40f2afff523d940c25ee000742fde4b3a9
RUN curl -fsSL \
        "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar" \
        -o /opt/oracle/ords/opentelemetry-javaagent.jar \
    && echo "${OTEL_AGENT_SHA256}  /opt/oracle/ords/opentelemetry-javaagent.jar" | sha256sum -c -
RUN curl -fsSL \
        "https://github.com/prometheus/jmx_exporter/releases/download/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar" \
        -o /opt/oracle/ords/jmx_prometheus_javaagent.jar \
    && echo "${JMX_EXPORTER_SHA256}  /opt/oracle/ords/jmx_prometheus_javaagent.jar" | sha256sum -c -

# Keep the original CLI for install and other startup work. The replacement adds both
# agents only when the image asks ORDS to run its long-lived `serve` command.
RUN mv /opt/oracle/ords/bin/ords /opt/oracle/ords/bin/ords-original
COPY --chown=oracle:oinstall serve-with-agent.sh /opt/oracle/ords/bin/ords
RUN chmod 0755 /opt/oracle/ords/bin/ords
