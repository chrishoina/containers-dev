#!/bin/bash
set -eu

# Startup installation and database checks also call the ORDS CLI. Keep those clean;
# instrument only the server process that handles HTTP requests.
if [[ "${1:-}" == "serve" ]]; then
    set -- --java-options "-javaagent:/opt/oracle/ords/opentelemetry-javaagent.jar" "$@"
fi

exec /opt/oracle/ords/bin/ords-original "$@"
