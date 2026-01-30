#!/bin/bash

#!/bin/bash

# Notes:
# File permissions: chmod +x awr_snapshots.sh
# Usage: ./awr_snapshots.sh INTERVAL_SECONDS DURATION_MINUTES (or run interactively)

set -euo pipefail

# --- PATH CONFIGURATION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
PY_DIR="$BASE_DIR/py_rx"
SH_DIR="$SCRIPT_DIR" 
# --------------------------

# --- ARGUMENT & PROMPT LOGIC ---
if [ "$#" -eq 2 ]; then
    # Use arguments if provided by the calling script (enable_audit_policy.sh)
    INTERVAL_SECONDS=$1
    DURATION_MINUTES=$2
else
    # Only ask if the Master Controller didn't provide them
    read -p "Enter interval..." INTERVAL_SECONDS
    read -p "Enter duration..." DURATION_MINUTES
fi

NUM_SNAPSHOTS=$(( DURATION_MINUTES * 60 / INTERVAL_SECONDS ))
echo "Executing: $NUM_SNAPSHOTS snapshots (${INTERVAL_SECONDS} intervals for ${DURATION_MINUTES} mins)"
# --------------------------------

SQLCL_PATH="/opt/homebrew/Caskroom/sqlcl/25.3.2.317.1117/sqlcl/bin/sql -s"
DB_CONNECT_STRING="sys/Password12345@//localhost:1521/FREEPDB1 as sysdba"

# 1. START Workload
WORKLOAD_PID=""
if [ -f "$PY_DIR/random_requests.py" ]; then
    echo "Starting Python workload..."
    python3 "$PY_DIR/random_requests.py" &
    WORKLOAD_PID=$!
elif [ -f "$SH_DIR/random_requests.sh" ]; then
    echo "Starting Shell workload..."
    bash "$SH_DIR/random_requests.sh" &
    WORKLOAD_PID=$!
fi

# 2. BEGIN Snapshots
echo "Taking initial snapshot..."
BEGIN_SNAP_ID=$($SQLCL_PATH "$DB_CONNECT_STRING" <<EOF | grep -oE '[0-9]+'
set feedback on
awr create snapshot
exit
EOF
)

for ((i=2; i<=NUM_SNAPSHOTS; i++)); do
  echo "Taking snapshot $i of $NUM_SNAPSHOTS..."
  $SQLCL_PATH "$DB_CONNECT_STRING" <<EOF > /dev/null
awr create snapshot
exit
EOF
  sleep "$INTERVAL_SECONDS"
done

# 3. TERMINATE Workload & FINAL Snapshot
echo "Stopping workload script (PID: $WORKLOAD_PID)..."
[ -n "$WORKLOAD_PID" ] && kill "$WORKLOAD_PID" || true

END_SNAP_ID=$($SQLCL_PATH "$DB_CONNECT_STRING" <<EOF | grep -oE '[0-9]+'
set feedback on
awr create snapshot
exit
EOF
)

# 4. REPORT Generation
echo "Waiting 10s for flush..."
sleep 10

# 4.1. Define the output directory
OUTPUT_DIR="$BASE_DIR/files_output"

# 4.2. Ensure the directory exists
mkdir -p "$OUTPUT_DIR"

echo "Generating AWR Reports into $OUTPUT_DIR..."

# 4.3. Generate the reports
# We move into the output directory FIRST so SQLcl writes files here naturally
cd "$OUTPUT_DIR"

$SQLCL_PATH "$DB_CONNECT_STRING" <<EOF
set feedback off
awr create html $BEGIN_SNAP_ID $END_SNAP_ID
awr create text $BEGIN_SNAP_ID $END_SNAP_ID
exit
EOF

# 5. List the files created
echo "--- Report Generation Complete ---"
ls -lh "$OUTPUT_DIR" | grep "awr_"
