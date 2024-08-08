CREATE DATABASE USRegionalSales;
USE USRegionalSales;
SELECT * FROM SalesData;

-- Alter Column Type to DATE

ALTER TABLE SalesData
MODIFY COLUMN ProcuredDate DATE;

ALTER TABLE SalesData
MODIFY COLUMN OrderDate DATE;

ALTER TABLE SalesData
MODIFY COLUMN ShipDate DATE;

ALTER TABLE SalesData
MODIFY COLUMN DeliveryDate DATE;

-- Fix Imported ProcuredDate

UPDATE SalesData
SET ProcuredDate = CONCAT(
    '20', -- Year portion (first two digits)
    SUBSTRING(ProcuredDate, 9, 2), '-',  -- Year portion (last two digits)
    SUBSTRING(ProcuredDate, 6, 2), '-',  -- Month portion
    SUBSTRING(ProcuredDate, 3, 2)        -- Day portion
);

-- Fix Imported OrderDate

UPDATE SalesData
SET OrderDate = CONCAT(
    '20',
    SUBSTRING(OrderDate, 9, 2), '-', 
    SUBSTRING(OrderDate, 6, 2), '-', 
    SUBSTRING(OrderDate, 3, 2)
);

-- Fix Imported ShipDate

UPDATE SalesData
SET ShipDate = CONCAT(
    '20',
    SUBSTRING(ShipDate, 9, 2), '-', 
    SUBSTRING(ShipDate, 6, 2), '-', 
    SUBSTRING(ShipDate, 3, 2)
);

-- Fix Imported DeliveryDate

UPDATE SalesData
SET DeliveryDate = CONCAT(
    '20',
    SUBSTRING(DeliveryDate, 9, 2), '-', 
    SUBSTRING(DeliveryDate, 6, 2), '-', 
    SUBSTRING(DeliveryDate, 3, 2)
);

-- Data Validation

SELECT *
FROM SalesData
WHERE OrderDate > DeliveryDate
;

-- Find Missing Values

SELECT *
FROM SalesData
WHERE OrderNumber IS NULL OR SalesChannel IS NULL
;

-- Find Duplicates

    SELECT OrderNumber
    FROM (SELECT OrderNumber, COUNT(*) 
          FROM SalesData
          GROUP BY OrderNumber 
          HAVING COUNT(*) > 1) AS duplicates
		  ;

-- Create Calculated Fields

ALTER TABLE SalesData
ADD COLUMN TotalRevenue DOUBLE,
ADD COLUMN TotalCost DOUBLE,
ADD COLUMN Profit DOUBLE,
ADD COLUMN DiscountedRevenue DOUBLE
;

UPDATE SalesData
SET TotalRevenue = ROUND(OrderQuantity * UnitPrice,2),
    TotalCost = ROUND(OrderQuantity * UnitCost,2),
    Profit = ROUND(TotalRevenue - TotalCost,2),
    DiscountedRevenue = ROUND(TotalRevenue - (TotalRevenue * DiscountApplied),2)
    ;
    
-- Revenue by Sales Channel

SELECT SalesChannel, ROUND(SUM(TotalRevenue),2) AS TotalRevenue, ROUND(SUM(Profit),2) AS TotalProfit
FROM SalesData
GROUP BY SalesChannel
;

-- Revenue and Profit by Sales Channel Over Time

SELECT EXTRACT(YEAR FROM OrderDate) AS Year, 
       SalesChannel, 
       ROUND(SUM(TotalRevenue), 2) AS TotalRevenue, 
       ROUND(SUM(Profit), 2) AS TotalProfit
FROM SalesData
GROUP BY Year, SalesChannel
ORDER BY Year, SalesChannel
;

-- Sales Trends by Month and Year

SELECT YEAR(OrderDate) AS Year, MONTH(OrderDate) AS Month, ROUND(SUM(TotalRevenue),2) AS MonthlyRevenue
FROM SalesData
GROUP BY Year, Month
ORDER BY Year, Month
;

-- Average Monthly Revenue

WITH MonthlyRevenue AS (
    SELECT
        EXTRACT(MONTH FROM OrderDate) AS Month,
        ROUND(SUM(TotalRevenue), 2) AS TotalMonthlyRevenue
    FROM SalesData
    GROUP BY Month
),

AverageMonthlyRevenue AS (
    SELECT
        Month,
        ROUND(AVG(TotalMonthlyRevenue), 2) AS AvgMonthlyRevenue
    FROM MonthlyRevenue
    GROUP BY Month
)

SELECT
    Month,
    AvgMonthlyRevenue
FROM AverageMonthlyRevenue
ORDER BY Month
;

-- Revenue and Order Trends by Weekday

SELECT DAYOFWEEK(OrderDate) AS Weekday, 
       ROUND(SUM(TotalRevenue), 2) AS TotalRevenue
FROM SalesData
GROUP BY Weekday
ORDER BY Weekday
;

-- Top 10 Customers by Revenue

SELECT _CustomerID, ROUND(SUM(TotalRevenue),2) AS CustomerRevenue
FROM SalesData
GROUP BY _CustomerID
ORDER BY CustomerRevenue DESC
LIMIT 10
;

-- Top 10 Products by Sales

SELECT _ProductID, ROUND(SUM(TotalRevenue),2) AS ProductSales
FROM SalesData
GROUP BY _ProductID
ORDER BY ProductSales DESC
LIMIT 10
;

-- Calculate Gross Profit for each Product 
-- Find the top 10 products by Gross Profit

SELECT _ProductID, 
       ROUND(SUM(TotalRevenue),2) AS TotalRevenue, 
       ROUND(SUM(TotalCost),2) AS TotalCost, 
       ROUND(SUM(TotalRevenue - TotalCost),2) AS GrossProfit
FROM SalesData
GROUP BY _ProductID
ORDER BY GrossProfit DESC
LIMIT 10
;


-- Calculate the number of orders and total revenue by year

WITH YearlyStats AS (
    SELECT
        YEAR(OrderDate) AS Year,
        COUNT(DISTINCT OrderNumber) AS TotalOrders,
        ROUND(SUM(TotalRevenue),2) AS TotalRevenue
    FROM SalesData
    GROUP BY YEAR(OrderDate)
),
-- Calculate percentage increases compared to the previous year
YearlyStatsWithIncreases AS (
    SELECT
        Year,
        TotalOrders,
        TotalRevenue,
        LAG(TotalOrders) OVER (ORDER BY Year) AS PreviousYearOrders,
        LAG(TotalRevenue) OVER (ORDER BY Year) AS PreviousYearRevenue
    FROM YearlyStats
)

SELECT
    Year,
    TotalOrders,
    TotalRevenue,
    CASE 
        WHEN PreviousYearOrders IS NULL THEN NULL 
        ELSE ROUND((TotalOrders - PreviousYearOrders) / PreviousYearOrders * 100, 2) 
    END AS OrdersPercentageIncrease,
    CASE 
        WHEN PreviousYearRevenue IS NULL THEN NULL 
        ELSE ROUND((TotalRevenue - PreviousYearRevenue) / PreviousYearRevenue * 100, 2) 
    END AS RevenuePercentageIncrease
FROM YearlyStatsWithIncreases
;


