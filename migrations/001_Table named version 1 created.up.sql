-- =============================================================================
-- Migration 001: Table Named Version 1 Created
-- Uploaded via web interface on 2026-02-22 19:43:53
-- =============================================================================
-- id: 001
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE IF NOT EXISTS mytable (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    created_at DATE
);