# 🌐 Migration Management Web UI

## Overview
The Migration Management Web UI provides a user-friendly interface for uploading SQL migrations, viewing all versions, managing rollbacks, and monitoring the complete migration lifecycle through GitHub Actions integration.

---

## 🚀 Quick Start

### 1. Start the Web UI
```bash
# Make sure your database is running (MySQL container)
docker run --name mysql-test -e MYSQL_ROOT_PASSWORD=testpw -e MYSQL_DATABASE=migration_db -p 3307:3306 -d mysql:8.0

# Start the web interface
./start_web.sh
```

### 2. Access the Interface
Open your browser and go to: **http://localhost:8000**

---

## 📊 Features Overview

### **Dashboard**
- **Real-time statistics**: Applied, pending, and total migrations
- **System health**: Database connection status
- **Backup count**: Available backup files
- **Auto-refresh**: Updates every 30 seconds

### **All Versions Tab**
- **Timeline view**: Visual representation of all migrations
- **Status indicators**: Applied ✅, Pending ⏰, Failed ❌
- **Risk levels**: Color-coded badges (Low/Medium/High)
- **One-click rollback**: Direct rollback buttons for applied migrations
- **Refresh**: Manual refresh of migration status

### **Upload Migration Tab**
- **SQL template**: Pre-filled template with required headers
- **Form validation**: Ensures all required fields are filled
- **GitHub integration**: Direct upload to GitHub repository
- **Auto-PR creation**: Creates pull request automatically
- **Real-time feedback**: Success/error notifications

### **Rollback Tab**
- **Version selection**: Dropdown of all rollback-able versions
- **Backup selection**: Choose from available backup files
- **Environment selection**: Dev/Staging/Production
- **Safety confirmations**: Multiple confirmation steps
- **Destructive operation warnings**: Clear warnings about data loss

### **Backups Tab**
- **Backup listing**: All available backup files with metadata
- **File information**: Size, creation date, type
- **Manual backup creation**: Create backups on-demand
- **Rollback integration**: Use backups directly for rollback

---

## 🔧 User Workflows

### **Workflow 1: Upload New Migration**

1. **Go to "Upload Migration" tab**
2. **Fill in the form**:
   - Migration ID (auto-suggested)
   - Description (e.g., `add_user_preferences_table`)
   - Author (pre-filled with your username)
   - Risk Level (Low/Medium/High)
   - SQL Content (your migration SQL)
   - GitHub Token (for API access)
   - Commit Message (auto-generated)

3. **Click "Upload & Create PR"**
4. **System automatically**:
   - Validates SQL format and headers
   - Creates new branch in GitHub
   - Uploads SQL file
   - Creates pull request
   - Triggers CI validation

5. **GitHub Actions will**:
   - Validate SQL syntax and format
   - Test migration application
   - Run data pipeline tests
   - Comment on PR with results

6. **Merge PR** → Auto-deploys to dev environment

### **Workflow 2: View All Versions**

1. **Go to "All Versions" tab**
2. **See timeline** of all migrations with:
   - Migration ID and description
   - Author and filename
   - Application date/time
   - Risk level and status
   - Rollback buttons for applied migrations

3. **Click "Rollback to here"** for quick rollback setup

### **Workflow 3: Rollback to Previous Version**

1. **Go to "Rollback" tab**
2. **Select target version** from dropdown
3. **Choose backup file** (with size and date info)
4. **Select environment** (Dev/Staging/Prod)
5. **Check confirmation** checkbox
6. **Click "Execute Rollback"**
7. **System will**:
   - Restore database from backup
   - Remove newer migration records
   - Update audit trail
   - Provide success confirmation

### **Workflow 4: Backup Management**

1. **Go to "Backups" tab**
2. **View all backups** with metadata
3. **Create new backup** with "Create Backup" button
4. **Use for rollback** with direct integration

---

## 🔐 Security & Authentication

### **GitHub Token Requirements**
- **Scope needed**: `repo` (full repository access)
- **Generate at**: https://github.com/settings/tokens
- **Used for**: Creating branches, uploading files, creating PRs

### **Environment Protection**
- **Dev**: No approval required
- **Staging**: Optional approval workflow
- **Production**: Required reviewers + manual approval

### **Access Control**
- **Local access**: Web UI runs on localhost:8000
- **Database access**: Uses existing environment credentials
- **GitHub access**: User-provided tokens

---

## 🛠️ API Endpoints

The web UI is powered by a FastAPI backend with these endpoints:

