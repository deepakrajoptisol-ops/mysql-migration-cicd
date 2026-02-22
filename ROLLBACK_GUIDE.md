# 🔄 Complete Rollback Guide

## Overview
This system provides multiple rollback methods to restore your database to a previous version. All methods use **backup restoration** since we use UP-only migrations.

---

## Method 1: CLI Rollback Command ⭐ (Recommended)

### Usage
```bash
# Check current state
python -m src.migrate status

# List available backups
ls -la backup_*.sql

# Rollback to specific migration version
python -m src.migrate rollback <target_version> --backup-file <backup_file>
```

### Example
```bash
# Rollback to migration 003
python -m src.migrate rollback 003 --backup-file backup_20260222_120000.sql

# Verify rollback
python -m src.migrate status
```

### What It Does
- ✅ Restores database from backup
- ✅ Removes migration records newer than target version
- ✅ Updates audit trail
- ✅ Provides structured logging

---

## Method 2: Rollback Script 🛠️

### Usage
```bash
# Interactive rollback with confirmation
./scripts/rollback.sh <backup_file>

# List available backups first
ls -la backup_*.sql
```

### Example
```bash
# Interactive rollback
./scripts/rollback.sh backup_prod_20260222T120000Z.sql

# The script will:
# 1. Show backup file details
# 2. Ask for confirmation
# 3. Restore database
# 4. Provide verification steps
```

### Features
- ✅ Safety confirmation prompt
- ✅ Environment variable loading
- ✅ Clear instructions
- ✅ Verification guidance

---

## Method 3: GitHub Actions Rollback 🚀

### For Dev Environment
```bash
# 1. Create rollback branch
git checkout -b rollback-to-v003

# 2. Remove newer migration files
rm migrations/004_*.sql migrations/005_*.sql migrations/008_*.sql

# 3. Commit and push
git add . && git commit -m "Rollback to migration 003"
git push origin rollback-to-v003

# 4. Create PR → triggers CI with rollback
```

### For Prod Environment
1. **Go to GitHub Actions**
2. **Select "Deploy Prod"**
3. **Click "Run workflow"**
4. **Inputs**:
   - `allow_destructive`: true (if needed)
   - `change_ticket_id`: ROLLBACK-001
5. **Approval required** (prod environment protection)
6. **Auto-rollback** if deployment fails

---

## Method 4: Manual Database Restore 💾

### Direct MySQL Restore
```bash
# 1. Stop application (prevent new writes)
# 2. Create current backup (safety)
mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD \
  --routines --triggers --events --single-transaction \
  $DB_NAME > current_backup.sql

# 3. Restore from target backup
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD \
  $DB_NAME < backup_target_version.sql

# 4. Verify restoration
python -m src.migrate status
```

---

## Backup Strategy 📦

### Automatic Backups
| Environment | When | Retention | Location |
|-------------|------|-----------|----------|
| **CI** | Before each test | 7 days | GitHub Artifacts |
| **Dev** | Before each deploy | 30 days | GitHub Artifacts |
| **Prod** | Before each deploy | 90 days | GitHub Artifacts + S3 |

### Manual Backups
```bash
# Create timestamped backup
ts=$(date -u +%Y%m%dT%H%M%SZ)
mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD \
  --routines --triggers --events --single-transaction \
  $DB_NAME > "backup_manual_${ts}.sql"
```

---

## Rollback Scenarios 📋

### Scenario 1: "Undo Last Migration"
```bash
# Find the previous version
python -m src.migrate status
docker exec mysql-test mysql -u root -ptestpw migration_db -e \
  "SELECT ID FROM DATABASECHANGELOG ORDER BY ORDEREXECUTED DESC LIMIT 2;"

# Rollback to previous version
python -m src.migrate rollback <previous_id> --backup-file <latest_backup>
```

### Scenario 2: "Go Back 3 Versions"
```bash
# Check migration history
docker exec mysql-test mysql -u root -ptestpw migration_db -e \
  "SELECT ID, AUTHOR, DATEEXECUTED FROM DATABASECHANGELOG ORDER BY ORDEREXECUTED;"

# Rollback to target version
python -m src.migrate rollback <target_id> --backup-file <appropriate_backup>
```

### Scenario 3: "Emergency Production Rollback"
1. **Immediate**: Use GitHub Actions "Deploy Prod" with rollback backup
2. **Manual**: SSH to prod server, use rollback script
3. **Incident**: Follow runbook in workflow logs

---

## Safety Considerations ⚠️

### Data Loss Risks
- **Backup-based rollback is destructive**
- **Loses data written after backup timestamp**
- **Requires maintenance window in production**

### Mitigations
- ✅ **Immediate pre-migration backups**
- ✅ **Read-only mode during deployments**
- ✅ **Test rollbacks in staging first**
- ✅ **Point-in-time recovery for precision**

### Best Practices
1. **Always backup before rollback**
2. **Verify backup integrity first**
3. **Coordinate with application teams**
4. **Test in non-prod environment**
5. **Document rollback reasons**

---

## Verification Steps ✅

After any rollback:

```bash
# 1. Check migration state
python -m src.migrate status

# 2. Verify database schema
python -m src.migrate verify

# 3. Test application functionality
python -m src.pipeline run --env <environment>

# 4. Check audit logs
docker exec mysql-test mysql -u root -ptestpw migration_db -e \
  "SELECT * FROM ops_migration_runs ORDER BY created_at DESC LIMIT 5;"
```

---

## Troubleshooting 🔧

### Common Issues

**Issue**: "Backup file not found"
```bash
# Solution: List available backups
ls -la backup_*.sql
# Use GitHub Actions artifacts if local backups missing
```

**Issue**: "Target version not found"
```bash
# Solution: Check migration history
docker exec mysql-test mysql -u root -ptestpw migration_db -e \
  "SELECT ID FROM DATABASECHANGELOG ORDER BY ORDEREXECUTED;"
```

**Issue**: "Permission denied"
```bash
# Solution: Check database credentials
echo $DB_PASSWORD  # Ensure environment loaded
source venv/bin/activate  # Ensure Python environment
```

---

## Contact & Support 📞

For rollback assistance:
1. **Check GitHub Actions logs** for auto-rollback details
2. **Review `ops_migration_runs`** table for run history
3. **Use `ROLLBACK_GUIDE.md`** for step-by-step instructions
4. **Create incident ticket** with rollback details

**Remember**: All rollbacks are logged and auditable! 🔍