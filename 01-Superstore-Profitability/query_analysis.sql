USE superstore_analysis;

-- 1. DATA PREPROCESSING & DATA TYPE TRANSFORMATION
SET SQL_SAFE_UPDATES = 0;

UPDATE superstore_analysis.superstore_data 
SET `Order Date` = STR_TO_DATE(`Order Date`, '%m/%d/%Y');

UPDATE superstore_analysis.superstore_data 
SET `Ship Date` = STR_TO_DATE(`Ship Date`, '%m/%d/%Y');

-- 2. DATA CLEANING & QUALITY ASSURANCE
-- Check for duplicate records based on primary identifier
SELECT `Row ID`, COUNT(*) 
FROM superstore_analysis.superstore_data
GROUP BY `Row ID`
HAVING COUNT(*) > 1;

-- Validate logical date consistency (Shipping date should not precede order date)
SELECT COUNT(*) AS anomalous_shipping_dates
FROM superstore_analysis.superstore_data
WHERE `Ship Date` < `Order Date`;

-- Standardize text fields by trimming leading and trailing whitespaces
UPDATE superstore_analysis.superstore_data
SET 
    `Ship Mode` = TRIM(`Ship Mode`),
    `Segment` = TRIM(`Segment`),
    `Country` = TRIM(`Country`),
    `City` = TRIM(`City`),
    `State` = TRIM(`State`),
    `Category` = TRIM(`Category`),
    `Sub-Category` = TRIM(`Sub-Category`),
    `Product Name` = TRIM(`Product Name`);

-- 3. EXPLORATORY DATA ANALYSIS (EDA) & SAMPLE EXTRACTION
-- Sample extraction containing shipping duration calculation
SELECT 
    `Order ID`,
    `Order Date`,
    `Ship Date`,
    `Ship Mode`,
    `Sales`,
    `Profit`,
    DATEDIFF(`Ship Date`, `Order Date`) AS Shipping_Time_Days
FROM superstore_analysis.superstore_data
LIMIT 10;

-- Analyze aggregate volume and total financial impact of unprofitable transactions
SELECT 
    COUNT(*) AS unprofitable_transactions_count,
    ROUND(SUM(Sales), 2) AS total_unprofitable_sales,
    ROUND(SUM(Profit), 2) AS total_net_loss
FROM superstore_analysis.superstore_data
WHERE Profit < 0;

-- Evaluate correlation between discount thresholds and business status profitability
SELECT 
    Discount * 100 AS discount_percentage,
    COUNT(*) AS total_transactions,
    ROUND(AVG(Profit), 2) AS average_profit,
    CASE 
        WHEN AVG(Profit) < 0 THEN 'NET LOSS'
        ELSE 'PROFITABLE'
    END AS business_status
FROM superstore_analysis.superstore_data
GROUP BY Discount
ORDER BY Discount ASC;

-- Identify product taxonomy performance ordered by lowest profitability to locate profit leaks
SELECT 
    Category,
    `Sub-Category`,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(AVG(Discount) * 100, 1) AS average_discount_percentage
FROM superstore_analysis.superstore_data
GROUP BY Category, `Sub-Category`
ORDER BY total_profit ASC;
