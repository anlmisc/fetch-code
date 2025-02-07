import sqlalchemy
import pandas as pd
import os 
from dotenv import load_dotenv
import matplotlib.pyplot as plt

pd.set_option('display.max_columns',500)
pd.set_option('display.width', 500)
pd.set_option('display.max_rows', 250)
pd.set_option('display.max_colwidth', 100)

# Get the path to the directory for .env
fetch_dir = 'C:\\Program Files\\Git\\alec-lohr\\fetch\\fetch-code\\'

# Connect the path with your '.env' file name
load_dotenv(os.path.join(fetch_dir, '.env'))

# load variables
SQL_ENGINE = os.environ.get("SQL_ENGINE")

# Define engine to access database
engine = sqlalchemy.create_engine(SQL_ENGINE, legacy_schema_aliasing=False, fast_executemany=True)

# Pull in SQL results
brands_21_and_over = pd.read_sql(
            f"""
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
            """
                , engine)
            
brands_6_months = pd.read_sql(
            f"""
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
            """
                , engine)


# Define X and Y for bar chart
brands = brands_21_and_over.BRAND
count = brands_21_and_over.brand_count

# Define colors
colors = []
for value in count:
    if value == count.max():
        colors.append('forestgreen')
    else:
        colors.append('palegoldenrod')

# Create bar chart
plt.bar(brands, count, color=colors)
plt.xlabel('Brands')
plt.xticks(rotation=45)
plt.ylabel('Count')
plt.title('Top Brands for 21+ Users')
plt.show()



# Define X and Y for bar chart
brands = brands_6_months.BRAND
count = brands_6_months.total_sale

# Define colors
colors = []
for value in count:
    if value == count.max():
        colors.append('forestgreen')
    else:
        colors.append('palegoldenrod')

# Create bar chart
plt.bar(brands, count, color=colors)
plt.xlabel('Brands')
plt.xticks(rotation=45)
plt.ylabel('Count')
plt.title('Top Brands for Users with Accounts 6 months+ Old')
plt.show()


