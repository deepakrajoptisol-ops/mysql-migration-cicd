-- =============================================================================
-- Migration 005: Add Order Priority
-- Adds priority field to track urgent/normal/low priority orders
-- =============================================================================
-- id: 005
-- author: product-team
-- risk: low
-- allowDestructive: false
-- labels: feature,priority
-- contexts: dev,prod

-- Add priority to staging orders
ALTER TABLE stg_orders 
ADD COLUMN priority VARCHAR(10) DEFAULT 'normal' NOT NULL;

-- Add priority to fact table
ALTER TABLE fact_order 
ADD COLUMN priority VARCHAR(10) DEFAULT 'normal' NOT NULL;

-- Create index for priority-based reporting
CREATE INDEX idx_fact_order_priority ON fact_order(priority, order_date);