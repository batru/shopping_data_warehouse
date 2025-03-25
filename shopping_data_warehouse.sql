CREATE TABLE shopping (
    customer_id INT PRIMARY KEY,
    age INT,
    gender VARCHAR(10),
    category VARCHAR(50),
    location VARCHAR(50),
    season VARCHAR(20),
    review_rating DECIMAL(3,1),
    subscription_status VARCHAR(10),
    payment_method VARCHAR(20),
    shipping_type VARCHAR(20),
    discount_applied VARCHAR(3),
    promo_code_used VARCHAR(3),
    previous_purchases INT,
    preferred_payment_method VARCHAR(20),
    frequency_of_purchases VARCHAR(20)
);

-- Load from s3 to our table shopping
COPY dev.public.shopping FROM 's3url' IAM_ROLE 'iam_role url' FORMAT AS CSV DELIMITER ',' QUOTE '"' IGNOREHEADER 1 REGION AS 'your-s3-region'
-- Replace dev with your db, s3url with your s3url, iam_role url with your iam_role url and region with your s3 region

SELECT * FROM shopping;

-- create a dimension TABLE
CREATE TABLE dim_gender (ID INT PRIMARY KEY , gender_type VARCHAR(50));

-- insert data into the dimension TABLE
INSERT INTO dim_gender (ID, gender_type)
SELECT customer_id, gender FROM shopping;

-- select data from dimension TABLE
SELECT * FROM dim_gender;

-- create a fact TABLE
CREATE TABLE fact_table (ID INT PRIMARY KEY, age INT , review_rating DECIMAL(3,1), previous_purchases INT);

-- insert data into the fact TABLE
INSERT INTO fact_table (ID, age, review_rating, previous_purchases)
SELECT customer_id, age, review_rating, previous_purchases FROM shopping;

-- select data from fact TABLE
SELECT * FROM fact_table;


-- Business question
-- product category with high review rating 
-- Threshold is above avreage review rating

-- create a dimension category TABLE
CREATE TABLE dim_category (ID INT PRIMARY KEY, category VARCHAR(50));

-- insert data into the TABLE
INSERT INTO dim_category (ID, category)
SELECT customer_id, category FROM shopping;

-- select data from TABLE
SELECT * FROM dim_category;

-- join the tables
SELECT 
    dc.category, 
    AVG(ft.review_rating) AS avg_review_rating
FROM 
    fact_table ft
JOIN 
    dim_category dc ON dc.ID = ft.ID
GROUP BY 
    dc.category
HAVING 
    AVG(ft.review_rating) > (SELECT AVG(review_rating) FROM fact_table)
ORDER BY 
    avg_review_rating DESC;


    -- Business question 2


-- what is the most frequecy of purchase per each season

-- create a dimension Season TABLE
CREATE TABLE dim_season (ID INT PRIMARY KEY, season VARCHAR(50));

-- insert data into the TABLE
INSERT INTO dim_season (ID, season)
SELECT customer_id, season FROM shopping;

select * from dim_season;

-- create a dimension frequency of purchase TABLE
CREATE TABLE dim_frequency (ID INT PRIMARY KEY, frequency_of_purchases VARCHAR(20));

-- insert data into the TABLE
INSERT INTO dim_frequency (ID, frequency_of_purchases)
SELECT customer_id, frequency_of_purchases  FROM shopping;

-- step 1: Join the Fact Table with the Time Dimension and the Frequency of Purchases Dimension
SELECT 
    ds.season, 
    df.frequency_of_purchases, 
    COUNT(df.frequency_of_purchases) AS frequency_count
FROM 
    fact_table ft
JOIN 
    dim_season ds ON ft.id = ds.ID  
    
JOIN 
    dim_frequency df ON ft.id = df.ID  
GROUP BY 
    ds.season, df.frequency_of_purchases
ORDER BY 
    ds.season, frequency_count DESC;

-- step 2: Rank the result and get only the most frequency of purchase by each season
WITH ranked_frequencies AS (
    SELECT 
        ds.season,
        df.frequency_of_purchases, 
        COUNT(df.frequency_of_purchases) AS frequency_count,
        RANK() OVER (PARTITION BY ds.season ORDER BY COUNT(df.frequency_of_purchases) DESC) AS rank
    FROM 
        fact_table AS ft 
    JOIN 
        dim_season AS ds ON ds.ID = ft.ID
    JOIN
        dim_frequency AS df on df.ID = ft.ID
    GROUP BY 
        ds.season, df.frequency_of_purchases
)

SELECT 
    season, 
    frequency_of_purchases, 
    frequency_count
FROM 
    ranked_frequencies
WHERE 
    rank = 1
ORDER BY 
    season;
