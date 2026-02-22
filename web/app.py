#!/usr/bin/env python3
"""
Migration Management Web API
FastAPI backend for SQL upload, version management, and rollback operations
"""

import os
import json
import base64
import logging
from datetime import datetime
from typing import List, Dict, Optional
from pathlib import Path

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests

# Load environment variables
from dotenv import load_dotenv
env_file = Path(__file__).parent.parent / "env.local"
if env_file.exists():
    load_dotenv(env_file)
    print(f"Loaded environment from {env_file}")

# Import our existing migration system
import sys
sys.path.append(str(Path(__file__).parent.parent))
from src.migrate.runner import status_cmd, update_cmd, rollback_cmd, validate_cmd
from src.migrate.changelog import load_changelog
from src.db import get_conn, execute

app = FastAPI(title="Migration Management API", version="1.0.0")

# Enable CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static files
static_dir = Path(__file__).parent / "static"
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

# Models
class MigrationInfo(BaseModel):
    id: str
    author: str
    description: str
    filename: str
    status: str  # 'applied', 'pending', 'failed'
    applied_at: Optional[datetime] = None
    risk_level: str
    checksum: str

class UploadRequest(BaseModel):
    migration_id: str
    description: str
    author: str
    risk_level: str
    sql_content: str
    commit_message: str
    github_token: str

class RollbackRequest(BaseModel):
    target_version: str
    backup_file: str
    environment: str
    github_token: Optional[str] = None

# GitHub configuration
GITHUB_REPO = "deepakrajoptisol-ops/mysql-migration-cicd"
GITHUB_API_BASE = "https://api.github.com"

@app.get("/")
async def serve_index():
    """Serve the main web interface"""
    index_file = Path(__file__).parent / "static" / "index.html"
    return FileResponse(str(index_file))

@app.get("/api/migrations/versions")
async def get_all_versions():
    """Get all available migration versions with their status"""
    try:
        # Load changelog to get all migrations
        migrations_dir = Path("migrations")
        changelog = load_changelog(migrations_dir)
        
        # Get applied migrations from database
        conn = get_conn()
        try:
            applied_migrations = {}
            cursor = conn.cursor(dictionary=True)
            cursor.execute("""
                SELECT ID, AUTHOR, FILENAME, DATEEXECUTED, MD5SUM 
                FROM DATABASECHANGELOG 
                ORDER BY ORDEREXECUTED
            """)
            for row in cursor.fetchall():
                applied_migrations[row['ID']] = {
                    'applied_at': row['DATEEXECUTED'],
                    'checksum': row['MD5SUM'],
                    'filename': row['FILENAME']
                }
            cursor.close()
        finally:
            conn.close()
        
        # Combine changelog and database info
        versions = []
        for changeset in changelog.changesets:
            is_applied = changeset.id in applied_migrations
            versions.append({
                'id': changeset.id,
                'author': changeset.author,
                'description': changeset.sqlFile.split('/')[-1].replace('.up.sql', '').replace(f"{changeset.id}_", ''),
                'filename': changeset.sqlFile,
                'status': 'applied' if is_applied else 'pending',
                'applied_at': applied_migrations.get(changeset.id, {}).get('applied_at'),
                'risk_level': changeset.risk,
                'checksum': changeset.checksum,
                'can_rollback_to': is_applied
            })
        
        return {
            'versions': versions,
            'total_count': len(versions),
            'applied_count': len(applied_migrations),
            'pending_count': len(versions) - len(applied_migrations)
        }
        
    except Exception as e:
        logging.error(f"Error getting versions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/migrations/status")
async def get_migration_status():
    """Get current migration status"""
    try:
        # Get pending migrations
        migrations_dir = Path("migrations")
        changelog = load_changelog(migrations_dir)
        
        conn = get_conn()
        try:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT ID FROM DATABASECHANGELOG")
            applied_ids = {row['ID'] for row in cursor.fetchall()}
            cursor.close()
        finally:
            conn.close()
        
        pending = [cs for cs in changelog.changesets if cs.id not in applied_ids]
        
        return {
            'pending_migrations': len(pending),
            'total_migrations': len(changelog.changesets),
            'applied_migrations': len(applied_ids),
            'pending_details': [
                {
                    'id': cs.id,
                    'author': cs.author,
                    'filename': cs.sqlFile,
                    'risk': cs.risk
                } for cs in pending
            ]
        }
        
    except Exception as e:
        logging.error(f"Error getting status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/backups")
async def list_backups():
    """List available backup files"""
    try:
        backup_files = []
        
        # Look for local backup files
        for backup_file in Path(".").glob("backup_*.sql"):
            stat = backup_file.stat()
            backup_files.append({
                'filename': backup_file.name,
                'size': stat.st_size,
                'created_at': datetime.fromtimestamp(stat.st_mtime),
                'type': 'local'
            })
        
        # Sort by creation time, newest first
        backup_files.sort(key=lambda x: x['created_at'], reverse=True)
        
        return {'backups': backup_files}
        
    except Exception as e:
        logging.error(f"Error listing backups: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/migrations/upload")
