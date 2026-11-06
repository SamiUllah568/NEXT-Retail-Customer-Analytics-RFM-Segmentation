
-- =====================================================
-- PROJECT: NEXT RETAIL SALES DATA CLEANING
-- DATABASE: next_retail
-- PURPOSE: Combine datasets and clean data
-- =====================================================


-- 1. CREATE TABLE 1: RAW DATA

CREATE TABLE next_1 (
    invoice      VARCHAR(20),
    stockcode    VARCHAR(20),
    description  VARCHAR(200),
    quantity     INTEGER,
    invoicedate  VARCHAR(50),
    price        NUMERIC(10,2),
    customer_id  INTEGER,
    country      VARCHAR(50)
);


-- 2. CREATE TABLE 2: SECOND DATASET

CREATE TABLE next_2 (
    invoice      VARCHAR(20),
    stockcode    VARCHAR(20),
    description  VARCHAR(200),
    quantity     INTEGER,
    invoicedate  VARCHAR(50),
    price        NUMERIC(10,2),
    customer_id  INTEGER,
    country      VARCHAR(50)
);


-- 3. COMBINE BOTH TABLES

CREATE TABLE nextdata AS
SELECT * FROM next_1

UNION ALL

SELECT * FROM next_2;


-- 4. CHECK TOTAL ROWS

SELECT COUNT(*) AS total_rows
FROM nextdata;


-- 5. COUNT EXTRA DUPLICATE ROWS

WITH duplicate_groups AS (
    SELECT COUNT(*) AS occurrences
    FROM nextdata
    GROUP BY
        invoice,
        stockcode,
        description,
        quantity,
        invoicedate,
        price,
        customer_id,
        country
    HAVING COUNT(*) > 1
)
SELECT SUM(occurrences - 1)
       AS total_duplicate_rows
FROM duplicate_groups;


-- 6. CREATE CLEAN TABLE WITHOUT EXACT DUPLICATES

CREATE TABLE nextdata_clean_1 AS
SELECT DISTINCT
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country
FROM nextdata;


-- 7. VALIDATE CLEANED DATA

SELECT COUNT(*) AS cleaned_total_rows
FROM nextdata_clean_1;


-- 8. CHECK WHETHER DUPLICATES REMAIN

SELECT
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country,
    COUNT(*) AS occurrences
FROM nextdata_clean_1
GROUP BY
    invoice,
    stockcode,
    description,
    quantity,
    invoicedate,
    price,
    customer_id,
    country
HAVING COUNT(*) > 1;


-- 9. VIEW CLEANED DATA

SELECT *
FROM nextdata_clean_1
LIMIT 100;


-- 10 CHECK NULL VALUES IN EACH COLUMN

SELECT
    COUNT(*) FILTER (WHERE invoice IS NULL)     AS invoice_null,
    COUNT(*) FILTER (WHERE stockcode IS NULL)    AS stockcode_null,
    COUNT(*) FILTER (WHERE description IS NULL)  AS description_null,
    COUNT(*) FILTER (WHERE quantity IS NULL)     AS quantity_null,
    COUNT(*) FILTER (WHERE invoicedate IS NULL)  AS invoicedate_null,
    COUNT(*) FILTER (WHERE price IS NULL)        AS price_null,
    COUNT(*) FILTER (WHERE customer_id IS NULL)  AS customer_id_null,
    COUNT(*) FILTER (WHERE country IS NULL)      AS country_null
FROM nextdata_clean_1;


-- 11 REMOVE ROWS WITH MISSING CUSTOMER IDs

CREATE TABLE nextdata_clean_2 AS
SELECT *
FROM nextdata_clean_1
WHERE customer_id IS NOT NULL;



-- 12 CHECK NULL VALUES IN EACH COLUMN AFTER DROP NULL

