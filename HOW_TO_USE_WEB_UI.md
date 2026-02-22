# 🌐 How to Use the Migration Management Web UI

## 🚀 Getting Started

### **Step 1: Start the Web UI**
```bash
# Make sure your database is running first
# Then start the web interface
./start_web.sh
```

### **Step 2: Open in Browser**
Navigate to: **http://localhost:8000**

---

## 📊 Dashboard Overview

When you first open the UI, you'll see the main dashboard with:

### **📈 Statistics Cards**
- **Applied Migrations**: Number of successfully applied migrations
- **Pending Migrations**: Migrations waiting to be applied  
- **Total Migrations**: All migrations in the system
- **Available Backups**: Number of backup files

### **🧭 Navigation Tabs**
- **All Versions**: View migration timeline and history
- **Upload Migration**: Create and upload new migrations
- **Rollback**: Safely rollback to previous versions
- **Backups**: Manage database backups

---

## 🔍 Tab 1: All Versions

### **What You'll See**
- **Timeline view** of all migrations
- **Status indicators**: ✅ Applied, ⏳ Pending, ❌ Failed
- **Risk level badges**: Color-coded (Low/Medium/High)
- **Migration details**: ID, description, author, date

### **Available Actions**
1. **Refresh**: Click "Refresh" to update the list
2. **Apply Migrations**: Click "Apply with Backup" to run pending migrations
3. **Rollback**: Click "Rollback to here" on any applied migration

### **How to Use**
```
1. Click "All Versions" tab
2. Review the migration timeline
3. Check status of each migration
4. Use "Apply with Backup" if you have pending migrations
5. Use "Rollback to here" if you need to revert changes
```

---

## 📤 Tab 2: Upload Migration

### **When to Use**
- Creating new database schema changes
- Adding new tables, columns, or indexes
- Updating existing database structure

### **Step-by-Step Process**

#### **Step 1: Fill the Form**
```
Migration ID: 012 (auto-suggested next available)
Description: add_user_notifications_table
Author: your-username (pre-filled)
Risk Level: Low/Medium/High
```

#### **Step 2: Write SQL Content**
Use the provided template:
```sql
-- =============================================================================
-- Migration 012: Add User Notifications Table
-- Brief explanation of what this migration does
-- =============================================================================
-- id: 012
-- author: your-username
-- risk: low
-- allowDestructive: false
-- labels: feature,notifications
-- contexts: dev,prod

-- Your SQL statements here
CREATE TABLE user_notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);
```

#### **Step 3: GitHub Integration (Optional)**
```
GitHub Token: ghp_xxxxxxxxxxxx (if you want to upload to GitHub)
Commit Message: Add migration 012: add_user_notifications_table (auto-generated)
```

#### **Step 4: Submit**
1. Click "Upload & Create PR"
2. If GitHub token provided: Creates PR automatically
3. If no token: Shows validation results only

### **What Happens Next**
- ✅ Form validation ensures all fields are correct
- 🔍 SQL syntax checking
- 📝 GitHub PR creation (if token provided)
- 🔄 CI workflow triggers for validation

---

## ⏪ Tab 3: Rollback

### **⚠️ Important Warning**
Rollback operations are **destructive** and will restore the database from a backup. Any data written after the backup timestamp will be **permanently lost**.

### **When to Use Rollback**
- Migration caused issues in production
- Need to revert to a previous stable state
- Emergency recovery situations

### **Step-by-Step Process**

#### **Step 1: Select Target Version**
```
Target Migration Version: [Dropdown of applied migrations]
Example: "011 - add_user_preferences_table (john-doe)"
```

#### **Step 2: Choose Backup File**
```
Backup File: [Dropdown of available backups]
Example: "backup_manual_20260222T183504Z.sql (0.03MB, 2026-02-22)"
```

#### **Step 3: Select Environment**
```
Environment: Development/Staging/Production
Note: Production requires additional confirmations
```

#### **Step 4: Confirm Operation**
```
☑️ I understand this operation is destructive and will restore 
   the database from the selected backup
```

#### **Step 5: Execute**
1. Click "Execute Rollback"
2. For Production: Additional warning dialog appears
3. Rollback executes with detailed logging
4. Success/failure notification displayed

### **Safety Features**
- 🛡️ Multiple confirmation steps
- ⚠️ Clear warnings about data loss
- 🔒 Extra protection for production environment
- 📋 Detailed logging and audit trail

---

## 💾 Tab 4: Backups

