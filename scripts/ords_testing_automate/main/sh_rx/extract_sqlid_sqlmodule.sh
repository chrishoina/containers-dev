#!/bin/bash

# Notes:
# File permissions: chmod +x extract_sqlid_sqlmodule.sh
# Usage: ./extract_sqlid_sqlmodule.sh ../files_output/awr_report_name.txt

set -euo pipefail

# --- 1. SETUP ENVIRONMENT ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$BASE_DIR/files_output"

# Standard connection info (keeping consistent with your other scripts)
SQLCL_PATH="/opt/homebrew/Caskroom/sqlcl/25.3.2.317.1117/sqlcl/bin/sql -s"
DB_CONNECT_STRING="sys/Password12345@//localhost:1521/FREEPDB1 as sysdba"

inputfile="$1"
outputfile="$OUTPUT_DIR/sql_modules.csv"

if [ ! -f "$inputfile" ]; then
    echo "ERROR: Input file $inputfile not found."
    exit 1
fi

# --- 2. PARSE AWR TEXT REPORT ---
echo "Parsing AWR report for Top SQL..."
awk -v output="$outputfile" '
BEGIN {
  in_section = 0
  print "sql_id,module" > output
}
{
  if ($0 ~ /^SQL ordered by Elapsed Time[ ]+DB\/Inst:/) { in_section = 1; next }
  if ($0 ~ /^SQL ordered by CPU Time[ ]+DB\/Inst:/) { in_section = 0; next }

  if (in_section) {
    if ($0 ~ /[a-z0-9]{13}$/) {
      sql_id = substr($0, length($0)-12, 13)
      module = ""
      getline nextline
      if (nextline ~ /^Module: /) {
        module = substr(nextline, index(nextline, ":")+2)
      }
      gsub(/"/, "\"\"", module)
      key = sql_id "|" module
      if (!seen[key]++) {
        printf "\"%s\",\"%s\"\n", sql_id, module >> output
      }
    }
  }
}
' "$inputfile"

echo "SQL IDs saved to $outputfile"

# --- 3. CROSS-REFERENCE AUDIT TRAIL ---
# Extract the unique SQL_IDs from the CSV (skipping header)
SQL_IDS=$(awk -F',' 'NR>1 {print $1}' "$outputfile" | tr -d '"' | paste -sd "," - | sed "s/,/','/g")

if [ -n "$SQL_IDS" ]; then
    echo "Cross-referencing Audit Trail for identified SQL_IDs..."
    
    # Run the Audit check and spool directly to the output folder
    $SQLCL_PATH "$DB_CONNECT_STRING" <<EOF
    SET FEEDBACK OFF
    SET MARKUP CSV ON
    SET TERMOUT OFF
    SPOOL "$OUTPUT_DIR/audit_culprits.csv"
    S-- Inside the EOF block of extract_sqlid_sqlmodule.sh
    SELECT event_timestamp, dbusername, action_name, SUBSTR(sql_text, 1, 60) as sql_short
    FROM unified_audit_trail 
    WHERE REGEXP_LIKE(sql_text, '$(echo $SQL_IDS | sed "s/','/|/g")')
    ORDER BY event_timestamp DESC;
    SPOOL OFF
    EXIT;
EOF
    echo "Audit investigation complete: $OUTPUT_DIR/audit_culprits.csv"
else
    echo "No SQL_IDs were extracted from the AWR report section."
fi