SELECT
    COUNT(*) FILTER (WHERE invoice IS NULL)     AS invoice_null,
    COUNT(*) FILTER (WHERE stockcode IS NULL)    AS stockcode_null,
    COUNT(*) FILTER (WHERE description IS NULL)  AS description_null,
    COUNT(*) FILTER (WHERE quantity IS NULL)     AS quantity_null,
    COUNT(*) FILTER (WHERE invoicedate IS NULL)  AS invoicedate_null,
    COUNT(*) FILTER (WHERE price IS NULL)        AS price_null,
    COUNT(*) FILTER (WHERE customer_id IS NULL)  AS customer_id_null,
    COUNT(*) FILTER (WHERE country IS NULL)      AS country_null
FROM nextdata_clean_2;


-- 13. Count rows where quantity is less than zero

SELECT COUNT(*) AS negative_quantity_rows
FROM nextdata_clean_2
WHERE quantity < 0;


-- 14. Remove rows where quantity is less than or equal to zero
CREATE TABLE nextdata_clean_3 AS
SELECT *
FROM nextdata_clean_2
WHERE quantity > 0;


-- STEP 15: Remove unwanted spaces from descriptions

UPDATE nextdata_clean_3
SET description = TRIM(description);


-- STEP 16: Convert invoicedate from VARCHAR to TIMESTAMP

ALTER TABLE nextdata_clean_3
ALTER COLUMN invoicedate TYPE TIMESTAMP
USING TO_TIMESTAMP(invoicedate, 'DD-MM-YYYY HH24:MI');

SELECT * FROM nextdata_clean_3;




-- Step 1. Total rows before cleaning
SELECT COUNT(*) AS total_rows_before_cleaning
FROM nextdata;

-- Step 2. Total rows after removing duplicates
SELECT COUNT(*) AS total_rows_after_removing_duplicates
FROM nextdata_clean_1;

-- Step 3. Total rows after removing NULL customer IDs
SELECT COUNT(*) AS total_rows_after_removing_nulls
FROM nextdata_clean_2;

-- STEP 4: Count rows after removing zero and negative quantities

SELECT COUNT(*) AS total_rows_after_removing_nonpositive_quantities
FROM nextdata_clean_3;






--BUSSINESS ANALYSIS

-- 1. Total unique customers
SELECT COUNT(DISTINCT customer_id) AS total_unique_customers
FROM nextdata_clean_3;

-- 2. TOTAL REVENUE

SELECT ROUND(SUM(quantity * price), 2) AS total_revenue
FROM nextdata_clean_3;

-- 3. Total quantity sold

SELECT SUM(quantity) AS total_quantity_sold
FROM nextdata_clean_3;

--4 Most common quantities per transaction line

SELECT
    quantity,
    COUNT(*) AS transaction_line_count
FROM nextdata_clean_3
GROUP BY quantity
ORDER BY transaction_line_count DESC;

--5. UNIQUE STOCKCODE

SELECT COUNT(DISTINCT stockcode) AS unique_stock_codes
FROM nextdata_clean_3;

-- 6. REVENUE BY YEAR

SELECT
    EXTRACT(YEAR FROM invoicedate) AS sales_year,
    SUM(quantity * price) AS total_revenue_by_year
FROM nextdata_clean_3
GROUP BY EXTRACT(YEAR FROM invoicedate)
ORDER BY sales_year;

-- 7. REVENUE BY MONTHS

SELECT
    DATE_TRUNC('month', invoicedate)::DATE AS sales_month,
    ROUND(SUM(quantity * price), 2) AS monthly_revenue
FROM nextdata_clean_3
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY sales_month;

-- 8. COUNTRY WISE SALE

SELECT
    country,
    ROUND(SUM(quantity * price), 2) AS total_revenue
FROM nextdata_clean_3
GROUP BY country
ORDER BY total_revenue DESC;



-- UPDATE TABLE APPLY BASIC CLEANING ON DESCRIPTION

UPDATE nextdata_clean_3
SET description =
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            TRIM(description),
            '\s+',
            ' ',
            'g'
        ),
        '[+-]',
        ' ',
        'g'
    );


-- 9. Top 10 products by revenue

SELECT
    stockcode,
    description,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(quantity * price), 2) AS total_revenue
FROM nextdata_clean_3
GROUP BY stockcode, description
ORDER BY total_revenue DESC
LIMIT 10;


-- 10. Top 10 customers by revenue

