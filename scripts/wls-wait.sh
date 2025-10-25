#!/bin/bash

set -e

DB_HOST=${DB_HOST:-db23}
DB_PORT=${DB_PORT:-1521}

# Function to check Oracle DB port
wait_for_db() {
  echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."
  while ! curl -v telnet://"$DB_HOST":"$DB_PORT"; do
    echo "Database not available yet, sleeping 5 seconds..."
    sleep 5
  done
  echo "Database is up!"
}

wait_for_db

echo "All dependencies are up - starting WebLogic..."
exec "$@"