#!/bin/bash

# Notes:
# File permissions: chmod +x disable_audit_policy.sh
# Usage: ./disable_audit_policy.sh

# --- 1. Path Setup ---
# This line finds exactly where THIS script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This points to the sql_rx folder relative to the script location
SQL_DIR="$SCRIPT_DIR/../sql_rx"

SQLCL_PATH="/opt/homebrew/Caskroom/sqlcl/25.3.2.317.1117/sqlcl/bin/sql -s"
DB_CONNECT_STRING="sys/Password12345@//localhost:1521/FREEPDB1 as sysdba"

# --- 2. Define Absolute Path to SQL file ---
SQL_FILE="$SQL_DIR/disable_audit_policy.sql"

echo "Disabling audit policy using: $SQL_FILE"

# --- 3. Execute ---
${SQLCL_PATH} "${DB_CONNECT_STRING}" <<EOF
@"$SQL_FILE"
EXIT;
EOF

echo "Audit policy disabled successfully."