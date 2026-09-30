-- Data Cleaning
-- Check size and date range of the ecommerce_orders table
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM
    ecommerce_orders;

-- Check for duplicate orders
SELECT
    order_id,
    COUNT(*) AS occurrences
FROM
    ecommerce_orders
GROUP BY
    order_id
HAVING
    COUNT(*) > 1
ORDER BY
    occurrences DESC,
    order_id;

-- Check for missing values and invalid data ranges
SELECT
    COUNT(*) FILTER (
        WHERE
            customer_id IS NULL
            OR order_date IS NULL
            OR product_id IS NULL
            OR order_amount IS NULL
    ) AS rows_missing_key_fields,
    COUNT(*) FILTER (
        WHERE
            quantity <= 0
            OR unit_price < 0
            OR order_amount < 0
            OR discount_amount < 0
            OR shipping_cost < 0
            OR tax_amount < 0
    ) AS rows_with_invalid_values,
    COUNT(*) FILTER (
        WHERE
            discount_percent NOT BETWEEN 0 AND 100
    ) AS invalid_discount_percent,
    COUNT(*) FILTER (
        WHERE
            review_rating NOT BETWEEN 0 AND 5
    ) AS invalid_review_rating
FROM
    ecommerce_orders;