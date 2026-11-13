#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups}"
CONTAINER_NAME="${DB_CONTAINER:-hotel_db}"
DB_NAME="${POSTGRES_DB:-hotel_booking_db}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgrespassword}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"

mkdir -p "${BACKUP_DIR}"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

echo "=================================================="
echo "Starting Database Backup"
echo "Database:  ${DB_NAME}"
echo "User:      ${DB_USER}"
echo "Timestamp: ${TIMESTAMP}"
echo "Target:    ${BACKUP_FILE}"
echo "=================================================="

if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "Running pg_dump inside Docker container '${CONTAINER_NAME}'..."
    docker exec -e PGPASSWORD="${DB_PASSWORD}" "${CONTAINER_NAME}" \
        pg_dump -U "${DB_USER}" -d "${DB_NAME}" --clean --if-exists --no-owner --no-privileges > "${BACKUP_FILE}"
elif command -v pg_dump >/dev/null 2>&1; then
    echo "Running local pg_dump client against ${DB_HOST}:${DB_PORT}..."
    PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
        --clean --if-exists --no-owner --no-privileges > "${BACKUP_FILE}"
else
    echo "Error: Neither active Docker container '${CONTAINER_NAME}' nor local 'pg_dump' utility was found." >&2
    exit 1
fi

if [ -s "${BACKUP_FILE}" ]; then
    BACKUP_SIZE="$(wc -c < "${BACKUP_FILE}" | tr -d ' ')"
    echo "Backup completed successfully!"
    echo "File: ${BACKUP_FILE}"
    echo "Size: ${BACKUP_SIZE} bytes"
else
    echo "Error: Backup file was created but is empty." >&2
    rm -f "${BACKUP_FILE}"
    exit 1
fi
