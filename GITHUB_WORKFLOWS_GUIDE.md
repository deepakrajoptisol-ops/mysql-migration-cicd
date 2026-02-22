# 🚀 GitHub Workflows Guide - Migration CI/CD Pipeline

## 📋 Workflow Overview

This repository implements a comprehensive CI/CD pipeline for database migrations with proper approval processes, automated testing, and backup management.

---

## 🔄 Complete Process Flow

### **Step 1: User Updates Migration Script**
1. Developer creates new migration file in `migrations/` folder
2. Uses web UI or direct file creation
3. Follows naming convention: `XXX_description.up.sql`

### **Step 2: Create Pull Request to Main**
1. Developer creates PR with new migration file
2. **Triggers**: `CI Validation` workflow
3. **Actions**: 
   - Validates file format and headers
   - Checks SQL syntax
   - No database operations performed
   - Comments on PR with validation results

### **Step 3: PR Approval and Merge**
1. Approver reviews and approves PR
2. PR is merged to main branch
3. **Triggers**: `Auto-Deploy to Dev` workflow
4. **Actions**:
   - Detects new migration files
   - Creates backup with migration IDs in filename
   - Applies migrations to dev database
   - Runs data pipeline
   - Stores backup in repository
   - Comments on commit with results

### **Step 4: Dev Validation Success**
1. Dev deployment completes successfully
2. Team validates functionality in dev environment
3. Ready for production deployment

### **Step 5: Production Change Request**
1. Manual trigger of `Deploy to Production` workflow
2. **Required Inputs**:
   - Change Request/Ticket ID
   - Migration IDs to deploy
   - Allow destructive operations (optional)
   - Emergency deployment flag (optional)
3. **Requires**: GitHub Environment approval (prod reviewers)

### **Step 6: Production Deployment**
1. Pre-deployment validation
2. Comprehensive backup creation
3. Migration application with auto-rollback
4. Smoke tests and integrity verification
5. Backup committed to repository
6. Deployment summary created

---

## 🛠️ Workflow Files

### **1. CI Validation** (`.github/workflows/ci.yml`)
**Trigger**: Pull requests with migration files
**Purpose**: Validate migration files without database operations

```yaml
Triggers:
  - pull_request (paths: migrations/*.up.sql)

Jobs:
  - validate-migrations: Format and syntax validation
  - Comment on PR with results
```

**What it does:**
- ✅ Validates filename format (`XXX_description.up.sql`)
- ✅ Checks required headers (`id`, `author`, `risk`)
- ✅ Validates ID consistency between filename and header
- ✅ Checks for destructive operations
- ✅ Offline changelog validation
- 💬 Comments on PR with validation status

### **2. Auto-Deploy to Dev** (`.github/workflows/auto-migration.yml`)
**Trigger**: Push to main with migration files
**Purpose**: Automatically deploy approved migrations to dev

```yaml
Triggers:
  - push to main (paths: migrations/*.up.sql)

Jobs:
  - detect-and-deploy-dev: Deploy to dev environment
```

**What it does:**
- 🔍 Detects new migration files from merge
- 💾 Creates backup: `backups/dev_pre_migration_{IDs}_{timestamp}.sql`
- 🚀 Applies migrations to dev database
- 🔄 Runs data pipeline
- 🔍 Verifies migration integrity
- 📁 Commits backup to repository
- 💬 Comments on commit with deployment status
- 🛡️ Auto-rollback on failure

### **3. Deploy to Production** (`.github/workflows/deploy-prod.yml`)
**Trigger**: Manual workflow dispatch
**Purpose**: Deploy migrations to production with approvals

```yaml
Triggers:
  - workflow_dispatch (manual)

Inputs:
  - change_ticket_id: Required change request ID
  - migration_ids: Comma-separated migration IDs
  - allow_destructive: Boolean for destructive operations
  - emergency_deployment: Boolean for emergency bypass

Jobs:
  - pre-deployment-checks: Validate deployment request
  - deploy-production: Execute production deployment
```

**What it does:**
- 🔍 Pre-deployment validation of migration IDs
- 🛡️ Checks for destructive operations
- 💾 Creates comprehensive backup: `backups/prod_pre_migration_{IDs}_{timestamp}.sql`
- 🚀 Applies migrations to production
- 🧪 Runs smoke tests
- 🔍 Verifies integrity
- 📁 Commits backup with metadata
- 🚨 Emergency rollback on failure
- 📊 Creates deployment summary

---

## 📁 Backup Naming Convention

### **Development Backups**
```
backups/dev_pre_migration_011_012_20260222_143022.sql
```
- `dev`: Environment
- `pre_migration`: Backup type
- `011_012`: Migration IDs being applied
- `20260222_143022`: Timestamp (YYYYMMDD_HHMMSS)

### **Production Backups**
```
backups/prod_pre_migration_011_012_013_20260222_143022.sql
backups/prod_pre_migration_011_012_013_20260222_143022.sql.meta
```
- Includes metadata file with deployment details
- Longer retention period (365 days vs 90 days)

---

## 🔐 Required GitHub Secrets

