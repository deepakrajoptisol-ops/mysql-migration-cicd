-- =============================================================================
-- Migration 002: Performance Indexes
-- Adds indexes optimised for incremental processing and analytics queries.
-- =============================================================================
-- id: 002
-- author: platform-team
-- risk: low
-- allowDestructive: false
-- labels: performance
-- contexts: dev,prod

-- Incremental processing: watermark-based lookups
CREATE INDEX idx_stg_customers_updated ON stg_customers(updated_at);
CREATE INDEX idx_stg_orders_updated    ON stg_orders(updated_at);

-- Analytics: composite covering index for date + customer queries
CREATE INDEX idx_fact_order_date_cust   ON fact_order(order_date, customer_sk);

-- Analytics: covering index for order-status reporting
CREATE INDEX idx_fact_order_status_date ON fact_order(status, order_date, amount);
