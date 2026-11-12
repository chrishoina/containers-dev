#!/usr/bin/env bash
set -euo pipefail

config_file="${ORDS_METRICS_CONFIG_FILE:-/etc/ords-metrics.conf}"
if [[ ! -r "$config_file" ]]; then
  printf 'Cannot read metrics configuration: %s\n' "$config_file" >&2
  exit 2
fi

logdir=/var/log/ords/access
namespace=dbtools_ords
resource=ords
compartment=
profile=
response_time=false
jmx=
pidfile=
host=

while IFS='=' read -r key value; do
  [[ "${key:-}" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${key:-}" ]] && continue
  key="$(printf '%s' "$key" | tr -d '[:space:]')"
  value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/\r$//')"
  case "$key" in
    logdir) logdir="$value" ;;
    namespace) namespace="$value" ;;
    resource) resource="$value" ;;
    compartment) compartment="$value" ;;
    profile) profile="$value" ;;
    time) response_time="$value" ;;
    jmx) jmx="$value" ;;
    pidfile) pidfile="$value" ;;
    host) host="$value" ;;
  esac
done < "$config_file"

if [[ -z "$compartment" ]]; then
  printf 'Set compartment in %s before enabling the oci-metrics Compose profile.\n' "$config_file" >&2
  exit 2
fi

metrics_bin="$(command -v ords-metrics || true)"
for root in /opt/oracle /opt/ords /usr/local; do
  [[ -n "$metrics_bin" ]] && break
  if [[ -d "$root" ]]; then
    candidate="$(find "$root" -name ords-metrics -type f -executable -print -quit 2>/dev/null || true)"
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      metrics_bin="$candidate"
      break
    fi
  fi
done
if [[ -z "$metrics_bin" || ! -x "$metrics_bin" ]]; then
  printf 'Could not find an executable ords-metrics utility in the ORDS image.\n' >&2
  exit 127
fi

args=(-d "$logdir" -n "$namespace" -r "$resource" -c "$compartment")
[[ -n "$profile" ]] && args+=(-p "$profile")
[[ "$response_time" == "true" ]] && args+=(-t)
[[ -n "$jmx" ]] && args+=(-m "$jmx")
[[ -n "$pidfile" ]] && args+=(-f "$pidfile")
[[ -n "$host" ]] && args+=(-H "$host")

exec "$metrics_bin" "${args[@]}"
