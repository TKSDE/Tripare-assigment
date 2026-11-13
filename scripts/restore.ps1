param (
    [string]$BackupFilePath,
    [string]$TargetDatabase
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

$backupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { Join-Path $rootDir "backups" }
$containerName = if ($env:DB_CONTAINER) { $env:DB_CONTAINER } else { "hotel_db" }
$targetDb = if ($TargetDatabase) { $TargetDatabase } elseif ($env:RESTORE_DB) { $env:RESTORE_DB } else { "hotel_booking_db_restored" }
$dbUser = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "postgres" }
$dbPassword = if ($env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD } else { "postgrespassword" }

if (-not $BackupFilePath) {
    $latest = Get-ChildItem -Path $backupDir -Filter "backup_*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $BackupFilePath = $latest.FullName
    } else {
        Write-Error "No backup file found in $backupDir to restore."
    }
}

if (-not (Test-Path $BackupFilePath)) {
    Write-Error "Backup file not found at: $BackupFilePath"
}

Write-Host "=================================================="
Write-Host "Starting Database Restore (PowerShell)"
Write-Host "Source Dump:     $BackupFilePath"
Write-Host "Target Database: $targetDb (fresh)"
Write-Host "User:            $dbUser"
Write-Host "=================================================="

$runningContainers = docker ps --format '{{.Names}}'
$isDocker = ($runningContainers -contains $containerName)

Write-Host "Step 1: Preparing fresh target database '$targetDb'..."

if ($isDocker) {
    docker exec -e PGPASSWORD=$dbPassword $containerName psql -U $dbUser -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$targetDb' AND pid <> pg_backend_pid();" | Out-Null
    docker exec -e PGPASSWORD=$dbPassword $containerName psql -U $dbUser -d postgres -c "DROP DATABASE IF EXISTS $targetDb;" | Out-Null
    docker exec -e PGPASSWORD=$dbPassword $containerName psql -U $dbUser -d postgres -c "CREATE DATABASE $targetDb;" | Out-Null

    Write-Host "Step 2: Restoring data into '$targetDb'..."
    Get-Content $BackupFilePath -Raw | docker exec -i -e PGPASSWORD=$dbPassword $containerName psql -U $dbUser -d $targetDb | Out-Null

    Write-Host "Step 3: Verifying restored database..."
    Write-Host "--- Table Counts in $targetDb ---"
    docker exec -e PGPASSWORD=$dbPassword $containerName psql -U $dbUser -d $targetDb -c @"
        SELECT 
            (SELECT COUNT(*) FROM hotel_bookings) AS total_hotel_bookings,
            (SELECT COUNT(*) FROM booking_events) AS total_booking_events;
"@

    Write-Host "--- Optimized Assessment Query Execution in $targetDb ---"
    docker exec -e PGPASSWORD=$dbPassword $containerName psql -U $dbUser -d $targetDb -c @"
        SELECT org_id, status, COUNT(*), SUM(amount)
        FROM hotel_bookings
        WHERE city = 'delhi'
        AND created_at >= NOW() - INTERVAL '30 days'
        GROUP BY org_id, status;
"@
} else {
    $env:PGPASSWORD = $dbPassword
    psql -h localhost -p 5432 -U $dbUser -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$targetDb' AND pid <> pg_backend_pid();" | Out-Null
    psql -h localhost -p 5432 -U $dbUser -d postgres -c "DROP DATABASE IF EXISTS $targetDb;" | Out-Null
    psql -h localhost -p 5432 -U $dbUser -d postgres -c "CREATE DATABASE $targetDb;" | Out-Null

    Write-Host "Step 2: Restoring data into '$targetDb'..."
    Get-Content $BackupFilePath -Raw | psql -h localhost -p 5432 -U $dbUser -d $targetDb | Out-Null

    Write-Host "Step 3: Verifying restored database..."
    Write-Host "--- Table Counts in $targetDb ---"
    psql -h localhost -p 5432 -U $dbUser -d $targetDb -c @"
        SELECT 
            (SELECT COUNT(*) FROM hotel_bookings) AS total_hotel_bookings,
            (SELECT COUNT(*) FROM booking_events) AS total_booking_events;
"@

    Write-Host "--- Optimized Assessment Query Execution in $targetDb ---"
    psql -h localhost -p 5432 -U $dbUser -d $targetDb -c @"
        SELECT org_id, status, COUNT(*), SUM(amount)
        FROM hotel_bookings
        WHERE city = 'delhi'
        AND created_at >= NOW() - INTERVAL '30 days'
        GROUP BY org_id, status;
"@
}

Write-Host "=================================================="
Write-Host "Restore and verification finished successfully!"
Write-Host "Target Database: $targetDb"
Write-Host "=================================================="
