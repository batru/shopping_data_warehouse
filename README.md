# Shopping Data Warehouse - Kimball Star Schema

## Overview

This project implements a **data warehouse** for a **shopping domain** using the **Kimball methodology**. The data warehouse follows the **star schema** approach, which is one of the core concepts in data warehousing. The purpose of the project is to analyze shopping data and answer business questions related to customer behavior, product ratings, and purchase frequency.

## Structure

The data warehouse consists of the following components:

1. **Fact Table**: Stores the transactional data for customers, including review ratings and purchase history.
2. **Dimension Tables**: Provide descriptive attributes for analysis, such as gender, season, frequency of purchases, and product categories.
3. **ETL Process**: Loads data from an external source (S3) into the data warehouse.
4. **Business Questions**: SQL queries designed to answer specific business questions based on the data.

## Tables

### 1. `shopping` (Raw Data Table)

This table stores the raw customer shopping data, which is imported from an S3 bucket.

- `customer_id` (INT): Unique identifier for the customer.
- `age` (INT): Customer's age.
- `gender` (VARCHAR): Customer's gender.
- `category` (VARCHAR): Product category.
- `location` (VARCHAR): Customer's location.
- `season` (VARCHAR): The season when the purchase occurred.
- `review_rating` (DECIMAL): Rating given by the customer for the product.
- `subscription_status` (VARCHAR): Subscription status of the customer.
- `payment_method` (VARCHAR): Payment method used for the purchase.
- `shipping_type` (VARCHAR): Type of shipping selected.
- `discount_applied` (VARCHAR): Indicates if a discount was applied.
- `promo_code_used` (VARCHAR): Indicates if a promo code was used.
- `previous_purchases` (INT): Number of previous purchases by the customer.
- `preferred_payment_method` (VARCHAR): Customer's preferred payment method.
- `frequency_of_purchases` (VARCHAR): Frequency at which the customer makes purchases.

### 2. `dim_gender` (Dimension Table)

Stores information about gender.

- `gender_id` (INT): Unique identifier (references `customer_id` in the fact table).
- `gender_type` (VARCHAR): Gender type (Male/Female).

### 3. `dim_category` (Dimension Table)

Stores information about product categories.

- `category_id` (INT): Unique identifier (references `category` in the fact table).
- `category_name` (VARCHAR): Product category (e.g., Clothing, Footwear).

### 4. `dim_season` (Dimension Table)

Stores information about the season during which a purchase occurred.

- `season_id` (INT): Unique identifier (references `season` in the fact table).
- `season_name` (VARCHAR): Season (e.g., Winter, Spring, Summer, Fall).

### 5. `dim_frequency` (Dimension Table)

Stores information about the frequency of purchases.

- `frequency_id` (INT): Unique identifier (references `frequency_of_purchases` in the fact table).
- `frequency_name` (VARCHAR): Frequency (e.g., Weekly, Monthly, Annually).

### 6. `fact_table` (Fact Table)

Stores transactional data, linking customer behavior to dimensions.

- `fact_id` (INT): Unique identifier for each transaction (references `customer_id`).
- `age` (INT): Customer's age.
- `review_rating` (DECIMAL): Review rating for the product.
- `previous_purchases` (INT): Number of previous purchases by the customer.
- `category_id` (INT): Foreign key to `dim_category`.
- `season_id` (INT): Foreign key to `dim_season`.
- `frequency_id` (INT): Foreign key to `dim_frequency`.

## ETL Process

The ETL process involves the following steps:

1. Load raw data from an S3 bucket into the `shopping` table.
2. Insert transformed data into dimension tables (`dim_gender`, `dim_category`, `dim_season`, `dim_frequency`).
3. Insert relevant data into the fact table (`fact_table`).

### Example ETL Query to Load Data:

```sql
COPY dev.public.shopping FROM 's3url' 
IAM_ROLE 'iam_role_url' 
FORMAT AS CSV DELIMITER ',' QUOTE '"' 
IGNOREHEADER 1 REGION 'your-s3-region';
```

## Business Questions

### 1. Product Categories with High Review Ratings

This query identifies **product categories** with an **MAX review rating**. It helps analyze which categories are receiving better feedback from customers.

```sql
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

```
### 2. Most Frequent Purchase Frequency Per Season
This query calculates the most frequent frequency of purchase for each season. It answers the business question of how frequently customers are purchasing products during different seasons.
```sql
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
```
## Technologies Used

- **SQL**: For creating tables and running queries.
- **ETL Process**: Data is loaded from an S3 bucket into the warehouse.
- **Kimball Methodology**: For the data warehouse design using the star schema.

