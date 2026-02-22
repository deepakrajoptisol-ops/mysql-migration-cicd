# 🧪 End-to-End UI Testing Guide

## Overview
This guide provides comprehensive instructions for testing the Migration Management Web UI from start to finish. It includes both automated and manual testing approaches to ensure all functionality works correctly.

---

## 🚀 Quick Start

### 1. Prerequisites
```bash
# Ensure MySQL container is running
docker ps | grep mysql-test

# If not running, start it:
docker run --name mysql-test -e MYSQL_ROOT_PASSWORD=testpw -e MYSQL_DATABASE=migration_db -p 3307:3306 -d mysql:8.0
```

### 2. Start the Web UI
```bash
# Start the web interface
./start_web.sh
```

### 3. Verify Server is Running
```bash
# Test API endpoint
curl http://localhost:8000/api/migrations/status
```

---

## 🔧 Testing Tools Provided

### 1. **Automated API Testing**
**File:** `test_web_ui_e2e.py`

```bash
# Run comprehensive API tests
python test_web_ui_e2e.py

# Test specific URL
python test_web_ui_e2e.py http://localhost:8000
```

**What it tests:**
- ✅ Server health and responsiveness
- ✅ All API endpoints functionality
- ✅ Error handling and validation
- ✅ Performance (response times)
- ✅ Data consistency across endpoints
- ✅ Frontend resource accessibility

### 2. **Interactive Manual Testing**
**File:** `test_ui_interactive.html`

```bash
# Open in browser
open test_ui_interactive.html
# or
firefox test_ui_interactive.html
```

**What it covers:**
- 📊 Dashboard functionality
- 🔄 Navigation and tabs
- 📝 Form validation
- 🔄 Auto-refresh behavior
- 💾 Backup operations
- ⏪ Rollback procedures
- ❌ Error scenarios

---

## 📋 Complete Test Scenarios

### **Scenario 1: Fresh Installation Test**

**Objective:** Test the UI with a clean database

```bash
# 1. Reset database (if needed)
docker stop mysql-test
docker rm mysql-test
docker run --name mysql-test -e MYSQL_ROOT_PASSWORD=testpw -e MYSQL_DATABASE=migration_db -p 3307:3306 -d mysql:8.0

# 2. Wait for MySQL to start
sleep 10

# 3. Initialize database
source venv/bin/activate
python -c "from src.migrate.runner import update_cmd; update_cmd()"

# 4. Start web UI
./start_web.sh
```

**Expected Results:**
- Dashboard shows 0 pending, some applied migrations
- All Versions tab shows migration history
- No backups initially available

### **Scenario 2: Add New Migration Test**

**Objective:** Test the complete migration upload workflow

**Steps:**
1. **Go to Upload Migration tab**
2. **Fill form with test data:**
   ```
   Migration ID: 012
   Description: test_ui_functionality
   Author: test-user
   Risk Level: Low
   SQL Content: CREATE TABLE test_table (id INT PRIMARY KEY);
   GitHub Token: [your-token] (optional)
   Commit Message: Add migration 012: test_ui_functionality
   ```
3. **Submit form**
4. **Verify results:**
   - Success modal appears (if GitHub token provided)
   - OR validation error (if no token)
   - Form resets after successful submission

### **Scenario 3: Backup and Rollback Test**

**Objective:** Test backup creation and rollback functionality

**Steps:**
1. **Create Backup:**
   - Go to Backups tab
   - Click "Create Backup"
   - Verify success message and file appears in list

2. **Test Rollback Setup:**
   - Go to Rollback tab
   - Select a target version
   - Select the backup file
   - Check confirmation checkbox
   - Verify warnings appear for production environment

3. **Test Integration:**
   - Go to Backups tab
   - Click "Use for Rollback" on a backup
   - Verify it switches to Rollback tab with backup pre-selected

### **Scenario 4: Error Handling Test**

**Objective:** Test error scenarios and recovery

**Steps:**
1. **Network Errors:**
   - Stop web server: `Ctrl+C` in terminal
   - Try refreshing browser
   - Verify user-friendly error messages
   - Restart server and verify recovery

2. **Validation Errors:**
   - Submit forms with missing required fields
   - Enter invalid data
   - Verify client-side validation works

3. **API Errors:**
   - Use browser dev tools to simulate network failures
   - Test timeout scenarios

---

## 📊 Test Checklist

### **Dashboard Tests** ✅
- [ ] Dashboard cards display correct numbers
- [ ] Auto-refresh works (30-second interval)
- [ ] Navigation tabs function correctly
- [ ] Status indicators are accurate

### **All Versions Tab** ✅
- [ ] Migration timeline displays correctly
- [ ] Status indicators (applied/pending) are accurate
- [ ] Risk level badges are color-coded
- [ ] Rollback buttons work for applied migrations
- [ ] Apply button enables/disables correctly
- [ ] Refresh button updates data

