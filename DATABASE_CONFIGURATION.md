# 🗄️ Database Configuration Summary

## 📋 Environment Database Assignments

### **Development Environment** 
```
Host: sql12.freesqldatabase.com
Port: 3306
User: sql12817767
Password: Ajb7KukR9R
Database: sql12817767
```
**Usage**: 
- Local development via `./start_web.sh`
- Auto-deployment after PR merge to main
- Dev environment testing and validation

### **Production Environment**
```
Host: sql12.freesqldatabase.com
Port: 3306
User: sql12817769
Password: AEAhD5Vuqs
Database: sql12817769
```
**Usage**:
- Production deployments via manual workflow
- Requires Change Request approval
- Protected with GitHub Environment controls

### **CI/Test Environment**
```
Host: 127.0.0.1 (MySQL service container)
Port: 3306
User: root
Password: ci_test_pw
Database: migration_test_db
```
**Usage**:
- GitHub Actions CI validation
- Ephemeral container for testing
- No persistent data

---

## 🔄 Updated Workflow Process

### **1. User Creates Migration**
- Creates migration file in `migrations/` folder
- Creates PR to main branch

### **2. PR Validation** 
- CI validates file format (uses temporary MySQL container)
- No real database operations
- Approver reviews and merges PR

### **3. Auto-Deploy to Dev**
- Triggers on merge to main
- Uses **Development Database** (`sql12817767`)
- Creates backup: `backups/dev_pre_migration_{IDs}_{timestamp}.sql`
- Applies migrations and runs tests

### **4. Auto-Create Production CR**
- **NEW**: Automatically creates Change Request issue
- Includes all deployment details and approval checklist
- Assigns to migration author
- Labels: `production-deployment`, `change-request`, `database-migration`

### **5. Production Deployment**
- Manual workflow trigger with CR number
- Uses **Production Database** (`sql12817769`)
- Requires GitHub Environment approval
- Creates backup: `backups/prod_pre_migration_{IDs}_{timestamp}.sql`
- Auto-updates CR status on completion

---

## 🎫 Automatic Change Request Process

### **CR Creation (After Dev Success)**
When dev deployment succeeds, an automatic CR is created with:

```
Title: 🏭 Production CR: Deploy Migrations 011,012 (CR-2026-02-22T18-45-30)
Labels: production-deployment, change-request, database-migration, auto-generated
Assignee: Migration author
```

**CR Contents**:
- ✅ Change request details with auto-generated CR number
- ✅ List of migration files to deploy
- ✅ Dev environment validation results
- ✅ Production deployment plan
- ✅ Risk assessment and rollback plan
- ✅ Approval checklist for stakeholders
- ✅ Step-by-step deployment instructions
- ✅ Contact information and artifacts

### **CR Management**
- **Created**: Automatically after successful dev deployment
- **Assigned**: To migration author for tracking
- **Approval**: Business and technical stakeholders check boxes
- **Deployment**: Via "Deploy to Production" workflow using CR number
- **Completion**: Auto-closed with success/failure status

---

## 🚀 How to Use

### **For Development**
```bash
# Start web UI with dev database
./start_web.sh

# Create migration file
# Create PR → Get approval → Merge
# Dev deployment happens automatically
# CR created automatically for production
```

### **For Production Deployment**
```bash
# After dev deployment creates CR:
# 1. Review the auto-created CR issue
# 2. Get stakeholder approvals (checkboxes in CR)
# 3. Go to Actions → "Deploy to Production"
# 4. Use CR number from the auto-created issue
# 5. Fill migration IDs from CR
# 6. Submit for GitHub Environment approval
# 7. Approver reviews and approves
# 8. Deployment executes and updates CR
```

---

## 📁 File Locations

### **Environment Files**
- `env.local` - Development database credentials
- `env.test` - Local testing configuration (service container)

### **Backup Storage**
- `backups/dev_pre_migration_*` - Development backups
- `backups/prod_pre_migration_*` - Production backups
- GitHub Actions artifacts (90-365 day retention)

### **Workflow Files**
- `.github/workflows/ci.yml` - PR validation (uses MySQL container)
- `.github/workflows/auto-migration.yml` - Dev deployment + CR creation
- `.github/workflows/deploy-prod.yml` - Production deployment + CR updates

---

## 🔐 Security Notes

### **Development Credentials**
- Hardcoded in workflows for simplicity
- Suitable for development environment
- No sensitive production data

### **Production Credentials**  
- Hardcoded in production workflow
- Protected by GitHub Environment controls
- Requires manual approval for deployment
- Change Request process for audit compliance

### **CI/Test Credentials**
- Ephemeral MySQL service container
- No persistent data or credentials
- Safe for public repositories

---

## 🎯 Key Benefits

### **Automated CR Process**
- ✅ No manual CR creation needed
- ✅ Comprehensive deployment documentation
- ✅ Built-in approval workflows
- ✅ Automatic status tracking

### **Database Separation**
- ✅ Clear environment boundaries
- ✅ Safe development and testing
- ✅ Protected production environment
- ✅ Audit trail for all changes

### **Backup Management**
- ✅ Automatic backup creation
- ✅ Descriptive naming with migration IDs
- ✅ Repository and artifact storage
- ✅ Easy rollback procedures

---

**Your database migration pipeline now includes automatic Change Request creation and management!** 🚀