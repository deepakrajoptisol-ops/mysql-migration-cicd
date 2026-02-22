-- =============================================================================
-- Migration 009: Add Rollback and Version Tracking Tables
-- Adds comprehensive tracking for rollback operations and version history
-- =============================================================================
-- id: 009
-- author: system
-- risk: low
-- allowDestructive: false
-- labels: ops,tracking,rollback
-- contexts: dev,prod

-- Migration runs tracking table
CREATE TABLE IF NOT EXISTS ops_migration_runs (
    run_id VARCHAR(36) PRIMARY KEY,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    status ENUM('running', 'completed', 'failed') NOT NULL DEFAULT 'running',
    applied_changesets INT DEFAULT 0,
    error_message TEXT NULL,
    context_name VARCHAR(50) NULL,
    
    INDEX idx_migration_runs_started (started_at),
    INDEX idx_migration_runs_status (status),
    INDEX idx_migration_runs_context (context_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Rollback operations tracking table
CREATE TABLE IF NOT EXISTS ops_rollback_runs (
    run_id VARCHAR(36) PRIMARY KEY,
    target_version VARCHAR(10) NOT NULL,
    backup_file VARCHAR(255) NOT NULL,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    status ENUM('started', 'completed', 'failed') NOT NULL DEFAULT 'started',
    removed_migrations JSON NULL,
    error_message TEXT NULL,
    initiated_by VARCHAR(100) NULL,
    environment VARCHAR(50) NULL,
    
    INDEX idx_rollback_runs_started (started_at),
    INDEX idx_rollback_runs_status (status),
    INDEX idx_rollback_runs_target (target_version),
    INDEX idx_rollback_runs_env (environment)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Version history tracking for audit trail
CREATE TABLE IF NOT EXISTS ops_version_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    version_id VARCHAR(10) NOT NULL,
    action ENUM('applied', 'rolled_back', 'failed') NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    run_id VARCHAR(36) NULL,
    backup_file VARCHAR(255) NULL,
    environment VARCHAR(50) NULL,
    details JSON NULL,
    
    INDEX idx_version_history_version (version_id),
    INDEX idx_version_history_timestamp (timestamp),
    INDEX idx_version_history_action (action),
    INDEX idx_version_history_env (environment)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Backup metadata tracking
CREATE TABLE IF NOT EXISTS ops_backup_metadata (
    backup_file VARCHAR(255) PRIMARY KEY,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    file_size BIGINT NULL,
    migration_version VARCHAR(10) NULL,
    environment VARCHAR(50) NULL,
    backup_type ENUM('manual', 'pre_migration', 'pre_rollback', 'scheduled') NOT NULL,
    retention_until DATE NULL,
    
    INDEX idx_backup_created (created_at),
    INDEX idx_backup_version (migration_version),
    INDEX idx_backup_type (backup_type),
    INDEX idx_backup_retention (retention_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert sample data for existing migrations (if any)
INSERT IGNORE INTO ops_version_history (version_id, action, timestamp, environment, details)
SELECT 
    ID as version_id,
    'applied' as action,
    DATEEXECUTED as timestamp,
    'unknown' as environment,
    JSON_OBJECT('author', AUTHOR, 'filename', FILENAME) as details
FROM DATABASECHANGELOG
WHERE ID IS NOT NULL;