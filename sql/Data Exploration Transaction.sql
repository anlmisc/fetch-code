-- View data to make sure import was correctly executed
SELECT TOP 10 *
FROM [Fetch Takehome].dbo.[transaction]

-- Check how many records and unique receipt_id and barcode there are
SELECT COUNT(*) number_of_records
, COUNT(DISTINCT CONCAT(RECEIPT_ID, ' | ', CAST(BARCODE AS BIGINT))) number_of_unqiue_receipt_user_barcode
FROM [Fetch Takehome].dbo.[transaction]
WHERE BARCODE <> '' -- included in case there was an empty cell not classified as NULL
AND BARCODE IS NOT NULL -- certain SQL dialects exclude NULL when using DISTINCT so added just to be safe

-- Looking at all records that have a partial quantity (decimal)
SELECT *
FROM [Fetch Takehome].dbo.products
WHERE BARCODE IN (SELECT DISTINCT BARCODE
				FROM [Fetch Takehome].dbo.[transaction]
				WHERE SUBSTRING(FINAL_QUANTITY, LEN(FINAL_QUANTITY)-1, 2) NOT IN ('00', 'ro'))

/*
Here we are converting the values of `zero` in FINAL_QUANTITY to 0. We are also CASTing it as a FLOAT and ROUNDing to get rid of the decimals.
I am making the assumption that you cannot have a partial unit of quantity. It could be the case where that represents something like weight.
for example if you are buying produce by the pound, but I am assuming that is not the case due to the previous query. That query shows all the
product info for the barcodes that have a decimal in their FINAL_QUANTITY. The ROUNDing is giving the benefit of the doubt to any numbers less 
than 1 and rounding them up, all other numbers are rounded normally.
*/
SELECT RECEIPT_ID, BARCODE, USER_ID, PURCHASE_DATE, SCAN_DATE, STORE_NAME
, CASE WHEN FINAL_QUANTITY = 'zero' THEN 0
	   WHEN CAST(FINAL_QUANTITY AS FLOAT) < 1 THEN CEILING(FINAL_QUANTITY)
	   ELSE ROUND(CAST(FINAL_QUANTITY AS FLOAT), 0) END AS FINAL_QUANTITY, FINAL_SALE

FROM [Fetch Takehome].dbo.[transaction]
WHERE BARCODE <> ''
AND BARCODE IS NOT NULL


/* FINAL QUERY TO FIX DATA ISSUES FOR PRODUCTS */
/*
The final fix is to group the records, but we will be taking the MAX value for FINAL_QUANTITY AND FINAL_SALE.
There are records that are identical but have differing FINAL_QUANTITY AND FINAL_SALE. This data appears to represent a receipt with its items.
There should not be multiple records for the same barcode within a receipt_id, that should be taken care of in the FINAL_QUANTITY field. We are taking the MAXIMUM as
we are making the assumption that if both numbers were recorded, perhaps the smaller number was pulled incorrectly as a "per unit price" or it could
have been something completely different. There are some fields that have a 0 for FINAL_SALE, but We actually do not want to exclude any records 
that satisfy this condition because they could be coupons (which we do not have data for), or something similar, that reduced the final amount to 0.
*/

WITH mydata AS (

SELECT RECEIPT_ID, BARCODE, USER_ID, PURCHASE_DATE, SCAN_DATE, STORE_NAME
, CASE WHEN FINAL_QUANTITY = 'zero' THEN 0
	   WHEN CAST(FINAL_QUANTITY AS FLOAT) < 1 THEN CEILING(FINAL_QUANTITY)
	   ELSE ROUND(CAST(FINAL_QUANTITY AS FLOAT), 0) END AS FINAL_QUANTITY, FINAL_SALE

FROM [Fetch Takehome].dbo.[transaction]
WHERE BARCODE <> ''
AND BARCODE IS NOT NULL

)

SELECT RECEIPT_ID, BARCODE, USER_ID, PURCHASE_DATE, SCAN_DATE, STORE_NAME, MAX(FINAL_QUANTITY) AS FINAL_QUANTITY, MAX(FINAL_SALE) AS FINAL_SALE
INTO [Fetch Takehome].dbo.[transaction_final]
FROM mydata
GROUP BY RECEIPT_ID, BARCODE, USER_ID, PURCHASE_DATE, SCAN_DATE, STORE_NAME


-- View final table and check uniqueness of composite key
SELECT TOP 10 *
FROM [Fetch Takehome].dbo.[transaction_final]

SELECT COUNT(*), COUNT(DISTINCT CONCAT(RECEIPT_ID, ' | ', CAST(BARCODE AS BIGINT)))
FROM [Fetch Takehome].dbo.[transaction_final]