-- =============================================================================
-- Migration 002: Mytable Named Version 3 Created
-- Uploaded via web interface on 2026-02-22 22:28:21
-- =============================================================================
-- id: 002
-- author: deepakrajoptisol-ops
-- risk: low
-- allowDestructive: false
-- labels: web-upload
-- contexts: dev,prod

CREATE TABLE mytable2 (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    created_at DATE
);