SELECT
    customer_id,
    ROUND(SUM(quantity * price), 2) AS total_revenue,
    SUM(quantity) AS total_quantity
FROM nextdata_clean_3
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;


-- 10. BOTTOM 10 CUSTOMERS BY REVENUE

SELECT
    customer_id,
    ROUND(SUM(quantity * price), 2) AS total_revenue,
    SUM(quantity) AS total_quantity
FROM nextdata_clean_3
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY total_revenue ASC
LIMIT 10;

--===============
-- Investigate customers with zero revenue
--===============

SELECT *
FROM nextdata_clean_3
WHERE customer_id IN (14103, 14827, 13256)
  AND price = 0;

-- STEP 11: Identify Test Products

SELECT *
FROM nextdata_clean_3
WHERE stockcode ILIKE 'TEST%'
  AND description ILIKE '%test product%';

-- STEP 11: Create a new table without test products

CREATE TABLE nextdata_analysis AS
SELECT *
FROM nextdata_clean_3
WHERE stockcode NOT ILIKE 'TEST%'
  AND description NOT ILIKE '%test product%';

-- Verify that no test products remain

SELECT *
FROM nextdata_analysis
WHERE stockcode ILIKE 'TEST%'
   OR description ILIKE '%test product%';


-- STEP 12: Identify Zero-Priced Transactions for Data Quality Review

SELECT *
FROM nextdata_analysis
WHERE price = 0;


-- STEP 13: Summarize Zero-Priced Transactions

SELECT
    COUNT(*) AS zero_price_rows,
    SUM(quantity) AS total_quantity
FROM nextdata_analysis
WHERE price = 0;

-- FINAL VALIDATION: Check the Analysis Dataset

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT invoice) AS total_invoices,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT stockcode) AS unique_products,
    ROUND(SUM(quantity * price), 2) AS total_revenue,
    SUM(quantity) AS total_quantity_sold
FROM nextdata_analysis;

SELECT * FROM nextdata_analysis;


SELECT MAX(invoicedate)::date + 1 AS ref_date FROM nextdata_analysis;


-- =====================================================
-- SECTION 15: CUSTOMER RFM ANALYSIS
-- Purpose: Calculate Recency, Frequency, and Monetary value per customer.
-- =====================================================

-- Lower recency means a more recent purchase.
-- Higher frequency and monetary values generally indicate greater engagement.

CREATE TABLE customer_rfm AS
SELECT
customer_id,
MAX(country) AS country,
('2011-12-10'::DATE - MAX(invoicedate)::DATE) AS recency,
COUNT(DISTINCT invoice) AS frequency,
SUM(quantity * price) AS monetary
FROM nextdata_analysis
GROUP BY customer_id;

-- =====================================================
-- ASSIGN RFM SCORES
-- Purpose: Divide customers into five relative scoring groups.
-- =====================================================

CREATE TABLE customer_rfm_score AS
SELECT *,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,

    CASE
        WHEN frequency = 1  THEN 1
        WHEN frequency = 2  THEN 2
        WHEN frequency <= 4 THEN 3
        WHEN frequency <= 9 THEN 4
        ELSE 5
    END AS f_score,

    NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM customer_rfm;

-- =====================================================
-- CUSTOMER SEGMENTATION
-- Purpose: Assign customer groups based on RFM scores.
-- =====================================================

CREATE TABLE customer_segments AS
SELECT
*,
CASE
WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
THEN 'Champions'

    WHEN r_score >= 4 AND f_score = 1
        THEN 'New'

    WHEN r_score <= 2 AND f_score >= 3
        THEN 'At Risk'

    WHEN r_score <= 2 AND f_score <= 2
        THEN 'Lost'
		
    WHEN r_score >= 3 AND f_score >= 3
        THEN 'Loyal'
		
    ELSE 'Needs Attention'
END AS customer_segment,
-- Label customers whose last purchase was more than 90 days ago.
CASE
    WHEN recency > 90 THEN 'Churned'
    ELSE 'Active'
END AS churn_flag
FROM customer_rfm_score;

-- =====================================================
-- END OF PROJECT
-- =====================================================