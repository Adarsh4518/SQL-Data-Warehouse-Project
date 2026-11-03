
/*
===============================================================================
Bronze Layer: Data Loading Script
===============================================================================

Script Purpose:
    This script loads raw data from CSV files into the Bronze layer.

    The loading process consists of:
        1. Creating a stored procedure to truncate Bronze tables.
        2. Executing the procedure to prepare tables for fresh data.
        3. Loading CSV files into the respective Bronze tables.
        4. Validating the loaded data using row counts.

Tables:
    CRM:
        - crm_cust_info
        - crm_prd_info
        - crm_sales_details

    ERP:
        - erp_cust_az12
        - erp_loc_a101
        - erp_px_cat_g1v2

WARNING:
    This script truncates existing Bronze table data before loading.
    All existing records in these tables will be deleted.

===============================================================================
*/


/*
===============================================================================
STEP 1: CREATE STORED PROCEDURE
===============================================================================
Purpose:
    Create a stored procedure named load_bronze.

    This procedure truncates all existing Bronze tables before
    loading fresh data from the source CSV files.
===============================================================================
*/

-- Change delimiter to allow procedure creation
DELIMITER //

-- Drop the procedure if it already exists
DROP PROCEDURE IF EXISTS bronze.load_bronze //

-- Create the Bronze loading procedure
  
CREATE PROCEDURE bronze.load_bronze()
BEGIN

    -- Declare variables to track execution time
    DECLARE start_time DATETIME;
    DECLARE end_time DATETIME;
    DECLARE batch_start_time DATETIME;
    DECLARE batch_end_time DATETIME;

    -- Capture the starting time of the batch
    SET batch_start_time = NOW();

    -- Display the start message
    SELECT '================================';
    SELECT 'STARTING BRONZE LAYER REFRESH';
    SELECT '================================';

    -- Capture the start time of the truncation process
    SET start_time = NOW();

    -- Truncate all existing Bronze tables
    TRUNCATE TABLE bronze.crm_cust_info;
    TRUNCATE TABLE bronze.crm_prd_info;
    TRUNCATE TABLE bronze.crm_sales_details;
    TRUNCATE TABLE bronze.erp_cust_az12;
    TRUNCATE TABLE bronze.erp_loc_a101;
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    -- Capture the end time of the truncation process
    SET end_time = NOW();

    -- Display the time taken to truncate all Bronze tables
    SELECT CONCAT(
        'All Bronze tables truncated in ',
        TIMESTAMPDIFF(SECOND, start_time, end_time),
        ' seconds'
    ) AS truncation_status;

    -- Capture the batch completion time
    SET batch_end_time = NOW();

    -- Display batch execution details
    SELECT
        batch_start_time AS start_time,
        batch_end_time AS end_time,
        TIMESTAMPDIFF(
            SECOND,
            batch_start_time,
            batch_end_time
        ) AS duration_seconds;

END //

-- Restore the default delimiter
DELIMITER ;


/*
===============================================================================
STEP 2: EXECUTE STORED PROCEDURE
===============================================================================
Purpose:
    Execute the stored procedure to truncate all Bronze tables
    before loading fresh data.
===============================================================================
*/

CALL bronze.load_bronze();


/*
===============================================================================
STEP 3: LOAD CRM DATA INTO BRONZE TABLES
===============================================================================
Purpose:
    Import raw data from CRM CSV files into the respective
    Bronze layer tables.
===============================================================================
*/


-- ---------------------------------------------------------------------------
-- 3.1 LOAD CUSTOMER INFORMATION
-- Source: cust_info.csv
-- Target: bronze.crm_cust_info
-- ---------------------------------------------------------------------------

LOAD DATA LOCAL INFILE 'C:/Users/adars/Desktop/project/cust_info.csv'
INTO TABLE bronze.crm_cust_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    @cst_create_date
)
SET cst_create_date =
    STR_TO_DATE(
        NULLIF(@cst_create_date, ''),
        '%d-%m-%Y'
    );


-- ---------------------------------------------------------------------------
-- 3.2 LOAD PRODUCT INFORMATION
-- Source: prd_info.csv
-- Target: bronze.crm_prd_info
-- ---------------------------------------------------------------------------

