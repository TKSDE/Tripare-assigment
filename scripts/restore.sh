#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups}"
CONTAINER_NAME="${DB_CONTAINER:-hotel_db}"
TARGET_DB="${2:-${RESTORE_DB:-hotel_booking_db_restored}}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgrespassword}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"

if [ "${1:-}" != "" ]; then
    BACKUP_FILE="$1"
else
    BACKUP_FILE="$(ls -t "${BACKUP_DIR}"/backup_*.sql 2>/dev/null | head -n 1 || true)"
fi

if [ -z "${BACKUP_FILE}" ] || [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: No valid backup file found to restore." >&2
    echo "Usage: $0 [path/to/backup.sql]" >&2
    exit 1
fi

echo "=================================================="
echo "Starting Database Restore"
echo "Source Dump:     ${BACKUP_FILE}"
echo "Target Database: ${TARGET_DB} (fresh)"
echo "User:            ${DB_USER}"
echo "=================================================="

EXEC_DOCKER=false
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    EXEC_DOCKER=true
fi

echo "Step 1: Preparing fresh target database '${TARGET_DB}'..."
if [ "${EXEC_DOCKER}" = true ]; then
    docker exec -e PGPASSWORD="${DB_PASSWORD}" "${CONTAINER_NAME}" \
        psql -U "${DB_USER}" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${TARGET_DB}' AND pid <> pg_backend_pid();" >/dev/null
    docker exec -e PGPASSWORD="${DB_PASSWORD}" "${CONTAINER_NAME}" \
        psql -U "${DB_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${TARGET_DB};" >/dev/null
    docker exec -e PGPASSWORD="${DB_PASSWORD}" "${CONTAINER_NAME}" \
        psql -U "${DB_USER}" -d postgres -c "CREATE DATABASE ${TARGET_DB};" >/dev/null
    
    echo "Step 2: Restoring data into '${TARGET_DB}'..."
    docker exec -i -e PGPASSWORD="${DB_PASSWORD}" "${CONTAINER_NAME}" \
        psql -U "${DB_USER}" -d "${TARGET_DB}" < "${BACKUP_FILE}" >/dev/null
    
    echo "Step 3: Verifying restored database..."
    echo "--- Table Counts in ${TARGET_DB} ---"
    docker exec -e PGPASSWORD="${DB_PASSWORD}" "${CONTAINER_NAME}" \
        psql -U "${DB_USER}" -d "${TARGET_DB}" -c "
            SELECT 
                (SELECT COUNT(*) FROM hotel_bookings) AS total_hotel_bookings,
                (SELECT COUNT(*) FROM booking_events) AS total_booking_events;
        "
    
    echo "--- Optimized Assessment Query Execution in ${TARGET_DB} ---"
    docker exec -e PGPASSWORD="${DB_PASSWORD}" "${CONTAINER_NAME}" \
        psql -U "${DB_USER}" -d "${TARGET_DB}" -c "
            SELECT org_id, status, COUNT(*), SUM(amount)
            FROM hotel_bookings
            WHERE city = 'delhi'
            AND created_at >= NOW() - INTERVAL '30 days'
            GROUP BY org_id, status;
        "
else
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${TARGET_DB}' AND pid <> pg_backend_pid();" >/dev/null
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${TARGET_DB};" >/dev/null
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "CREATE DATABASE ${TARGET_DB};" >/dev/null
    
    echo "Step 2: Restoring data into '${TARGET_DB}'..."
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" < "${BACKUP_FILE}" >/dev/null
    
    echo "Step 3: Verifying restored database..."
    echo "--- Table Counts in ${TARGET_DB} ---"
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" -c "
        SELECT 
            (SELECT COUNT(*) FROM hotel_bookings) AS total_hotel_bookings,
            (SELECT COUNT(*) FROM booking_events) AS total_booking_events;
    "
    
    echo "--- Optimized Assessment Query Execution in ${TARGET_DB} ---"
    PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" -c "
        SELECT org_id, status, COUNT(*), SUM(amount)
        FROM hotel_bookings
        WHERE city = 'delhi'
        AND created_at >= NOW() - INTERVAL '30 days'
        GROUP BY org_id, status;
    "
fi

echo "=================================================="
echo "Restore and verification finished successfully!"
echo "Target Database: ${TARGET_DB}"
echo "=================================================="
