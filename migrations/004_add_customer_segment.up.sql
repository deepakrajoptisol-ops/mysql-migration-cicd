-- =============================================================================
-- Migration 004: Add Customer Segmentation
-- Adds a customer_segment column to track VIP/Standard/New customers
-- =============================================================================
-- id: 004
-- author: data-team
-- risk: low
-- allowDestructive: false
-- labels: feature,segmentation
-- contexts: dev,prod

-- Add new column to staging table
ALTER TABLE stg_customers 
ADD COLUMN customer_segment VARCHAR(20) DEFAULT 'Standard' NOT NULL;

-- Add new column to dimension table  
ALTER TABLE dim_customer 
ADD COLUMN customer_segment VARCHAR(20) DEFAULT 'Standard' NOT NULL;

-- Create index for segment-based queries
CREATE INDEX idx_dim_customer_segment ON dim_customer(customer_segment);

-- Update existing records with business logic (simplified)
UPDATE dim_customer d
JOIN (
    SELECT f.customer_sk, SUM(f.amount) as total_amount
    FROM fact_order f
    GROUP BY f.customer_sk
) totals ON totals.customer_sk = d.customer_sk
SET d.customer_segment = CASE 
    WHEN totals.total_amount > 1000 THEN 'VIP'
    ELSE 'Standard'
END
WHERE d.is_current = 1;