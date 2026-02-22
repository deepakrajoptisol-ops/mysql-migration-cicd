-- =============================================================================
-- Migration 001: Initial Schema
-- Creates staging layer, curated star-schema layer, and pipeline ops tables.
-- MySQL 8.0+ compatible.  All tables use InnoDB for transactional safety.
-- =============================================================================
-- id: 001
-- author: platform-team
-- risk: low
-- allowDestructive: false
-- labels: schema,init
-- contexts: dev,prod

-- ---------------------------------------------------------------------------
-- STAGING LAYER  (raw data landing zone; source-aligned)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS stg_customers (
    customer_id   BIGINT       PRIMARY KEY,
    full_name     VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    country       CHAR(2)      NOT NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS stg_orders (
    order_id      BIGINT        PRIMARY KEY,
    customer_id   BIGINT        NOT NULL,
    order_date    DATE          NOT NULL,
    amount        DECIMAL(12,2) NOT NULL,
    currency      CHAR(3)       NOT NULL DEFAULT 'USD',
    status        VARCHAR(20)   NOT NULL DEFAULT 'pending',
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME      NOT NULL,
    KEY idx_stg_orders_customer (customer_id),
    KEY idx_stg_orders_date     (order_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- CURATED LAYER  (star schema for analytics consumption)
-- ---------------------------------------------------------------------------

-- Slowly Changing Dimension Type 2 for customer attributes
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_sk     BIGINT       AUTO_INCREMENT PRIMARY KEY,
    customer_id     BIGINT       NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    email_masked    CHAR(64)     NOT NULL COMMENT 'SHA-256 hash of email for privacy',
    country         CHAR(2)      NOT NULL,
    effective_from  DATETIME     NOT NULL,
    effective_to    DATETIME     NULL,
    is_current      TINYINT(1)   NOT NULL DEFAULT 1,
    KEY idx_dim_cust_bk      (customer_id),
    KEY idx_dim_cust_current (is_current, customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Fact table for orders (grain = one row per order)
CREATE TABLE IF NOT EXISTS fact_order (
    order_id      BIGINT        PRIMARY KEY,
    customer_sk   BIGINT        NOT NULL,
    order_date    DATE          NOT NULL,
    amount        DECIMAL(12,2) NOT NULL,
    currency      CHAR(3)       NOT NULL,
    status        VARCHAR(20)   NOT NULL,
    load_run_id   CHAR(36)      NOT NULL,
    KEY idx_fact_order_date (order_date),
    KEY idx_fact_order_cust (customer_sk),
    KEY idx_fact_order_run  (load_run_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- PIPELINE OPERATIONAL TABLES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ops_pipeline_runs (
    run_id      CHAR(36)    PRIMARY KEY,
    env_name    VARCHAR(32) NOT NULL,
    started_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP   NULL,
    status      ENUM('running','succeeded','failed') NOT NULL,
    git_sha     CHAR(40)    NULL,
    actor       VARCHAR(128) NULL,
    details     JSON         NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ops_dq_results (
    run_id       CHAR(36)      NOT NULL,
    check_name   VARCHAR(128)  NOT NULL,
    status       ENUM('pass','fail') NOT NULL,
    metric_value DECIMAL(20,4) NULL,
    threshold    DECIMAL(20,4) NULL,
    details      JSON          NULL,
    created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (run_id, check_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ops_checkpoints (
    dataset_name   VARCHAR(128) PRIMARY KEY,
    last_watermark VARCHAR(64)  NOT NULL,
    updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
