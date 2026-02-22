-- =============================================================================
-- Migration 003: RBAC and Data Masking
-- Creates masked / consumption views and documents RBAC grant strategy.
-- =============================================================================
-- id: 003
-- author: security-team
-- risk: medium
-- allowDestructive: false
-- labels: security,rbac
-- contexts: dev,prod

-- ---------------------------------------------------------------------------
-- MASKED VIEW: hides PII for analytics consumers
-- Analysts see only first initial + "***" and the SHA-256 email hash.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_masked AS
SELECT
    customer_sk,
    customer_id,
    CONCAT(LEFT(full_name, 1), '***')  AS full_name_masked,
    email_masked,
    country,
    effective_from,
    effective_to,
    is_current
FROM dim_customer;

-- ---------------------------------------------------------------------------
-- CONSUMPTION VIEW: order summary (aggregated by customer, country, month)
-- Demonstrates complex joins + aggregations for analytics workloads.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    d.customer_id,
    d.country,
    DATE_FORMAT(f.order_date, '%Y-%m')  AS order_month,
    COUNT(*)                            AS order_count,
    SUM(f.amount)                       AS total_amount,
    AVG(f.amount)                       AS avg_amount,
    MIN(f.amount)                       AS min_amount,
    MAX(f.amount)                       AS max_amount
FROM fact_order f
INNER JOIN dim_customer d
    ON d.customer_sk = f.customer_sk
    AND d.is_current = 1
GROUP BY d.customer_id, d.country, DATE_FORMAT(f.order_date, '%Y-%m');

-- ---------------------------------------------------------------------------
-- RBAC REFERENCE (MySQL GRANT statements)
-- These are documented as comments because the migration runner user
-- typically does not hold GRANT privileges.  A DBA applies these once
-- per environment using a privileged session.
--
-- Principle: least privilege, role separation.
--
-- 1. Migration runner  (schema changes + audit tables only)
--    CREATE USER IF NOT EXISTS 'migrator'@'%' IDENTIFIED BY '<secret>';
--    GRANT ALTER, CREATE, DROP, INDEX, REFERENCES
--          ON migration_db.* TO 'migrator'@'%';
--    GRANT SELECT, INSERT, UPDATE, DELETE
--          ON migration_db.DATABASECHANGELOG TO 'migrator'@'%';
--    GRANT SELECT, INSERT, UPDATE
--          ON migration_db.DATABASECHANGELOGLOCK TO 'migrator'@'%';
--    GRANT SELECT, INSERT, UPDATE
--          ON migration_db.ops_migration_runs TO 'migrator'@'%';
--
-- 2. Pipeline / ETL runner  (DML only, no DDL)
--    CREATE USER IF NOT EXISTS 'etl_runner'@'%' IDENTIFIED BY '<secret>';
--    GRANT SELECT, INSERT, UPDATE, DELETE
--          ON migration_db.stg_customers TO 'etl_runner'@'%';
--    GRANT SELECT, INSERT, UPDATE, DELETE
--          ON migration_db.stg_orders TO 'etl_runner'@'%';
--    GRANT SELECT, INSERT, UPDATE, DELETE
--          ON migration_db.dim_customer TO 'etl_runner'@'%';
--    GRANT SELECT, INSERT, UPDATE, DELETE
--          ON migration_db.fact_order TO 'etl_runner'@'%';
--    GRANT SELECT, INSERT, UPDATE
--          ON migration_db.ops_pipeline_runs TO 'etl_runner'@'%';
--    GRANT SELECT, INSERT
--          ON migration_db.ops_dq_results TO 'etl_runner'@'%';
--    GRANT SELECT, INSERT, UPDATE
--          ON migration_db.ops_checkpoints TO 'etl_runner'@'%';
--
-- 3. Analytics / read-only consumer
--    CREATE USER IF NOT EXISTS 'analytics_ro'@'%' IDENTIFIED BY '<secret>';
--    GRANT SELECT ON migration_db.vw_customer_masked TO 'analytics_ro'@'%';
--    GRANT SELECT ON migration_db.vw_order_summary   TO 'analytics_ro'@'%';
--    GRANT SELECT ON migration_db.fact_order          TO 'analytics_ro'@'%';
--    -- NOTE: No access to stg_* or dim_customer (contains PII).
-- ---------------------------------------------------------------------------
