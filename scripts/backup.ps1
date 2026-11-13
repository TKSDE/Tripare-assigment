$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

$backupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { Join-Path $rootDir "backups" }
$containerName = if ($env:DB_CONTAINER) { $env:DB_CONTAINER } else { "hotel_db" }
$dbName = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "hotel_booking_db" }
$dbUser = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "postgres" }
$dbPassword = if ($env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD } else { "postgrespassword" }

if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupDir "backup_$timestamp.sql"

Write-Host "=================================================="
Write-Host "Starting Database Backup (PowerShell)"
Write-Host "Database:  $dbName"
Write-Host "User:      $dbUser"
Write-Host "Timestamp: $timestamp"
Write-Host "Target:    $backupFile"
Write-Host "=================================================="

$runningContainers = docker ps --format '{{.Names}}'
if ($runningContainers -contains $containerName) {
    Write-Host "Executing pg_dump in Docker container '$containerName'..."
    docker exec -e PGPASSWORD=$dbPassword $containerName pg_dump -U $dbUser -d $dbName --clean --if-exists --no-owner --no-privileges | Out-File -FilePath $backupFile -Encoding utf8
} else {
    Write-Host "Executing local pg_dump against localhost:5432..."
    $env:PGPASSWORD = $dbPassword
    pg_dump -h localhost -p 5432 -U $dbUser -d $dbName --clean --if-exists --no-owner --no-privileges | Out-File -FilePath $backupFile -Encoding utf8
}

if ((Test-Path $backupFile) -and ((Get-Item $backupFile).Length -gt 0)) {
    $size = (Get-Item $backupFile).Length
    Write-Host "Backup completed successfully!"
    Write-Host "File: $backupFile"
    Write-Host "Size: $size bytes"
} else {
    Write-Error "Backup file was created but is empty or missing."
}
