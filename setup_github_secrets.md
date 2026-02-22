# 🔐 GitHub Secrets Setup Guide

## Required GitHub Repository Secrets

You need to set up the following secrets in your GitHub repository for the workflows to work with your new database credentials.

### 🛠️ How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each secret below

---

## 🌍 Environment-Specific Secrets

### **Production Environment Secrets**
*These should be set in the `prod` environment (Settings → Environments → prod)*

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `PROD_DB_HOST` | `sql12.freesqldatabase.com` | Production database host |
| `PROD_DB_PORT` | `3306` | Production database port |
| `PROD_DB_USER` | `[YOUR_PROD_USER]` | Production database user |
| `PROD_DB_PASSWORD` | `[YOUR_PROD_PASSWORD]` | Production database password |
| `PROD_DB_NAME` | `[YOUR_PROD_DATABASE]` | Production database name |

---

## 📋 Current Configuration Summary

### **Development Environment** (Hardcoded in workflows)
- **Host:** `sql12.freesqldatabase.com`
- **Port:** `3306`
- **User:** `sql12817767`
- **Password:** `Ajb7KukR9R`
- **Database:** `sql12817767`

### **Test Environment** (Hardcoded in workflows)
- **Host:** `sql12.freesqldatabase.com`
- **Port:** `3306`
- **User:** `sql12817769`
- **Password:** `AEAhD5Vuqs`
- **Database:** `sql12817769`

---

## 🚀 Updated Workflow Files

The following GitHub workflow files have been updated to use your new database credentials:

### ✅ **Updated Files:**
- `.github/workflows/ci.yml` - Uses test database for CI
- `.github/workflows/auto-migration.yml` - Uses test for testing, dev for deployment
- `.github/workflows/deploy-dev.yml` - Uses dev database directly
- `.github/workflows/deploy-prod.yml` - Uses production secrets

### 🔄 **Key Changes Made:**
1. **Removed MySQL service containers** - Now connects to remote databases
2. **Updated environment variables** - Points to freesqldatabase.com
3. **Simplified secret management** - Dev/test credentials are hardcoded, prod uses secrets
4. **Maintained security** - Production credentials still use GitHub secrets

---

## 🧪 Testing the Setup

### **1. Test Local Environment**
```bash
# Test dev environment
./start_web.sh

# Test test environment  
ENVIRONMENT=test ./start_web.sh
# or
./start_web_test.sh
```

### **2. Test GitHub Workflows**
1. **Push to main branch** - Triggers CI and auto-deployment to dev
2. **Create a PR** - Triggers validation and testing
3. **Manual prod deployment** - Use "Deploy Prod" workflow (requires secrets)

---

## 🛡️ Security Notes

### **Development & Test Credentials**
- These are hardcoded in the workflows for simplicity
- Suitable for development and testing environments
- Consider using secrets for additional security if needed

### **Production Credentials**
- **MUST** use GitHub Environment secrets
- Requires manual setup in GitHub repository settings
- Protected by GitHub Environment protection rules

---

## 🔧 Environment File Updates

Your local environment files have been updated:

### **env.local** (Development)
```bash
DB_HOST=sql12.freesqldatabase.com
DB_PORT=3306
DB_USER=sql12817767
DB_PASSWORD=Ajb7KukR9R
DB_NAME=sql12817767
ENV_NAME=dev
```

### **env.test** (Test)
```bash
DB_HOST=sql12.freesqldatabase.com
DB_PORT=3306
DB_USER=sql12817769
DB_PASSWORD=AEAhD5Vuqs
DB_NAME=sql12817769
ENV_NAME=test
```

---

## 🎯 Next Steps

1. **✅ Local testing** - Verify web UI works with new credentials
2. **🔐 Set up production secrets** - Add prod secrets to GitHub repository
3. **🧪 Test workflows** - Push changes and verify GitHub Actions work
4. **📊 Monitor deployments** - Check workflow runs and database connections

---

**Your GitHub workflows are now configured to use the new database credentials!** 🚀