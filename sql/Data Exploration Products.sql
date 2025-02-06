-- View data to make sure import was correctly executed
SELECT TOP 10 *
FROM [Fetch Takehome].dbo.products

-- Check how many records and unique barcodes there are
SELECT COUNT(*) number_of_records
, COUNT(DISTINCT BARCODE) number_of_unique_barcodes
FROM [Fetch Takehome].dbo.products
WHERE BARCODE <> '' -- included in case there was an empty cell not classified as NULL
AND BARCODE IS NOT NULL -- certain SQL dialects exclude NULL when using DISTINCT so added just to be safe

-- Check for barcodes that appear multiple times
SELECT BARCODE
FROM [Fetch Takehome].dbo.products
WHERE BARCODE <> ''
AND BARCODE IS NOT NULL
GROUP BY BARCODE
HAVING COUNT(*) > 1

-- looked at a barcode that was duplicated to realize the entire row appears to be duplicated
-- this will be resolved by grouping the data
SELECT *
FROM [Fetch Takehome].dbo.products
WHERE BARCODE = 4138891

-- checking for barcodes that are not fixed by grouping
WITH barcodes_grouped AS (

SELECT BARCODE
FROM [Fetch Takehome].dbo.products
WHERE BARCODE <> ''
AND BARCODE IS NOT NULL
GROUP BY CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4, MANUFACTURER, BRAND, BARCODE

)

SELECT BARCODE
FROM barcodes_grouped
GROUP BY BARCODE
HAVING COUNT(*) > 1

/* 
Looked at a barcode that was duplicated to realize parts of the row were the same and others were different.
This won't be resolved by grouping the data. There are only 27 barcodes that persist with duplication issues so
it may be worth it to manually correct those. However, for our purposes we will just select the record with the least
number of NULL columns. If the duplicate records have the same number of non-NULL columns, we will have it selected
based on the order it had in the provided datasets.
*/
SELECT *
FROM [Fetch Takehome].dbo.products
WHERE BARCODE = 3431207


/* FINAL QUERY TO FIX DATA ISSUES FOR PRODUCTS */
-- group the data to get barcode deduped and implement the fix on barcodes that won't be resolved simply by grouping

-- Create list of 27 barcodes that are not fixed by grouping
WITH difficult_barcodes AS (

SELECT BARCODE
FROM (SELECT CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4, MANUFACTURER, BRAND, BARCODE 
	  FROM [Fetch Takehome].dbo.products
	  WHERE BARCODE <> '' AND BARCODE IS NOT NULL
	  GROUP BY CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4, MANUFACTURER, BRAND, BARCODE) A
GROUP BY BARCODE
HAVING COUNT(*) > 1

)

-- Create a fix to only keep one record from barcodes that have multiple records that are not resolved by grouping
, duplicate_records_barcodes AS (

SELECT *
-- Calculation below provides a count for the number of columns that are not NULL. This is used to determine the order in the duplicate records.
, ROW_NUMBER() OVER (PARTITION BY BARCODE ORDER BY ((CASE WHEN MANUFACTURER IS NOT NULL THEN 1 ELSE 0 END) + 
													(CASE WHEN BRAND IS NOT NULL THEN 1 ELSE 0 END) +
													(CASE WHEN CATEGORY_1 IS NOT NULL THEN 1 ELSE 0 END) +
													(CASE WHEN CATEGORY_2 IS NOT NULL THEN 1 ELSE 0 END) +
													(CASE WHEN CATEGORY_3 IS NOT NULL THEN 1 ELSE 0 END) +
													(CASE WHEN CATEGORY_4 IS NOT NULL THEN 1 ELSE 0 END)
												   ) DESC
					) AS rn
FROM [Fetch Takehome].dbo.products
WHERE BARCODE IN (SELECT BARCODE FROM difficult_barcodes)

)

SELECT * INTO [Fetch Takehome].dbo.[products_final] FROM (

SELECT BARCODE, MANUFACTURER, BRAND, CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4
FROM duplicate_records_barcodes
WHERE rn = 1 -- We are selecting the record that has the least number of NULL columns. If they are equal it is keeping the record based on the order in the base dataset.

UNION ALL

-- We are UNIONing the rest of the barcodes that are fixed by grouping
SELECT BARCODE, MANUFACTURER, BRAND, CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4
FROM [Fetch Takehome].dbo.products
WHERE BARCODE <> '' 
AND BARCODE IS NOT NULL
AND BARCODE NOT IN (SELECT BARCODE FROM difficult_barcodes)
GROUP BY BARCODE, MANUFACTURER, BRAND, CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4
) A




-- View final table and check uniqueness of primary key
SELECT TOP 10 *
FROM [Fetch Takehome].dbo.[products_final]

SELECT COUNT(*), COUNT(DISTINCT BARCODE)
FROM [Fetch Takehome].dbo.[products_final]