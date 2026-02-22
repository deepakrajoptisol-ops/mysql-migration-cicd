-- =============================================================================
-- Transform: Build fact_order
--
-- Joins staging orders with the current dim_customer record to resolve
-- the surrogate key (customer_sk).
--
-- Uses INSERT ... ON DUPLICATE KEY UPDATE so the load is idempotent:
-- re-running with the same data updates existing rows rather than failing.
--
-- Requires: MySQL session variable @run_id to be set before execution.
-- =============================================================================

INSERT INTO fact_order
    (order_id, customer_sk, order_date, amount, currency, status, load_run_id)
SELECT
    o.order_id,
    d.customer_sk,
    o.order_date,
    o.amount,
    o.currency,
    o.status,
    @run_id
FROM stg_orders o
INNER JOIN dim_customer d
    ON  d.customer_id = o.customer_id
    AND d.is_current  = 1
ON DUPLICATE KEY UPDATE
    customer_sk  = VALUES(customer_sk),
    order_date   = VALUES(order_date),
    amount       = VALUES(amount),
    currency     = VALUES(currency),
    status       = VALUES(status),
    load_run_id  = VALUES(load_run_id);