### **Repository Secrets** (for production)
Set these in: Settings → Secrets and variables → Actions

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `PROD_DB_HOST` | Production database host | `sql12.freesqldatabase.com` |
| `PROD_DB_PORT` | Production database port | `3306` |
| `PROD_DB_USER` | Production database user | `prod_user` |
| `PROD_DB_PASSWORD` | Production database password | `secure_password` |
| `PROD_DB_NAME` | Production database name | `prod_database` |

### **Environment Configuration**
Create GitHub Environment "prod" with:
- Required reviewers (1-2 people)
- Protection rules
- Deployment timeout (30 minutes)

---

## 📊 Database Configuration

### **Development Environment** (Hardcoded)
```
Host: sql12.freesqldatabase.com
Port: 3306
User: sql12817767
Password: Ajb7KukR9R
Database: sql12817767
```

### **Test Environment** (Hardcoded)
```
Host: sql12.freesqldatabase.com
Port: 3306
User: sql12817769
Password: AEAhD5Vuqs
Database: sql12817769
```

### **Production Environment** (Secrets)
Configure via GitHub repository secrets (see above)

---

## 🎯 Usage Examples

### **Example 1: Standard Migration Deployment**

1. **Create migration file**:
   ```sql
   -- migrations/011_add_user_preferences.up.sql
   -- id: 011
   -- author: developer
   -- risk: low
   
   CREATE TABLE user_preferences (
     id BIGINT AUTO_INCREMENT PRIMARY KEY,
     user_id BIGINT NOT NULL,
     preference_key VARCHAR(255) NOT NULL,
     preference_value TEXT
   );
   ```

2. **Create PR**: 
   - CI validates the file
   - Approver reviews and merges

3. **Auto-deployment to dev**:
   - Creates backup: `backups/dev_pre_migration_011_20260222_143022.sql`
   - Applies migration to dev
   - Comments on commit with success

4. **Production deployment**:
   - Go to Actions → "Deploy to Production"
   - Fill inputs:
     - Change Ticket: `CR-2024-001`
     - Migration IDs: `011`
     - Allow Destructive: `false`
   - Approve deployment
   - Creates backup: `backups/prod_pre_migration_011_20260222_150000.sql`

### **Example 2: Multiple Migrations**

1. **Create multiple files**: `012_add_indexes.up.sql`, `013_update_schema.up.sql`
2. **Single PR** with both files
3. **Dev deployment**: Backup named `dev_pre_migration_012_013_timestamp.sql`
4. **Prod deployment**: Input `012,013` in migration IDs field

### **Example 3: Emergency Deployment**

1. **Critical hotfix** needed in production
2. **Manual trigger** with:
   - Emergency Deployment: `true`
   - Change Ticket: `INC-2024-005`
   - Migration IDs: `014`
3. **Expedited process** with emergency flags

---

## 🛡️ Safety Features

### **Validation Safeguards**
- ✅ File format validation
- ✅ Required header checks
- ✅ ID consistency validation
- ✅ Destructive operation detection
- ✅ Migration existence verification

### **Backup Protection**
- 💾 Automatic backup before every deployment
- 📁 Backup stored in repository and artifacts
- 🏷️ Descriptive naming with migration IDs
- ⏰ Long retention periods (90-365 days)
- 📋 Metadata tracking for production

### **Rollback Capabilities**
- 🔄 Automatic rollback on migration failure
- 🚨 Emergency rollback procedures
- 💾 Backup restoration with detailed logging
- 📊 Comprehensive failure reporting

### **Approval Controls**
- 👥 Required reviewers for production
- 🎫 Mandatory change ticket IDs
- 🔒 Environment protection rules
- ⏰ Deployment timeouts

---

## 📈 Monitoring and Artifacts

### **Backup Artifacts**
- **Location**: GitHub Actions artifacts + repository `backups/` folder
- **Retention**: 90 days (dev), 365 days (prod)
- **Format**: SQL dump with metadata
- **Access**: Via web UI or repository

### **Deployment Tracking**
- **Comments**: Automatic comments on commits/PRs
- **Logs**: Detailed workflow execution logs
- **Artifacts**: Backup files and metadata
- **History**: Complete audit trail in repository

### **Failure Handling**
- **Auto-rollback**: Immediate restoration on failure
- **Notifications**: Detailed failure reports
- **Runbooks**: Step-by-step recovery procedures
- **Incident tracking**: Integration with change tickets

---

## 🎉 Benefits of This Approach

### **For Developers**
- 🚀 Streamlined deployment process
- 🔍 Immediate validation feedback
- 💾 Automatic backup management
- 🛡️ Safety nets and rollback protection

### **For Operations**
- 📊 Complete audit trail
- 🎫 Change management integration
- 🔒 Approval-based production deployments
- 📁 Centralized backup storage

### **For Business**
- ⚡ Faster development cycles
- 🛡️ Reduced deployment risks
- 📈 Improved reliability
- 🔍 Better compliance and tracking

---

**This CI/CD pipeline provides enterprise-grade database migration management with comprehensive safety features and approval workflows!** 🚀