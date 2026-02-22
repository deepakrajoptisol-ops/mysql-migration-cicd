-- =============================================================================
-- Migration 002: Mytable Named Version 3 Created
-- Uploaded via web interface on 2026-02-22 22:28:21
-- =============================================================================
-- id: 004
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE IF NOT EXISTS mytable_v4 (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    created_at DATE
);