### **What You'll See**
- **Table of all backup files** with metadata
- **File information**: Name, size, creation date, type
- **Actions**: Use for rollback, download (future feature)

### **Available Actions**

#### **Create New Backup**
1. Click "Create Backup" button
2. Wait for backup creation (shows progress)
3. Success notification with file details
4. New backup appears in the list

#### **Use Backup for Rollback**
1. Click "Use for Rollback" on any backup
2. Automatically switches to Rollback tab
3. Pre-selects the chosen backup file
4. Continue with rollback process

### **Backup File Naming**
```
Format: backup_manual_YYYYMMDDTHHMMSSZ.sql
Example: backup_manual_20260222T183504Z.sql

Information shown:
- Filename: backup_manual_20260222T183504Z.sql
- Size: 0.03 MB
- Created: 2/22/2026, 6:35:04 PM
- Type: local
```

---

## 🎯 Common Use Cases

### **Use Case 1: Apply Pending Migrations**
```
1. Go to "All Versions" tab
2. See pending migrations (⏳ status)
3. Click "Apply with Backup"
4. Confirm the operation
5. Wait for completion
6. Verify success in timeline
```

### **Use Case 2: Upload New Migration**
```
1. Go to "Upload Migration" tab
2. Fill form with migration details
3. Write SQL in the text area
4. Add GitHub token (optional)
5. Click "Upload & Create PR"
6. Review success message and PR link
```

### **Use Case 3: Emergency Rollback**
```
1. Go to "Backups" tab
2. Click "Create Backup" (create current state backup)
3. Go to "Rollback" tab
4. Select target version (before the problem)
5. Choose appropriate backup file
6. Confirm destructive operation
7. Execute rollback
8. Verify system recovery
```

### **Use Case 4: Regular Backup Creation**
```
1. Go to "Backups" tab
2. Click "Create Backup"
3. Wait for completion
4. Verify backup in the list
5. Note backup details for future reference
```

---

## 🔧 Troubleshooting

### **Common Issues**

#### **"Database connection failed"**
```
Solution:
1. Check if database is running
2. Verify credentials in env.local
3. Test connection: curl http://localhost:8000/api/migrations/status
4. Restart web server if needed
```

#### **"GitHub upload failed"**
```
Solution:
1. Check GitHub token has 'repo' scope
2. Verify token is not expired
3. Test token: curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
4. Check repository permissions
```

#### **"Migration validation failed"**
```
Solution:
1. Check required headers (-- id:, -- author:, -- risk:)
2. Verify ID matches filename
3. Check SQL syntax
4. Review error message details
```

#### **"Backup creation failed"**
```
Solution:
1. Check disk space
2. Verify database permissions
3. Ensure mysqldump is available
4. Check database connection
```

### **Getting Help**
- Check browser console for JavaScript errors
- Review network tab for API call failures
- Check web server logs in terminal
- Verify database connectivity

---

## 🎉 Success Indicators

### **✅ Everything Working Correctly**
- Dashboard shows current statistics
- All tabs load without errors
- Migrations display in timeline
- Backup creation succeeds
- Form validation works properly
- API calls complete quickly (< 1 second)

### **🚀 Ready for Production Use**
- All tests pass in test suite
- GitHub integration configured
- Backup procedures tested
- Rollback procedures verified
- Team trained on UI usage

---

## 📱 UI Features

### **🎨 Modern Interface**
- Bootstrap 5 styling
- Responsive design
- Font Awesome icons
- Color-coded status indicators
- Loading animations

### **⚡ Real-time Updates**
- Auto-refresh every 30 seconds
- Live status indicators
- Instant feedback on operations
- Progress indicators for long operations

### **🛡️ Safety Features**
- Form validation
- Confirmation dialogs
- Error handling
- Success notifications
- Audit trail logging

---

**The Migration Management Web UI provides a complete, user-friendly interface for managing your database migrations safely and efficiently!** 🚀

## 🎯 Quick Reference

| Action | Tab | Steps |
|--------|-----|-------|
| **View Status** | All Versions | Click tab → Review timeline |
| **Apply Migrations** | All Versions | Click "Apply with Backup" → Confirm |
| **Upload Migration** | Upload Migration | Fill form → Write SQL → Submit |
| **Rollback Database** | Rollback | Select version → Choose backup → Confirm |
| **Create Backup** | Backups | Click "Create Backup" → Wait |
| **Use Backup** | Backups | Click "Use for Rollback" → Continue in Rollback tab |