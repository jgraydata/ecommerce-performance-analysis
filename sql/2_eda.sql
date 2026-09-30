-- EDA
/* Cancelled and returned orders retain positive order_amount and
profit_amount values in the source data. They are therefore
excluded from realised revenue and profit calculations to avoid
overstating commercial performance.*/
-- Overview of performance
SELECT
    COUNT(DISTINCT order_id) AS successful_orders,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT product_id) AS products,
    SUM(quantity) AS units_sold,

    ROUND(SUM(order_amount)::numeric, 2) AS realised_revenue,
    ROUND(SUM(profit_amount)::numeric, 2) AS realised_profit,

    ROUND(
        (
            SUM(order_amount)
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS avg_order_value,

    ROUND(
        (
            SUM(profit_amount)
            / NULLIF(SUM(order_amount), 0)
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_orders

WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE;

-- Total orders by status
SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE LOWER(order_status) = 'cancelled'
    ) AS cancelled_orders,

    COUNT(*) FILTER (
        WHERE returned = TRUE
          AND LOWER(order_status) <> 'cancelled'
    ) AS returned_orders,

    COUNT(*) FILTER (
        WHERE LOWER(order_status) <> 'cancelled'
          AND returned = FALSE
    ) AS successful_orders

FROM ecommerce_orders;

-- Annual performance
SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(order_amount)::numeric, 2) AS revenue,
    ROUND(SUM(profit_amount)::numeric, 2) AS profit
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year;

-- Monthly performance
SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(order_amount)::numeric, 2) AS revenue,
    ROUND(SUM(profit_amount)::numeric, 2) AS profit
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- Performance by product category
SELECT
    product_category,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(order_amount)::numeric, 2) AS revenue,
    ROUND(SUM(profit_amount)::numeric, 2) AS profit,
    ROUND(
        (
            SUM(profit_amount)
            / NULLIF(SUM(order_amount), 0)
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE
GROUP BY product_category
ORDER BY revenue DESC;

-- Performance by product subcategory
SELECT
    product_category,
    product_subcategory,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(order_amount)::numeric, 2) AS revenue,
    ROUND(SUM(profit_amount)::numeric, 2) AS profit,
    ROUND(
        (
            SUM(profit_amount)
            / NULLIF(SUM(order_amount), 0)
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE
GROUP BY
    product_category,
    product_subcategory
ORDER BY revenue DESC;

-- Performance by customer segment
SELECT
    customer_segment,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(order_amount)::numeric, 2) AS revenue,
    ROUND(
        (
            SUM(order_amount)
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS avg_order_value,
    ROUND(SUM(profit_amount)::numeric, 2) AS profit
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE
GROUP BY customer_segment
ORDER BY revenue DESC;

-- Performance by membership status
SELECT
    membership_status,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(order_amount)::numeric, 2) AS revenue,
    ROUND(
        (
            SUM(order_amount)
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS avg_order_value,
    ROUND(SUM(profit_amount)::numeric, 2) AS profit
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE
GROUP BY membership_status
ORDER BY revenue DESC;

-- Performance by traffic source
SELECT
    traffic_source,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(order_amount)::numeric, 2) AS revenue,
    ROUND(
        (
            SUM(order_amount)
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS avg_order_value,
    ROUND(SUM(profit_amount)::numeric, 2) AS profit
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE
GROUP BY traffic_source
ORDER BY revenue DESC;

-- Return rate by product category
SELECT
    product_category,

    COUNT(*) FILTER (
        WHERE LOWER(order_status) <> 'cancelled'
    ) AS eligible_orders,

    COUNT(*) FILTER (
        WHERE returned = TRUE
          AND LOWER(order_status) <> 'cancelled'
    ) AS returned_orders,

    ROUND(
        (
            100.0
            * COUNT(*) FILTER (
                WHERE returned = TRUE
                  AND LOWER(order_status) <> 'cancelled'
            )
            / NULLIF(
                COUNT(*) FILTER (
                    WHERE LOWER(order_status) <> 'cancelled'
                ),
                0
            )
        ),
        2
    ) AS return_rate_pct

FROM ecommerce_orders
GROUP BY product_category
ORDER BY return_rate_pct DESC;

-- Delivery performance by shipping method
SELECT
    shipping_method,
    COUNT(*) AS orders,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(shipping_cost)::numeric, 2) AS avg_shipping_cost,
    ROUND(AVG(review_rating)::numeric, 2) AS avg_review_rating
FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
GROUP BY shipping_method
ORDER BY avg_delivery_days;

-- Profitability by discount band
SELECT
    CASE
        WHEN discount_percent = 0 THEN 'No Discount'
        WHEN discount_percent <= 10 THEN '1-10%'
        WHEN discount_percent <= 20 THEN '11-20%'
        WHEN discount_percent <= 30 THEN '21-30%'
        ELSE '30%+'
    END AS discount_band,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        (
            SUM(order_amount)
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS avg_order_value,

    ROUND(SUM(order_amount)::numeric, 2) AS revenue,

    ROUND(SUM(profit_amount)::numeric, 2) AS profit,

    ROUND(
        (
            SUM(profit_amount)
            / NULLIF(SUM(order_amount), 0)
            * 100
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_orders
WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE

GROUP BY
    CASE
        WHEN discount_percent = 0 THEN 'No Discount'
        WHEN discount_percent <= 10 THEN '1-10%'
        WHEN discount_percent <= 20 THEN '11-20%'
        WHEN discount_percent <= 30 THEN '21-30%'
        ELSE '30%+'
    END

ORDER BY MIN(discount_percent);

-- Overall order outcomes
SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE LOWER(order_status) = 'cancelled'
    ) AS cancelled_orders,

    COUNT(*) FILTER (
        WHERE returned = TRUE
          AND LOWER(order_status) <> 'cancelled'
    ) AS returned_orders,

    COUNT(*) FILTER (
        WHERE returned = FALSE
          AND LOWER(order_status) <> 'cancelled'
    ) AS successful_orders

FROM ecommerce_orders;

-- Overall return rate
SELECT
    ROUND(
        (
            100.0
            * COUNT(*) FILTER (
                WHERE returned = TRUE
                  AND LOWER(order_status) <> 'cancelled'
            )
            / NULLIF(
                COUNT(*) FILTER (
                    WHERE LOWER(order_status) <> 'cancelled'
                ),
                0
            )
        ),
        2
    ) AS return_rate_pct
FROM ecommerce_orders;

-- Overall cancellation rate
SELECT
    ROUND(
        (
            100.0
            * COUNT(*) FILTER (
                WHERE LOWER(order_status) = 'cancelled'
            )
            / NULLIF(COUNT(*), 0)
        ),
        2
    ) AS cancellation_rate_pct
FROM ecommerce_orders;

-- Cancellation rate by product category
SELECT
    product_category,
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE LOWER(order_status) = 'cancelled'
    ) AS cancelled_orders,

    ROUND(
        (
            100.0
            * COUNT(*) FILTER (
                WHERE LOWER(order_status) = 'cancelled'
            )
            / NULLIF(COUNT(*), 0)
        ),
        2
    ) AS cancellation_rate_pct

FROM ecommerce_orders

GROUP BY product_category

ORDER BY cancellation_rate_pct DESC;

