#!/bin/sh
set -eu

# The Compose file supplies this password from .env. Fail early if it is missing
# so the Instance API user is never created with an unexpected credential.
: "${ORDS_INSTANCE_API_USER_PWD:?Set ORDS_INSTANCE_API_USER_PWD for the Instance API user}"

# ORDS keeps its standalone settings and file-based users in this mounted
# configuration directory, so these settings survive container recreation.
ORDS_CONFIG_DIR=/etc/ords/config

# Enable the Instance API globally for this ORDS configuration.
ords --config "$ORDS_CONFIG_DIR" config set --global instance.api.enabled true

# Create or update the local ORDS user and grant the role required by the
# Instance API. --password-stdin keeps the password out of the process args.
printf '%s\n' "$ORDS_INSTANCE_API_USER_PWD" |
  ords --config "$ORDS_CONFIG_DIR" config user add --password-stdin \
    instance_api_user "System Administrator"
