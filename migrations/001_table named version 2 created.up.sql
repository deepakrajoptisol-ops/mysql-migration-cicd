-- =============================================================================
-- Migration 001: Table Named Version 2 Created
-- Uploaded via web interface on 2026-02-22 22:07:57
-- Updated to trigger workflow with MySQL compatibility fix
-- =============================================================================
-- id: 002
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE mytable_v2 (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    created_at DATE
);