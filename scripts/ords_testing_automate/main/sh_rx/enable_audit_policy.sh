#!/bin/bash

# Notes:
# File permissions: chmod +x enable_audit_policy.sh
# Usage: ./enable_audit_policy.sh [INTERVAL] [DURATION]

# --- 1. Path Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$SCRIPT_DIR/../sql_rx"
SQLCL_PATH="/opt/homebrew/Caskroom/sqlcl/25.3.2.317.1117/sqlcl/bin/sql -s"
DB_CONNECT_STRING="sys/Password12345@//localhost:1521/FREEPDB1 as sysdba"

# --- 2. Argument Handling (NO MORE PROMPTS HERE) ---
# This takes arguments from the Master Controller. 
# If run manually without args, it defaults to 60 and 5.
INTERVAL=${1:-60}
DURATION=${2:-5}

echo "Configured for: ${INTERVAL}s interval, ${DURATION}m duration."
echo "----------------------------------------------------------------"

# --- 3. Execute Audit Policy Enable ---
SQL_FILE="$SQL_DIR/enable_audit_policy.sql"
echo "Enabling Audit Policy..."
${SQLCL_PATH} "${DB_CONNECT_STRING}" <<EOF
@"$SQL_FILE"
EXIT;
EOF

echo ""
echo "================================================================"
echo "Unified Auditing enabled: ordstest_audit"
echo "================================================================"
