-- =============================================================================
-- Transform: Build dim_customer  (SCD Type 2)
--
-- Step 1: Close (expire) current dimension records whose attributes changed.
-- Step 2: Insert new or changed records as the new "current" version.
--
-- Idempotent: re-running with the same staging data produces no duplicates
-- because Step 1 only matches is_current=1 rows with diffs, and Step 2
-- only inserts where no current record exists (or just expired).
-- =============================================================================

-- Step 1: expire changed records
UPDATE dim_customer d
INNER JOIN stg_customers s ON s.customer_id = d.customer_id
SET
    d.effective_to = NOW(),
    d.is_current   = 0
WHERE d.is_current = 1
  AND (   d.full_name    <> s.full_name
       OR d.country      <> s.country
       OR d.email_masked <> SHA2(s.email, 256));

-- Step 2: insert new / changed as current
INSERT INTO dim_customer
    (customer_id, full_name, email_masked, country, effective_from, effective_to, is_current)
SELECT
    s.customer_id,
    s.full_name,
    SHA2(s.email, 256),
    s.country,
    NOW(),
    NULL,
    1
FROM stg_customers s
LEFT JOIN dim_customer d
    ON  d.customer_id = s.customer_id
    AND d.is_current  = 1
WHERE d.customer_sk IS NULL;