### **Migration Management**
- `GET /api/migrations/versions` - Get all migration versions
- `GET /api/migrations/status` - Get current migration status
- `POST /api/migrations/upload` - Upload new migration via GitHub
- `POST /api/migrations/apply` - Apply pending migrations
- `POST /api/migrations/rollback` - Execute rollback

### **Backup Management**
- `GET /api/backups` - List available backups
- `POST /api/backups/create` - Create new backup

### **Static Files**
- `GET /` - Main web interface
- `GET /static/*` - CSS, JS, and other assets

---

## 📁 File Structure

```
web/
├── app.py              # FastAPI backend application
├── requirements.txt    # Python dependencies for web UI
└── static/
    ├── index.html      # Main web interface
    └── app.js          # Frontend JavaScript logic

start_web.sh           # Startup script for web UI
WEB_UI_GUIDE.md       # This documentation
```

---

## 🔄 Integration with GitHub Actions

### **Auto-Migration Workflow**
When you upload a migration via the web UI:

1. **File uploaded** to GitHub repository
2. **Auto-Migration workflow** triggers
3. **Validation steps** run:
   - SQL format validation
   - Header validation
   - Migration testing
4. **PR commented** with results
5. **Merge triggers** dev deployment

### **Manual Production Deployment**
For production deployments:

1. **Go to GitHub Actions**
2. **Select "Deploy Prod" workflow**
3. **Click "Run workflow"**
4. **Fill inputs**:
   - Allow destructive operations (true/false)
   - Change ticket ID (for audit)
5. **Approve deployment** (required reviewer)
6. **Auto-rollback** on failure

---

## 🚨 Error Handling & Troubleshooting

### **Common Issues**

**Issue**: "GitHub API error: 403 Forbidden"
```
Solution: Check your GitHub token has 'repo' scope
Generate new token at: https://github.com/settings/tokens
```

**Issue**: "Database connection failed"
```
Solution: Ensure MySQL container is running
docker ps | grep mysql-test
If not running: docker start mysql-test
```

**Issue**: "Migration validation failed"
```
Solution: Check SQL file format and required headers
Ensure headers: -- id:, -- author:, -- risk:
```

**Issue**: "Backup file not found"
```
Solution: Create backup first or select existing backup
Use "Backups" tab to create new backup
```

### **Debug Mode**
To run in debug mode with detailed logs:
```bash
cd web
python -c "
import app
import uvicorn
uvicorn.run(app.app, host='0.0.0.0', port=8000, log_level='debug')
"
```

---

## 🎯 Best Practices

### **Migration Upload**
1. **Test locally first** before uploading
2. **Use descriptive names** for migration IDs
3. **Include proper risk assessment**
4. **Add meaningful commit messages**
5. **Review PR before merging**

### **Rollback Operations**
1. **Always backup before rollback**
2. **Test rollback in dev first**
3. **Coordinate with application teams**
4. **Document rollback reasons**
5. **Verify application functionality after rollback**

### **Backup Management**
1. **Create backups before major changes**
2. **Verify backup integrity**
3. **Clean up old backups regularly**
4. **Store critical backups externally**

---

## 🔮 Advanced Features

### **Real-time Updates**
- Dashboard auto-refreshes every 30 seconds
- Migration status updates automatically
- Backup list refreshes after operations

### **Audit Trail**
All operations are logged in database tables:
- `ops_migration_runs` - Migration executions
- `ops_rollback_runs` - Rollback operations
- `ops_version_history` - Version change history
- `ops_backup_metadata` - Backup file tracking

### **GitHub Integration**
- Automatic branch creation
- PR creation with detailed descriptions
- CI workflow integration
- Artifact management

---

## 📞 Support & Maintenance

### **Logs Location**
- **Web UI logs**: Console output when running `start_web.sh`
- **Migration logs**: Database `ops_*` tables
- **GitHub Actions logs**: Repository Actions tab

### **Monitoring**
- **Database health**: Connection status in dashboard
- **Migration status**: Real-time in "All Versions" tab
- **Backup status**: File count and sizes in dashboard

### **Maintenance Tasks**
1. **Regular backup cleanup**: Remove old backup files
2. **Database maintenance**: Clean up old audit records
3. **Token rotation**: Update GitHub tokens periodically
4. **Dependency updates**: Keep web UI dependencies current

---

## 🎉 Success Indicators

When everything is working correctly, you should see:

✅ **Dashboard shows** current migration counts  
✅ **All Versions** displays migration timeline  
✅ **Upload works** and creates GitHub PRs  
✅ **Rollback functions** with proper confirmations  
✅ **Backups create** and list properly  
✅ **GitHub Actions** trigger on uploads  
✅ **Auto-deployment** works on PR merge  

**The web UI provides a complete, enterprise-ready migration management system!** 🚀