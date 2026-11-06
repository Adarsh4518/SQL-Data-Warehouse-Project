
/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================

Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load)
    process to populate the Silver Layer tables from the Bronze Layer.

Actions Performed:
    1. Truncates existing Silver tables before loading fresh data.
    2. Extracts raw data from Bronze tables.
    3. Cleans and transforms the extracted data.
    4. Loads the transformed data into Silver tables.

Tables Processed:

    CRM:
        - crm_cust_info
        - crm_prd_info
        - crm_sales_details

    ERP:
        - erp_cust_az12
        - erp_loc_a101
        - erp_px_cat_g1v2

Parameters:
    None.

Usage Example:
    CALL silver.load_silver();

WARNING:
    This procedure truncates all six Silver tables before loading.
    Existing Silver data will be permanently deleted and replaced.

===============================================================================
*/


/*
===============================================================================
STEP 1: CREATE STORED PROCEDURE
===============================================================================
Purpose:
    Create a stored procedure named load_silver.

    The procedure performs the complete data transformation
    and loading process from Bronze to Silver.
===============================================================================
*/

-- Change delimiter to allow stored procedure creation
DELIMITER //

-- Drop the existing procedure if it already exists
DROP PROCEDURE IF EXISTS silver.load_silver //

-- Create the Silver loading procedure
CREATE PROCEDURE silver.load_silver()
BEGIN


    /*
    ===========================================================================
    STEP 2: LOAD CRM CUSTOMER INFORMATION
    ===========================================================================
    Source Table:
        bronze.crm_cust_info

    Target Table:
        silver.crm_cust_info

    Transformations:
        - Remove duplicate customer records.
        - Retain the latest record based on creation date.
        - Remove unwanted spaces from first and last names.
        - Standardize marital status.
        - Standardize gender values.
    ===========================================================================
    */

    -- Remove existing data from the Silver customer table
    TRUNCATE TABLE silver.crm_cust_info;

    -- Insert cleaned and transformed customer data
    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,

        -- Remove leading and trailing spaces
        TRIM(cst_firstname),
        TRIM(cst_lastname),

        -- Standardize marital status
        CASE
            WHEN cst_marital_status = 'M' THEN 'MARRIED'
            WHEN cst_marital_status = 'S' THEN 'SINGLE'
            ELSE 'N/A'
        END,

        -- Standardize gender values
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
            ELSE 'N/A'
        END,

        cst_create_date

    FROM (
        -- Identify duplicate customer records using ROW_NUMBER()
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS ranks

        FROM bronze.crm_cust_info

    ) AS t

    -- Retain only the latest record for each customer
    WHERE ranks = 1;


    /*
    ===========================================================================
    STEP 3: LOAD CRM PRODUCT INFORMATION
    ===========================================================================
    Source Table:
        bronze.crm_prd_info

    Target Table:
        silver.crm_prd_info

    Transformations:
        - Extract category ID from the product key.
        - Remove category information from the product key.
        - Replace NULL product costs with zero.
        - Standardize product line descriptions.
        - Calculate product end dates using LEAD().
    ===========================================================================
    */

    -- Remove existing data from the Silver product table
    TRUNCATE TABLE silver.crm_prd_info;

    -- Insert cleaned and transformed product data
    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,

        -- Extract category ID and replace hyphens with underscores
        REPLACE(
            SUBSTRING(prd_key, 1, 5),
            '-',
            '_'
        ) AS cat_id,

        -- Extract product key by removing the category prefix
        SUBSTRING(
            prd_key,
            7,
            LENGTH(prd_key)
        ) AS prd_key,

        prd_nm,

        -- Replace NULL product costs with zero
        IFNULL(prd_cost, 0) AS prd_cost,

        -- Standardize product line descriptions
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'N/A'
        END AS prd_line,

        prd_start_dt,

        -- Calculate product end date using the next start date
        DATE_SUB(
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            ),
            INTERVAL 1 DAY
        ) AS prd_end_dt

    FROM bronze.crm_prd_info;


    /*
    ===========================================================================
    STEP 4: LOAD CRM SALES DETAILS
    ===========================================================================
    Source Table:
        bronze.crm_sales_details

    Target Table:
        silver.crm_sales_details

    Transformations:
        - Convert order dates into DATE format.
        - Handle invalid and missing dates.
        - Validate sales amounts.
        - Recalculate incorrect sales values.
        - Correct missing or invalid selling prices.
    ===========================================================================
    */

    -- Remove existing data from the Silver sales table
    TRUNCATE TABLE silver.crm_sales_details;

    -- Insert cleaned and transformed sales data
    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        -- Convert order date from YYYYMMDD into DATE format
        -- Return NULL for invalid or missing order dates
        CASE
            WHEN sls_order_dt = 0
              OR LENGTH(sls_order_dt) != 8
            THEN NULL

            ELSE STR_TO_DATE(
                CAST(sls_order_dt AS CHAR),
                '%Y%m%d'
            )
        END AS sls_order_dt,

        -- Convert shipping date into DATE format
        CASE
            WHEN sls_ship_dt IS NULL THEN NULL

            ELSE STR_TO_DATE(
                CAST(sls_ship_dt AS CHAR),
                '%Y-%m-%d'
            )
        END AS sls_ship_dt,

        -- Retain the existing due date
        sls_due_dt,

        -- Validate sales amount and recalculate if necessary
        CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales != sls_quantity * ABS(sls_price)

            THEN sls_quantity * ABS(sls_price)

            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        -- Recalculate selling price if it is missing or invalid
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0

            THEN sls_sales / NULLIF(sls_quantity, 0)

            ELSE sls_price
        END AS sls_price

    FROM bronze.crm_sales_details;


    /*
    ===========================================================================
    STEP 5: LOAD ERP CUSTOMER INFORMATION (AZ12)
    ===========================================================================
    Source Table:
        bronze.erp_cust_az12

    Target Table:
        silver.erp_cust_az12

    Transformations:
        - Remove the 'NAS' prefix from customer IDs.
        - Identify and handle future birth dates.
        - Standardize gender values.
    ===========================================================================
    */

    -- Remove existing data from the Silver ERP customer table
    TRUNCATE TABLE silver.erp_cust_az12;

    -- Insert cleaned and transformed ERP customer data
    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT

        -- Remove NAS prefix from customer ID
        CASE
            WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LENGTH(cid))

            ELSE cid
        END AS cid,

        -- Replace future birth dates with NULL
        CASE
            WHEN bdate > CURRENT_DATE() THEN NULL
            ELSE bdate
        END AS bdate,

        -- Standardize gender values
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
            THEN 'Female'

            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
            THEN 'Male'

            ELSE 'n/a'
        END AS gen

    FROM bronze.erp_cust_az12;


    /*
    ===========================================================================
    STEP 6: LOAD ERP LOCATION INFORMATION (A101)
    ===========================================================================
    Source Table:
        bronze.erp_loc_a101

    Target Table:
        silver.erp_loc_a101

    Transformations:
        - Remove hyphens from customer IDs.
        - Standardize country names.
        - Handle missing country values.
    ===========================================================================
    */

    -- Remove existing data from the Silver ERP location table
    TRUNCATE TABLE silver.erp_loc_a101;

    -- Insert cleaned and transformed ERP location data
    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT

        -- Remove hyphens from customer ID
        REPLACE(cid, '-', '') AS cid,

        -- Standardize country names and handle missing values
        CASE
            WHEN TRIM(cntry) = 'DE'
            THEN 'Germany'

            WHEN TRIM(cntry) IN ('US', 'USA')
            THEN 'United States'

            WHEN TRIM(cntry) = '' OR cntry IS NULL
            THEN 'n/a'

            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101;


    /*
    ===========================================================================
    STEP 7: LOAD ERP PRODUCT CATEGORY INFORMATION (G1V2)
    ===========================================================================
    Source Table:
        bronze.erp_px_cat_g1v2

    Target Table:
        silver.erp_px_cat_g1v2

    Transformations:
        - Transfer product category information.
        - Preserve category, subcategory and maintenance details.
    ===========================================================================
    */

    -- Remove existing data from the Silver ERP product category table
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    -- Insert product category data into Silver
    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat_g1v2;


END //

-- Restore the default delimiter
DELIMITER ;


/*
===============================================================================
STEP 8: EXECUTE STORED PROCEDURE
===============================================================================
Purpose:
    Execute the stored procedure to perform the complete
    Bronze-to-Silver ETL process.
===============================================================================
*/

CALL silver.load_silver();


/*
===============================================================================
END OF SILVER LAYER LOADING SCRIPT
===============================================================================
*/