LOAD DATA LOCAL INFILE 'C:/Users/adars/Desktop/project/prd_info.csv'
INTO TABLE bronze.crm_prd_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    prd_id,
    prd_key,
    prd_nm,
    @prd_cost,
    prd_line,
    prd_start_dt,
    @prd_end_dt
)
SET
    prd_cost = NULLIF(@prd_cost, ''),
    prd_end_dt = NULLIF(@prd_end_dt, '');


-- ---------------------------------------------------------------------------
-- 3.3 LOAD SALES DETAILS
-- Source: sales_details.csv
-- Target: bronze.crm_sales_details
-- ---------------------------------------------------------------------------

LOAD DATA LOCAL INFILE 'C:/Users/adars/Desktop/project/sales_details.csv'
INTO TABLE bronze.crm_sales_details
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    @sls_order_dt,
    @sls_ship_dt,
    @sls_due_dt,
    @sls_sales,
    @sls_quantity,
    @sls_price
)
SET
    sls_order_dt = NULLIF(@sls_order_dt, ''),
    sls_ship_dt = STR_TO_DATE(
        NULLIF(NULLIF(@sls_ship_dt, ''), '0'),
        '%Y%m%d'
    ),
    sls_due_dt = STR_TO_DATE(
        NULLIF(NULLIF(@sls_due_dt, ''), '0'),
        '%Y%m%d'
    ),
    sls_sales = NULLIF(@sls_sales, ''),
    sls_quantity = NULLIF(@sls_quantity, ''),
    sls_price = NULLIF(@sls_price, '');


/*
===============================================================================
STEP 4: LOAD ERP DATA INTO BRONZE TABLES
===============================================================================
Purpose:
    Import raw data from ERP CSV files into the respective
    Bronze layer tables.
===============================================================================
*/


-- ---------------------------------------------------------------------------
-- 4.1 LOAD ERP CUSTOMER INFORMATION
-- Source: CUST_AZ12.csv
-- Target: bronze.erp_cust_az12
-- ---------------------------------------------------------------------------

LOAD DATA LOCAL INFILE 'C:/Users/adars/Desktop/project/source_erp/CUST_AZ12.csv'
INTO TABLE bronze.erp_cust_az12
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    cid,
    @bdate,
    gen
)
SET bdate =
    STR_TO_DATE(
        NULLIF(@bdate, ''),
        '%Y-%m-%d'
    );


-- ---------------------------------------------------------------------------
-- 4.2 LOAD ERP LOCATION INFORMATION
-- Source: LOC_A101.csv
-- Target: bronze.erp_loc_a101
-- ---------------------------------------------------------------------------

LOAD DATA LOCAL INFILE 'C:/Users/adars/Desktop/project/source_erp/LOC_A101.csv'
INTO TABLE bronze.erp_loc_a101
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    cid,
    cntry
);


-- ---------------------------------------------------------------------------
-- 4.3 LOAD ERP PRODUCT CATEGORY INFORMATION
-- Source: PX_CAT_G1V2.csv
-- Target: bronze.erp_px_cat_g1v2
-- ---------------------------------------------------------------------------

LOAD DATA LOCAL INFILE 'C:/Users/adars/Desktop/project/source_erp/PX_CAT_G1V2.csv'
INTO TABLE bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    id,
    cat,
    subcat,
    maintenance
);


/*
===============================================================================
STEP 5: DATA VALIDATION
===============================================================================
Purpose:
    Verify whether data has been successfully loaded into
    all six Bronze layer tables.

    COUNT(*) returns the total number of records in each table.
===============================================================================
*/

SELECT
    'crm_cust_info' AS table_name,
    COUNT(*) AS total_rows
FROM bronze.crm_cust_info

UNION ALL

SELECT
    'crm_prd_info',
    COUNT(*)
FROM bronze.crm_prd_info

UNION ALL

SELECT
    'crm_sales_details',
    COUNT(*)
FROM bronze.crm_sales_details

UNION ALL

SELECT
    'erp_cust_az12',
    COUNT(*)
FROM bronze.erp_cust_az12

UNION ALL

SELECT
    'erp_loc_a101',
    COUNT(*)
FROM bronze.erp_loc_a101

UNION ALL

SELECT
    'erp_px_cat_g1v2',
    COUNT(*)
FROM bronze.erp_px_cat_g1v2;


/*
===============================================================================
END OF BRONZE LAYER DATA LOADING SCRIPT
===============================================================================
*/
