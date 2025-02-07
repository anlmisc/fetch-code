-- Top 5 brands by sales among users with accounts for at least six months

SELECT BRAND, ranking, total_sale FROM (

SELECT 
p.BRAND
, RANK() OVER (ORDER BY SUM(FINAL_SALE) DESC) AS ranking -- use of rank rather than dense_rank to give a true ranking
, SUM(FINAL_SALE) total_sale
FROM [Fetch Takehome].dbo.transaction_final t
JOIN [Fetch Takehome].dbo.user_final u -- JOIN works as we only want to look at users who "exist"
ON t.USER_ID = u.ID
JOIN [Fetch Takehome].dbo.products_final p -- JOIN works as we only want to look at products that "exist"
ON t.BARCODE = p.BARCODE
AND BRAND IS NOT NULL

WHERE CASE WHEN DAY(u.CREATED_DATE) <= DAY(GETDATE()) 
		THEN DATEDIFF(month, u.CREATED_DATE, GETDATE())
		ELSE DATEDIFF(month, u.CREATED_DATE, GETDATE()) - 1 
		END >= 6 -- This is a more accurate way of calculating months than just taking the difference in months.
				 -- The logic is if the CREATED_DATE is on or before the date today, that date has hit the mark 
				 -- month and we can count that month. Otherwise we do not count the month.

GROUP BY p.BRAND
) A
WHERE ranking <= 5


