# Shopping Data Warehouse - Kimball Star Schema

## Overview

This project implements a **data warehouse** for a **shopping domain** using the **Kimball methodology**. The data warehouse follows the **star schema** approach, which is one of the core concepts in data warehousing. The purpose of the project is to analyze shopping data, answering business questions related to customer behavior, product ratings, and purchase frequency.

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

- `ID` (INT): Unique identifier (references `customer_id` in the fact table).
- `gender_type` (VARCHAR): Gender type (Male/Female).

### 3. `dim_category` (Dimension Table)

Stores information about product categories.

- `ID` (INT): Unique identifier (references `customer_id` in the fact table).
- `category` (VARCHAR): Product category (e.g., Clothing, Footwear).

### 4. `dim_season` (Dimension Table)

Stores information about the season during which a purchase occurred.

- `ID` (INT): Unique identifier (references `customer_id` in the fact table).
- `season` (VARCHAR): Season (e.g., Winter, Spring, Summer, Fall).

### 5. `dim_frequency` (Dimension Table)

Stores information about the frequency of purchases.

- `ID` (INT): Unique identifier (references `customer_id` in the fact table).
- `frequency_of_purchases` (VARCHAR): Frequency (e.g., Weekly, Monthly, Annually).

### 6. `fact_table` (Fact Table)

Stores transactional data, linking customer behavior to dimensions.

- `ID` (INT): Unique identifier (references `customer_id`).
- `age` (INT): Customer's age.
- `review_rating` (DECIMAL): Review rating for the product.
- `previous_purchases` (INT): Number of previous purchases by the customer.

## ETL Process

The ETL process involves the following steps:

1. Load raw data from an S3 bucket into the `shopping` table.
2. Insert transformed data into dimension tables (`dim_gender`, `dim_category`, `dim_season`, `dim_frequency`).
3. Insert relevant data into the fact table (`fact_table`).

## Business Questions

### 1. Product Categories with High Review Ratings

This query identifies **product categories** with an **average review rating** greater than the overall average review rating. It helps analyze which categories are receiving better feedback from customers.

```sql
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
```
### 2. Most Frequent Purchase Frequency Per Season
This query calculates the most frequent frequency of purchase for each season. It answers the business question of how frequently customers are purchasing products during different seasons.
```sql
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
        dim_frequency AS df ON df.ID = ft.ID
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
```
## Technologies Used

- **SQL**: For creating tables and running queries.
- **ETL Process**: Data is loaded from an S3 bucket into the warehouse.
- **Kimball Methodology**: For the data warehouse design using the star schema.

