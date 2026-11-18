#!/bin/bash
set -eu

# For `ords serve`, add the Java agents before ORDS starts the server.
# Other CLI commands, such as installation and database checks, run without them.
if [[ "${1:-}" == "serve" ]]; then
    set -- --java-options "-javaagent:/opt/oracle/ords/opentelemetry-javaagent.jar -javaagent:/opt/oracle/ords/jmx_prometheus_javaagent.jar=/opt/oracle/ords/jmx-exporter.yaml" "$@"
fi

# Forward the arguments and replace the shell so ORDS receives signals directly.
exec /opt/oracle/ords/bin/ords-original "$@"
