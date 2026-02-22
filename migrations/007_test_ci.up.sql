-- =============================================================================
-- Migration 007: Test CI Pipeline
-- Simple test migration to verify CI/CD pipeline functionality
-- =============================================================================
-- id: 007
-- author: test-user
-- risk: low
-- allowDestructive: false
-- labels: test,ci
-- contexts: dev,prod

-- Add a simple test table
CREATE TABLE test_ci_table (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    test_message VARCHAR(255) NOT NULL DEFAULT 'CI Pipeline Working!',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO test_ci_table (test_message) VALUES 
('Migration 007 applied successfully'),
('Auto-changelog generation working'),
('GitHub Actions CI/CD operational');