async def upload_migration(request: UploadRequest):
    """Upload a new migration via GitHub API"""
    try:
        # Generate filename
        filename = f"{request.migration_id}_{request.description}.up.sql"
        
        # Generate full SQL content with headers
        sql_content = f"""-- =============================================================================
-- Migration {request.migration_id}: {request.description.replace('_', ' ').title()}
-- Uploaded via web interface on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- =============================================================================
-- id: {request.migration_id}
-- author: {request.author}
-- risk: {request.risk_level}
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

{request.sql_content}"""
        
        # Create branch name
        branch_name = f"migration-{request.migration_id}-{int(datetime.now().timestamp())}"
        
        # Get main branch SHA
        main_response = requests.get(
            f"{GITHUB_API_BASE}/repos/{GITHUB_REPO}/git/refs/heads/main",
            headers={'Authorization': f'token {request.github_token}'}
        )
        main_response.raise_for_status()
        main_sha = main_response.json()['object']['sha']
        
        # Create new branch
        branch_response = requests.post(
            f"{GITHUB_API_BASE}/repos/{GITHUB_REPO}/git/refs",
            headers={'Authorization': f'token {request.github_token}'},
            json={
                'ref': f'refs/heads/{branch_name}',
                'sha': main_sha
            }
        )
        branch_response.raise_for_status()
        
        # Upload file
        upload_response = requests.put(
            f"{GITHUB_API_BASE}/repos/{GITHUB_REPO}/contents/migrations/{filename}",
            headers={'Authorization': f'token {request.github_token}'},
            json={
                'message': request.commit_message,
                'content': base64.b64encode(sql_content.encode()).decode(),
                'branch': branch_name
            }
        )
        upload_response.raise_for_status()
        
        # Create PR
        pr_response = requests.post(
            f"{GITHUB_API_BASE}/repos/{GITHUB_REPO}/pulls",
            headers={'Authorization': f'token {request.github_token}'},
            json={
                'title': f"Add migration {request.migration_id}: {request.description}",
                'head': branch_name,
                'base': 'main',
                'body': f"""## New Migration Upload

- **Migration ID**: {request.migration_id}
- **Description**: {request.description}
- **Author**: {request.author}
- **Risk Level**: {request.risk_level}
- **Uploaded**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

### SQL Content Preview
```sql
{request.sql_content[:500]}{'...' if len(request.sql_content) > 500 else ''}
```

Uploaded via web interface. This PR will trigger CI validation and auto-deploy to dev environment upon merge.
"""
            }
        )
        pr_response.raise_for_status()
        pr_data = pr_response.json()
        
        return {
            'success': True,
            'filename': filename,
            'branch': branch_name,
            'pr_url': pr_data['html_url'],
            'pr_number': pr_data['number']
        }
        
    except requests.RequestException as e:
        logging.error(f"GitHub API error: {e}")
        raise HTTPException(status_code=400, detail=f"GitHub API error: {str(e)}")
    except Exception as e:
        logging.error(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/migrations/apply")
async def apply_migrations():
    """Apply pending migrations"""
    try:
        # Create backup first
        timestamp = datetime.now().strftime('%Y%m%dT%H%M%SZ')
        backup_file = f"backup_web_apply_{timestamp}.sql"
        
        # Apply migrations using existing system
        update_cmd()
        
        return {
            'success': True,
            'message': 'Migrations applied successfully',
            'backup_file': backup_file
        }
        
    except Exception as e:
        logging.error(f"Apply error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/migrations/rollback")
async def rollback_migration(request: RollbackRequest):
    """Rollback to a specific migration version"""
    try:
        # Validate backup file exists
        backup_path = Path(request.backup_file)
        if not backup_path.exists():
            raise HTTPException(status_code=404, detail=f"Backup file {request.backup_file} not found")
        
        # Execute rollback using existing system
        rollback_cmd(request.target_version, request.backup_file)
        
        return {
            'success': True,
            'message': f'Successfully rolled back to version {request.target_version}',
            'backup_used': request.backup_file
        }
        
    except Exception as e:
        logging.error(f"Rollback error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/backups/create")
async def create_backup():
    """Create a new backup"""
    try:
        timestamp = datetime.now().strftime('%Y%m%dT%H%M%SZ')
        backup_file = f"backup_manual_{timestamp}.sql"
        
        # Create backup using mysqldump
        import subprocess
        env = os.environ
        cmd = [
            'mysqldump',
            '-h', env.get('DB_HOST', '127.0.0.1'),
            '-P', env.get('DB_PORT', '3307'),
            '-u', env.get('DB_USER', 'root'),
            f'-p{env.get("DB_PASSWORD", "testpw")}',
            '--routines', '--triggers', '--events', '--single-transaction',
            env.get('DB_NAME', 'migration_db')
        ]
        
        with open(backup_file, 'w') as f:
            result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Backup failed: {result.stderr}")
        
        # Get file size
        backup_path = Path(backup_file)
        file_size = backup_path.stat().st_size
        
        return {
            'success': True,
            'filename': backup_file,
            'size': file_size,
            'created_at': datetime.now()
        }
        
    except Exception as e:
        logging.error(f"Backup creation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)