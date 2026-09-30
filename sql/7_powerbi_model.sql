-- Power BI Data Model
/* 
Model:
             dim_date
                │
                │ 1 : *
                ▼
           fact_orders
                ▲
                │ * : 1
                │
          dim_customer
*/

-- fact_orders
DROP VIEW IF EXISTS fact_orders CASCADE;

CREATE VIEW fact_orders AS

SELECT
    -- Keys
    order_id,
    order_date,

    -- Customer key
    customer_id,

    -- Order-time customer attributes
    customer_age,
    customer_gender,
    country,
    city,
    customer_segment,
    membership_status,
    customer_lifetime_value,

    -- Product attributes
    product_id,
    product_category,
    product_subcategory,
    brand,

    -- Sales measures
    unit_price,
    quantity,
    discount_percent,
    discount_amount,
    coupon_used,
    shipping_cost,
    tax_amount,
    order_amount,
    profit_amount,
    profit_margin_percent,

    -- Order attributes
    payment_method,
    device_type,
    traffic_source,
    shipping_method,
    warehouse_region,

    -- Operational attributes
    delivery_days,
    order_status,
    returned,
    review_rating,

    -- Existing business classifications
    holiday_season,
    high_value_order

FROM ecommerce_orders;

-- dim_date
DROP VIEW IF EXISTS dim_date CASCADE;

CREATE VIEW dim_date AS

WITH date_range AS (
    SELECT
        generate_series(
            MIN(order_date),
            MAX(order_date),
            INTERVAL '1 day'
        )::date AS date
    FROM ecommerce_orders
)

SELECT
    date,

    EXTRACT(YEAR FROM date)::int AS year,

    EXTRACT(QUARTER FROM date)::int AS quarter,

    'Q' || EXTRACT(QUARTER FROM date)::int
        AS quarter_name,

    EXTRACT(MONTH FROM date)::int AS month_number,

    TO_CHAR(date, 'Month') AS month_name,

    TO_CHAR(date, 'Mon') AS month_short_name,

    TO_CHAR(date, 'YYYY-MM') AS year_month,

    TO_CHAR(date, 'Mon YYYY') AS month_year,

    EXTRACT(DAY FROM date)::int AS day,

    EXTRACT(ISODOW FROM date)::int AS day_of_week_number,

    TO_CHAR(date, 'Day') AS day_of_week,

    CASE
        WHEN EXTRACT(ISODOW FROM date) IN (6, 7)
            THEN TRUE
        ELSE FALSE
    END AS is_weekend,

    CASE
        WHEN EXTRACT(MONTH FROM date) IN (12, 1, 2)
            THEN 'Winter'
        WHEN EXTRACT(MONTH FROM date) IN (3, 4, 5)
            THEN 'Spring'
        WHEN EXTRACT(MONTH FROM date) IN (6, 7, 8)
            THEN 'Summer'
        WHEN EXTRACT(MONTH FROM date) IN (9, 10, 11)
            THEN 'Autumn'
    END AS season

FROM date_range

ORDER BY date;

-- dim_customer
DROP VIEW IF EXISTS dim_customer CASCADE;

CREATE VIEW dim_customer AS

SELECT DISTINCT
    customer_id

FROM ecommerce_orders;


SELECT
    COUNT(*) AS dimension_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_customer_rows

FROM dim_customer;
