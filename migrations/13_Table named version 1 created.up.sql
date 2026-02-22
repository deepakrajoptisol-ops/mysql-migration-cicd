-- =============================================================================
-- Migration 13: Table Named Version 1 Created
-- Uploaded via web interface on 2026-02-22 23:38:10
-- =============================================================================
-- id: 13
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE sample (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);