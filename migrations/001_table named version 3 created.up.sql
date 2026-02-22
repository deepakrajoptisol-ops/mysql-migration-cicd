-- =============================================================================
-- Migration 001: Table Named Version 3 Created
-- Uploaded via web interface on 2026-02-22 22:23:05
-- =============================================================================
-- id: 003
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE IF NOT EXISTS mytable_v3 (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    created_at DATE
);