-- =============================================================================
-- Migration 005: Sample Table with Auto Increment
-- Created to demonstrate idempotent migrations
-- =============================================================================
-- id: 005
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: sample,auto-increment
-- contexts: dev,prod

CREATE TABLE IF NOT EXISTS sample (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);