### **Upload Migration Tab** ✅
- [ ] Form auto-populates next available ID
- [ ] Author field is pre-filled
- [ ] Commit message auto-updates
- [ ] Client-side validation works
- [ ] SQL template is helpful and accurate
- [ ] GitHub integration works (if token provided)
- [ ] Success/error modals display correctly

### **Rollback Tab** ✅
- [ ] Target version dropdown populates with applied migrations
- [ ] Backup file dropdown shows available backups
- [ ] Environment selection works
- [ ] Confirmation checkbox is required
- [ ] Production warnings are prominent
- [ ] Form validation prevents invalid submissions

### **Backups Tab** ✅
- [ ] Backup list displays with correct metadata
- [ ] File sizes are formatted correctly
- [ ] Creation dates are accurate
- [ ] "Create Backup" functionality works
- [ ] "Use for Rollback" buttons work
- [ ] Integration with Rollback tab functions

### **Error Handling** ✅
- [ ] Network errors show user-friendly messages
- [ ] Loading modals appear during operations
- [ ] Success modals provide useful information
- [ ] Error modals are informative and actionable
- [ ] Form validation is comprehensive
- [ ] Recovery from errors works smoothly

---

## 🎯 Performance Benchmarks

### **Response Time Targets**
- Dashboard load: < 1 second
- API calls: < 500ms
- Backup creation: < 10 seconds
- Migration application: < 30 seconds

### **Load Testing**
```bash
# Test concurrent requests
for i in {1..10}; do
  curl -s http://localhost:8000/api/migrations/status &
done
wait
```

---

## 🐛 Common Issues and Solutions

### **Issue: Database Connection Failed**
```
Solution:
1. Check MySQL container: docker ps | grep mysql
2. Verify port 3307 is available: netstat -an | grep 3307
3. Check environment variables in env.local
4. Restart container if needed: docker restart mysql-test
```

### **Issue: Web Server Won't Start**
```
Solution:
1. Check if port 8000 is in use: lsof -i :8000
2. Verify virtual environment: source venv/bin/activate
3. Install dependencies: pip install -r web/requirements.txt
4. Check Python path and imports
```

### **Issue: GitHub Upload Fails**
```
Solution:
1. Verify GitHub token has 'repo' scope
2. Check repository name in app.py (GITHUB_REPO variable)
3. Test token with: curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
4. Verify network connectivity to GitHub
```

### **Issue: Backup Creation Fails**
```
Solution:
1. Check MySQL credentials in environment
2. Verify mysqldump is installed: which mysqldump
3. Check disk space: df -h
4. Verify database permissions
```

---

## 📈 Test Reporting

### **Automated Test Report**
The automated test script generates detailed JSON reports:
```bash
python test_web_ui_e2e.py
# Creates: web_ui_test_report_YYYYMMDD_HHMMSS.json
```

### **Manual Test Report**
The interactive test page allows downloading test results:
1. Complete all manual tests
2. Click "Download Test Report"
3. Review JSON report for documentation

### **Test Report Contents**
```json
{
  "timestamp": "2026-02-22T18:35:06.123Z",
  "total_tests": 16,
  "passed_tests": 15,
  "failed_tests": 1,
  "test_results": {
    "dashboard-load": true,
    "navigation-tabs": true,
    // ... more results
  }
}
```

---

## 🚀 Continuous Testing

### **Pre-deployment Checklist**
1. Run automated test suite: `python test_web_ui_e2e.py`
2. Complete critical path manual tests
3. Verify all API endpoints respond correctly
4. Test error scenarios and recovery
5. Check performance benchmarks
6. Validate cross-browser compatibility

### **Regression Testing**
After any code changes:
1. Run full automated test suite
2. Test affected functionality manually
3. Verify no existing features are broken
4. Update tests if new features are added

---

## 🎉 Success Criteria

The Migration Management Web UI is considered fully functional when:

✅ **All automated tests pass** (10/11 or better)  
✅ **All manual tests complete successfully**  
✅ **Dashboard displays accurate real-time data**  
✅ **All tabs and navigation work smoothly**  
✅ **Form validation prevents invalid submissions**  
✅ **Error handling is user-friendly**  
✅ **Backup and rollback operations function correctly**  
✅ **Performance meets benchmarks**  
✅ **GitHub integration works (when configured)**  
✅ **Cross-browser compatibility is verified**  

---

## 📞 Support and Troubleshooting

### **Debug Mode**
```bash
cd web
python -c "
import app
import uvicorn
uvicorn.run(app.app, host='0.0.0.0', port=8000, log_level='debug')
"
```

### **Browser Developer Tools**
1. Open browser dev tools (F12)
2. Check Console tab for JavaScript errors
3. Monitor Network tab for API calls
4. Use Application tab to inspect local storage

### **Log Analysis**
- Web server logs: Console output from `./start_web.sh`
- Database logs: `docker logs mysql-test`
- Migration logs: Database `ops_*` tables

---

**The Migration Management Web UI provides a comprehensive, user-friendly interface for managing database migrations with enterprise-grade safety features!** 🚀