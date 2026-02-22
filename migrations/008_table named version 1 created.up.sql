-- =============================================================================
-- Migration 008: Table Named Version 1 Created
-- Uploaded via web interface on 2026-02-22 22:52:23
-- =============================================================================
-- id: 008
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE IF NOT EXISTS sample (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);