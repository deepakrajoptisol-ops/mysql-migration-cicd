-- =============================================================================
-- Migration 008: Create Sample Test Table
-- Creates a comprehensive test table to demonstrate CI/CD pipeline functionality
-- =============================================================================
-- id: 008
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: feature,testing,demo
-- contexts: dev,prod

-- Create the sampletest table with various column types
CREATE TABLE sampletest (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    test_description TEXT,
    test_status ENUM('pending', 'running', 'passed', 'failed') DEFAULT 'pending',
    test_score DECIMAL(5,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    test_data JSON,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Add indexes for performance
    INDEX idx_sampletest_status (test_status),
    INDEX idx_sampletest_active (is_active),
    INDEX idx_sampletest_created (created_at)
);

-- Insert sample test data
INSERT INTO sampletest (test_name, test_description, test_status, test_score, test_data) VALUES
('CI Pipeline Test', 'Validates GitHub Actions CI workflow', 'passed', 95.50, '{"pipeline": "github-actions", "duration": "2m30s"}'),
('Migration Validation', 'Tests auto-changelog generation', 'passed', 98.75, '{"migrations": 8, "checksum_valid": true}'),
('Database Rollback', 'Verifies auto-rollback functionality', 'passed', 92.00, '{"rollback_time": "15s", "data_loss": false}'),
('Performance Test', 'Checks query execution times', 'running', 0.00, '{"queries": 150, "avg_time": "0.05ms"}'),
('Security Audit', 'RBAC and data masking validation', 'pending', 0.00, '{"roles": 4, "masked_tables": 2}');

-- Create a view for active tests only
CREATE VIEW active_sampletest AS
SELECT 
    id,
    test_name,
    test_description,
    test_status,
    test_score,
    created_at
FROM sampletest 
WHERE is_active = TRUE
ORDER BY created_at DESC;