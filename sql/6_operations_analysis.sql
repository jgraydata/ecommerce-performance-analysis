-- Operations Analysis
-- Order outcome performance
SELECT
    COUNT(DISTINCT order_id) AS total_orders,

    COUNT(DISTINCT order_id)
        FILTER (
            WHERE LOWER(order_status) = 'cancelled'
        ) AS cancelled_orders,

    COUNT(DISTINCT order_id)
        FILTER (
            WHERE LOWER(order_status) <> 'cancelled'
              AND returned = TRUE
        ) AS returned_orders,

    COUNT(DISTINCT order_id)
        FILTER (
            WHERE LOWER(order_status) <> 'cancelled'
              AND returned = FALSE
        ) AS successful_orders,

    ROUND(
        (
            100.0 * COUNT(DISTINCT order_id)
                FILTER (
                    WHERE LOWER(order_status) = 'cancelled'
                )
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS cancellation_rate_pct,

    ROUND(
        (
            100.0 * COUNT(DISTINCT order_id)
                FILTER (
                    WHERE LOWER(order_status) <> 'cancelled'
                      AND returned = TRUE
                )
            / NULLIF(
                COUNT(DISTINCT order_id)
                    FILTER (
                        WHERE LOWER(order_status) <> 'cancelled'
                    ),
                0
            )
        )::numeric,
        2
    ) AS return_rate_pct,

    ROUND(
        (
            100.0 * COUNT(DISTINCT order_id)
                FILTER (
                    WHERE LOWER(order_status) <> 'cancelled'
                      AND returned = FALSE
                )
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS successful_order_rate_pct

FROM ecommerce_orders;

-- Operational trends
SELECT
    EXTRACT(YEAR FROM order_date)::int AS year,

    COUNT(DISTINCT order_id) AS total_orders,

    COUNT(DISTINCT order_id)
        FILTER (
            WHERE LOWER(order_status) = 'cancelled'
        ) AS cancelled_orders,

    ROUND(
        (
            100.0 * COUNT(DISTINCT order_id)
                FILTER (
                    WHERE LOWER(order_status) = 'cancelled'
                )
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS cancellation_rate_pct,

    COUNT(DISTINCT order_id)
        FILTER (
            WHERE LOWER(order_status) <> 'cancelled'
              AND returned = TRUE
        ) AS returned_orders,

    ROUND(
        (
            100.0 * COUNT(DISTINCT order_id)
                FILTER (
                    WHERE LOWER(order_status) <> 'cancelled'
                      AND returned = TRUE
                )
            / NULLIF(
                COUNT(DISTINCT order_id)
                    FILTER (
                        WHERE LOWER(order_status) <> 'cancelled'
                    ),
                0
            )
        )::numeric,
        2
    ) AS return_rate_pct,

    COUNT(DISTINCT order_id)
        FILTER (
            WHERE LOWER(order_status) <> 'cancelled'
              AND returned = FALSE
        ) AS successful_orders

FROM ecommerce_orders

GROUP BY EXTRACT(YEAR FROM order_date)

ORDER BY year;

-- Return performance
SELECT
    shipping_method,

    COUNT(DISTINCT order_id) AS non_cancelled_orders,

    COUNT(DISTINCT order_id)
        FILTER (
            WHERE returned = TRUE
        ) AS returned_orders,

    ROUND(
        (
            100.0 * COUNT(DISTINCT order_id)
                FILTER (
                    WHERE returned = TRUE
                )
            / NULLIF(COUNT(DISTINCT order_id), 0)
        )::numeric,
        2
    ) AS return_rate_pct,

    ROUND(
        AVG(delivery_days)::numeric,
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(shipping_cost)::numeric,
        2
    ) AS avg_shipping_cost,

    ROUND(
        AVG(review_rating)::numeric,
        2
    ) AS avg_review_rating

FROM ecommerce_orders

WHERE LOWER(order_status) <> 'cancelled'

GROUP BY shipping_method

ORDER BY return_rate_pct DESC;

-- Delivery performance
WITH delivery_bands AS (
    SELECT
        order_id,
        delivery_days,
        review_rating,
        shipping_cost,

        CASE
            WHEN delivery_days <= 2 THEN '1-2 Days'
            WHEN delivery_days <= 4 THEN '3-4 Days'
            WHEN delivery_days <= 6 THEN '5-6 Days'
            ELSE '7+ Days'
        END AS delivery_band

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
)

SELECT
    delivery_band,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        AVG(delivery_days)::numeric,
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(shipping_cost)::numeric,
        2
    ) AS avg_shipping_cost,

    ROUND(
        AVG(review_rating)::numeric,
        2
    ) AS avg_review_rating

FROM delivery_bands

GROUP BY delivery_band

ORDER BY
    CASE delivery_band
        WHEN '1-2 Days' THEN 1
        WHEN '3-4 Days' THEN 2
        WHEN '5-6 Days' THEN 3
        WHEN '7+ Days' THEN 4
    END;