-- =============================================================================
-- Data Quality Checks  (reference SQL — executed programmatically by
-- src/pipeline/validate.py, which records results in ops_dq_results)
-- =============================================================================

-- DQ-1: Orphan orders (customer FK not found in staging)
SELECT COUNT(*) AS orphan_count
FROM stg_orders o
LEFT JOIN stg_customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- DQ-2: Duplicate order IDs in staging
SELECT COUNT(*) AS dup_count
FROM (
    SELECT order_id
    FROM stg_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x;

-- DQ-3: Reconciliation — fact count vs joinable staging count
SELECT
    (SELECT COUNT(*)
     FROM stg_orders o
     INNER JOIN stg_customers c ON c.customer_id = o.customer_id) AS stg_joinable,
    (SELECT COUNT(*) FROM fact_order)                               AS fact_count;

-- DQ-4: Null / empty required fields in stg_customers
SELECT COUNT(*) AS null_count
FROM stg_customers
WHERE full_name IS NULL OR full_name = ''
   OR email     IS NULL OR email     = ''
   OR country   IS NULL OR country   = '';

-- DQ-5: Negative or zero order amounts
SELECT COUNT(*) AS bad_amount_count
FROM stg_orders
WHERE amount <= 0;
