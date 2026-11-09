/*
===============================================================================
Script: Gold Layer Quality Checks

Purpose:
    Performs data quality checks on Gold Layer views to ensure data accuracy
    and consistency.

Checks Include:
    - Validates customer, product, and sales views.
    - Identifies duplicate customer and product IDs.
    - Checks foreign key integrity between fact and dimension tables.

Usage:
    Execute after creating Gold Layer views to verify data quality.
===============================================================================
*/

-- =============================================================================
-- Gold Layer Quality Checks
-- =============================================================================

-- Check customer dimension
SELECT * FROM gold.dim_customers;

-- Check product dimension
SELECT * FROM gold.dim_products;

-- Check sales fact
SELECT * FROM gold.fact_sales;


-- =============================================================================
-- Check Duplicate Customer IDs
-- =============================================================================

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- =============================================================================
-- Check Duplicate Product IDs
-- =============================================================================

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- =============================================================================
-- Foreign Key Integrity Check
-- =============================================================================

SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL;


-- =============================================================================
-- End of Gold Layer DDL Script
-- =============================================================================
