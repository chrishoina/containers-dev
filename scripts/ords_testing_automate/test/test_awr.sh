#!/bin/bash

# --- 1. SETUP MOCKS ---
# Create a dummy sql executable in a temp directory
mkdir -p ./mock_bin
cat << 'EOF' > ./mock_bin/sql
#!/bin/bash
# Mocking SQLcl: return a dummy Snapshot ID or report path
if [[ "$*" == *"awr create snapshot"* ]]; then
  echo "Snapshot ID: 12345"
fi
if [[ "$*" == *"awr create html"* ]]; then
  echo "Report written to: /tmp/mock_report.html"
fi
if [[ "$*" == *"awr create text"* ]]; then
  echo "Report written to: /tmp/mock_report.txt"
fi
EOF
chmod +x ./mock_bin/sql

# --- 2. SETUP ENVIRONMENT ---
# Point the script to our mock instead of the real SQLCL_PATH
export PATH="$(pwd)/mock_bin:$PATH"
# Override the path variable inside the script by passing it as an env var or editing the script
# For testing, it's easier to temporarily modify the SQLCL_PATH in your main script to:
# SQLCL_PATH=${SQLCL_PATH:-"sql -s"}

# --- 3. TEST CASE: Python Script Detection ---
echo "TEST: Checking Python script execution..."
touch random_requests.py  # Create dummy file
# Run with short duration for testing (1s interval, 1 min duration)
bash awr_snapshots.sh 1 1 
rm random_requests.py

# --- 4. TEST CASE: Shell Script Detection ---
echo "TEST: Checking Shell script execution..."
touch random_requests.sh
bash awr_snapshots.sh 1 1
rm random_requests.sh