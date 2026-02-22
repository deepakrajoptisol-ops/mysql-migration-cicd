#!/bin/bash
# =============================================================================
# Rollback Script - Restore database from backup
# Usage: ./scripts/rollback.sh <backup_file>
# =============================================================================

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la backup_*.sql 2>/dev/null || echo "No backup files found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found"
    exit 1
fi

# Load environment
if [ -f "env.local" ]; then
    export $(cat env.local | grep -v '^#' | xargs)
fi

echo "=== ROLLBACK WARNING ==="
echo "This will REPLACE the entire database with: $BACKUP_FILE"
echo "Current database: $DB_NAME on $DB_HOST:$DB_PORT"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

echo "Rolling back database..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
    "$DB_NAME" < "$BACKUP_FILE"

echo "✅ Rollback complete!"
echo "Verify with: python -m src.migrate status"