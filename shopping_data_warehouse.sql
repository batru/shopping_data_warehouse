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


-- create a dimension table gender
CREATE TABLE dim_gender (
    gender_id INT PRIMARY KEY,  -- A unique ID for the gender
    gender_type VARCHAR(50)     -- Gender type (e.g., Male, Female)
);

-- Insert data into dim_gender, automatically assigning IDs to gender types
INSERT INTO dim_gender (gender_id, gender_type)
SELECT 
    ROW_NUMBER() OVER (ORDER BY gender) AS gender_id,  -- Automatically generate gender_id
    gender AS gender_type                             -- Gender type (Male or Female)
FROM 
    (SELECT DISTINCT gender FROM shopping) AS distinct_genders;

-- Select the data from dim_gender to verify
SELECT * FROM dim_gender;

CREATE TABLE dim_category (
    category_id INT PRIMARY KEY,  -- Unique ID for each category
    category_name VARCHAR(50)     -- Product category (e.g., Clothing, Footwear)
);

INSERT INTO dim_category (category_id, category_name)
SELECT 
    ROW_NUMBER() OVER (ORDER BY category) AS category_id, 
    category AS category_name

FROM 
    (SELECT DISTINCT category FROM shopping) AS distinct_category;

-- Select the data from dim_category to verify
SELECT * FROM dim_category;

CREATE TABLE dim_season (
    season_id INT PRIMARY KEY,  -- Unique ID for each season
    season_name VARCHAR(20)     -- Season name (e.g., Winter, Spring)
);

INSERT INTO dim_season (season_id, season_name)
SELECT 
    ROW_NUMBER() OVER( ORDER BY season) AS season_id, 
    season AS season_name
FROM (SELECT DISTINCT season FROM shopping) AS season_category;

SELECT * FROM dim_season;

CREATE TABLE dim_frequency (
    frequency_id INT PRIMARY KEY,  -- Unique ID for each frequency
    frequency_name VARCHAR(20)     -- Frequency of purchases (e.g., Weekly, Monthly)
);

INSERT INTO dim_frequency (frequency_id, frequency_name)
SELECT 
    ROW_NUMBER() OVER( ORDER BY frequency_of_purchases) AS frequency_id, 
    frequency_of_purchases AS frequency_name
FROM (SELECT DISTINCT frequency_of_purchases FROM shopping) AS frequency_category;

SELECT * FROM dim_frequency;

-- Fact TABLE
CREATE TABLE fact_table (
    fact_id INT PRIMARY KEY,        -- Fact table ID (use an auto-incrementing ID)
    age INT,               
    review_rating DECIMAL(3,1),     -- Fact: Review rating for the purchase
    previous_purchases INT,         -- Fact: Total previous purchases by the customer
    category_id INT,                -- Foreign key to category
    season_id INT,                  -- Foreign key to season
    frequency_id INT,               -- Foreign key to frequency
    
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (season_id) REFERENCES dim_season(season_id),
    FOREIGN KEY (frequency_id) REFERENCES dim_frequency(frequency_id)
);

-- insert data into fact TABLE
INSERT INTO fact_table (fact_id, age, review_rating, previous_purchases, category_id, season_id, frequency_id)
SELECT 
    s.customer_id, 
    s.age,
    s.review_rating, 
    s.previous_purchases, 
    dc.category_id, 
    ds.season_id, 
    df.frequency_id
FROM 
    shopping s
JOIN 
    dim_category dc ON dc.category_name = s.category
JOIN 
    dim_season ds ON ds.season_name = s.season
JOIN 
    dim_frequency df ON df.frequency_name = s.frequency_of_purchases;

-- Business Queries
-- 1. Products with High Review Rating (Above Average)
-- Now, let's query products (categories) that have an average review rating above the overall average review rating.

SELECT 
    dc.category_name, 
    MAX(ft.review_rating) AS high_review_rating
FROM 
    fact_table ft
JOIN 
    dim_category dc ON dc.category_id = ft.category_id
GROUP BY 
    dc.category_name
ORDER BY 
    high_review_rating DESC;

-- 2. Most Frequent Frequency of Purchase Per Each Season
-- For this query, we'll find the most frequent frequency of purchase per each season.
WITH ranked_frequencies AS (
    SELECT 
        ds.season_name,
        df.frequency_name, 
        COUNT(df.frequency_name) AS frequency_count,
        RANK() OVER (PARTITION BY ds.season_name ORDER BY COUNT(df.frequency_name) DESC) AS rank
    FROM 
        fact_table ft
    JOIN 
        dim_season ds ON ds.season_id = ft.season_id
    JOIN 
        dim_frequency df ON df.frequency_id = ft.frequency_id
    GROUP BY 
        ds.season_name, df.frequency_name
)
SELECT 
    season_name, 
    frequency_name, 
    frequency_count
FROM 
    ranked_frequencies
WHERE 
    rank = 1
ORDER BY 
    season_name;



