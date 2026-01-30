#!/bin/bash

# Master Controller Script with Archiving
# Files permission: chmod +x run_test_suite.sh
# Location: /ords_testing_automate/run_test_suite.sh

set -euo pipefail

# 1. SETUP PATHS
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SH_DIR="$ROOT_DIR/main/sh_rx"
OUTPUT_DIR="$ROOT_DIR/main/files_output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="test_run_$TIMESTAMP"

mkdir -p "$OUTPUT_DIR"

echo "================================================================"
echo "      ORDS PERFORMANCE & AUDIT AUTOMATION SUITE"
echo "================================================================"

# 2. GET USER INPUTS
read -p "Enter snapshot interval (seconds) [60]: " USER_INTERVAL
INTERVAL=${USER_INTERVAL:-60}

read -p "Enter total duration (minutes) [5]: " USER_DURATION
DURATION=${USER_DURATION:-5}

# [STEP 1/4]
echo "[STEP 1/4] Enabling Audit Policy..."
bash "$SH_DIR/enable_audit_policy.sh" "$INTERVAL" "$DURATION" || exit 1

# [STEP 2/4] - THE CRITICAL STEP
echo "[STEP 2/4] Running Workload & AWR Snapshots..."
# Ensure this path to awr_snapshots.sh is 100% correct
bash "$SH_DIR/awr_snapshots.sh" "$INTERVAL" "$DURATION" || exit 1

# [STEP 3/4]
echo "[STEP 3/4] Shutting down Audit Policy..."
bash "$SH_DIR/disable_audit_policy.sh" || exit 1

# [STEP 4/4]
echo "[STEP 4/4] Analyzing Top SQL and Audit Trail..."
# List files to debug if it fails
echo "Searching for AWR text files in: $OUTPUT_DIR"
LATEST_AWR_TXT=$(ls -t "$OUTPUT_DIR"/awr_*.txt 2>/dev/null | head -n 1)

if [ -n "$LATEST_AWR_TXT" ]; then
    echo "Found: $(basename "$LATEST_AWR_TXT")"
    bash "$SH_DIR/extract_sqlid_sqlmodule.sh" "$LATEST_AWR_TXT"
else
    echo "ERROR: Analysis skipped because no AWR text report was found in $OUTPUT_DIR"
fi

# --- FINAL STEP: ARCHIVING & CLEANUP ---
echo -e "\n[FINAL STEP] Archiving results..."

# Create a temporary folder for the current run's results
RUN_FOLDER="$OUTPUT_DIR/$ARCHIVE_NAME"
mkdir -p "$RUN_FOLDER"

# Move all results generated in this run into the specific run folder
# This includes AWR reports, the SQL modules CSV, and the Audit Culprits CSV
mv "$OUTPUT_DIR"/*.{html,txt,csv} "$RUN_FOLDER/" 2>/dev/null || true

# Zip the folder
cd "$OUTPUT_DIR"
zip -r "${ARCHIVE_NAME}.zip" "$ARCHIVE_NAME" > /dev/null

# Optional: Remove the unzipped folder to keep only the .zip
rm -rf "$ARCHIVE_NAME"

echo -e "\n================================================================"
echo "TEST SUITE COMPLETE"
echo "----------------------------------------------------------------"
echo "Archive Created: $OUTPUT_DIR/${ARCHIVE_NAME}.zip"
echo "Results inside:  AWR HTML/TXT, sql_modules.csv, audit_culprits.csv"
echo "================================================================"