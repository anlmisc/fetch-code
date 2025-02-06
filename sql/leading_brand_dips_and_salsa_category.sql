-- leading brand in the Dips & Salsa category

SELECT TOP 5 p.BRAND
, SUM(FINAL_SALE) total_sale
, SUM(FINAL_QUANTITY) total_quantity
, COUNT(DISTINCT t.USER_ID) number_of_users_that_purchased
, COUNT(DISTINCT t.BARCODE) number_of_unique_items
, RANK() OVER (ORDER BY SUM(FINAL_SALE) DESC) AS ranking_sale
, RANK() OVER (ORDER BY SUM(FINAL_QUANTITY) DESC) AS ranking_quantity
, RANK() OVER (ORDER BY COUNT(DISTINCT t.USER_ID) DESC) AS ranking_unique_users
, RANK() OVER (ORDER BY COUNT(DISTINCT t.BARCODE) DESC) AS ranking_quantity
FROM [Fetch Takehome].dbo.transaction_final t
JOIN [Fetch Takehome].dbo.products_final p -- JOIN works as we only want to look at products that "exist"
ON t.BARCODE = p.BARCODE
WHERE p.CATEGORY_2 = 'Dips & Salsa'
AND p.BRAND IS NOT NULL
GROUP BY p.BRAND
ORDER BY RANK() OVER (ORDER BY SUM(FINAL_SALE) DESC)