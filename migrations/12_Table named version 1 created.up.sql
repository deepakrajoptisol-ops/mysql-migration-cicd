-- =============================================================================
-- Migration 12: Table Named Version 1 Created
-- Uploaded via web interface on 2026-02-22 23:32:08
-- =============================================================================
-- id: 12
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE sample3 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);