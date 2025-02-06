
-- Top 5 brands by receipts scanned among users 21 and over
SELECT BRAND, ranking, brand_count FROM (

SELECT 
p.BRAND
, RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking -- use of rank rather than dense_rank to give a true ranking
, COUNT(*) brand_count
FROM [Fetch Takehome].dbo.transaction_final t
JOIN [Fetch Takehome].dbo.user_final u -- JOIN works as we only want to look at users who "exist"
ON t.USER_ID = u.ID
JOIN [Fetch Takehome].dbo.products_final p -- JOIN works as we only want to look at products that "exist"
ON t.BARCODE = p.BARCODE
AND BRAND IS NOT NULL

WHERE DATEDIFF(day, BIRTH_DATE, GETDATE()) / 365 >= 21 -- more accurate way of calculating age than simply getting the difference in years

GROUP BY p.BRAND
) A
WHERE ranking <= 5
