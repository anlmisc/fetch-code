-- View data to make sure import was correctly executed
SELECT TOP 10 *
FROM [Fetch Takehome].dbo.[user]

-- Check how many records and unique barcodes there are
SELECT COUNT(*) number_of_records
, COUNT(DISTINCT ID) number_of_unique_barcodes
FROM [Fetch Takehome].dbo.[user]

/*
ID is unique as the primary key. No deduping is required here.
There are NULLs in the remaining fields but they are descriptive of the user and are not necessary.
Users with a NULL in a given field will simply be excluded from the analysis further along.
*/
SELECT * INTO [Fetch Takehome].dbo.[user_final]
FROM [Fetch Takehome].dbo.[user]

-- View final table and check uniqueness of primary key
SELECT TOP 10 *
FROM [Fetch Takehome].dbo.[user_final]

SELECT COUNT(*), COUNT(DISTINCT ID)
FROM [Fetch Takehome].dbo.[user_final]