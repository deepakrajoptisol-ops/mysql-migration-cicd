# GitHub Setup Instructions

## Step 1: Create Repository on GitHub.com

1. Go to https://github.com/new
2. Repository name: `mysql-migration-cicd`
3. Description: `Enterprise MySQL migration system with CI/CD`
4. Public repository (for free GitHub Actions)
5. Do NOT initialize with README
6. Click "Create repository"

## Step 2: Push Code to GitHub

```bash
cd "/home/laptop-rt-10/projects/Technical Competency/iteration2"

# Add your GitHub repo as remote
git remote add origin https://github.com/deepakrajoptisol-ops/mysql-migration-cicd.git

# Push to GitHub
git push -u origin main
```

## Step 3: Set Up GitHub Environments

### 3a. Create "dev" Environment
1. Go to your repo → Settings → Environments
2. Click "New environment"
3. Name: `dev`
4. Add secrets:
   - `DB_HOST`: `127.0.0.1` (or your dev DB host)
   - `DB_PORT`: `3306`
   - `DB_USER`: `root`
   - `DB_PASSWORD`: `your_dev_password`
   - `DB_NAME`: `migration_db_dev`

### 3b. Create "prod" Environment  
1. Click "New environment"
2. Name: `prod`
3. **Enable "Required reviewers"** → Add yourself
4. Add secrets:
   - `DB_HOST`: `your_prod_host`
   - `DB_PORT`: `3306` 
   - `DB_USER`: `migrator_user`
   - `DB_PASSWORD`: `your_prod_password`
   - `DB_NAME`: `migration_db_prod`

## Step 4: Test the Workflows

### Test CI (automatic)
1. Create a new branch: `git checkout -b test-ci`
2. Make a small change to README
3. Push: `git push origin test-ci`
4. Create Pull Request on GitHub
5. Watch CI workflow run automatically

### Test Dev Deploy (automatic)
1. Merge PR to main
2. Watch dev deploy workflow run automatically

### Test Prod Deploy (manual)
1. Go to Actions → Deploy Prod → Run workflow
2. Fill in inputs:
   - `allow_destructive`: false
   - `change_ticket_id`: TEST-001
3. Approve the deployment (required reviewer)
4. Watch prod deploy run

## Step 5: Monitor Results

Check these after each workflow:
- **Actions tab**: See workflow logs
- **Artifacts**: Download backup files
- **Database**: Verify migrations applied
- **Audit tables**: Check `DATABASECHANGELOG`, `ops_migration_runs`

## Troubleshooting

If workflows fail:
1. Check the logs in Actions tab
2. Verify environment secrets are set correctly
3. Ensure MySQL service is accessible
4. Check backup artifacts were created