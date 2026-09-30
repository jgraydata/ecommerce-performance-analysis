-- Customer Analysis
-- Customer value
WITH customer_value AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS successful_orders,

        SUM(quantity) AS units_purchased,

        SUM(order_amount) AS realised_revenue,

        SUM(profit_amount) AS realised_profit,

        AVG(order_amount) AS avg_order_value

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY customer_id
)

SELECT
    customer_id,
    successful_orders,
    units_purchased,

    ROUND(realised_revenue::numeric, 2)
        AS realised_revenue,

    ROUND(realised_profit::numeric, 2)
        AS realised_profit,

    ROUND(avg_order_value::numeric, 2)
        AS avg_order_value,

    RANK() OVER (
        ORDER BY realised_revenue DESC
    ) AS revenue_rank

FROM customer_value

ORDER BY realised_revenue DESC

LIMIT 20;

--Customer revenue concentration
WITH customer_value AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS successful_orders,
        SUM(order_amount) AS realised_revenue,
        SUM(profit_amount) AS realised_profit

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY customer_id
),

customer_deciles AS (
    SELECT
        customer_id,
        successful_orders,
        realised_revenue,
        realised_profit,

        NTILE(10) OVER (
            ORDER BY realised_revenue DESC
        ) AS revenue_decile

    FROM customer_value
)

SELECT
    revenue_decile,

    COUNT(*) AS customers,

    SUM(successful_orders) AS successful_orders,

    ROUND(
        SUM(realised_revenue)::numeric,
        2
    ) AS realised_revenue,

    ROUND(
        (
            100.0 * SUM(realised_revenue)
            / SUM(SUM(realised_revenue)) OVER ()
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(
        SUM(realised_profit)::numeric,
        2
    ) AS realised_profit,

    ROUND(
        (
            100.0 * SUM(realised_profit)
            / SUM(SUM(realised_profit)) OVER ()
        )::numeric,
        2
    ) AS profit_share_pct,

    ROUND(
        AVG(successful_orders)::numeric,
        2
    ) AS avg_successful_orders

FROM customer_deciles

GROUP BY revenue_decile

ORDER BY revenue_decile;

-- Customer segment
SELECT
    customer_segment,

    COUNT(DISTINCT customer_id) AS customers,

    COUNT(DISTINCT order_id) AS successful_orders,

    ROUND(
        AVG(order_amount)::numeric,
        2
    ) AS avg_order_value,

    ROUND(
        SUM(order_amount)::numeric,
        2
    ) AS realised_revenue,

    ROUND(
        (
            100.0 * SUM(order_amount)
            / SUM(SUM(order_amount)) OVER ()
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(
        SUM(profit_amount)::numeric,
        2
    ) AS realised_profit,

    ROUND(
        (
            100.0 * SUM(profit_amount)
            / NULLIF(SUM(order_amount), 0)
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_orders

WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE

GROUP BY customer_segment

ORDER BY realised_revenue DESC;

-- Membership performance
SELECT
    membership_status,

    COUNT(DISTINCT customer_id) AS customers,

    COUNT(DISTINCT order_id) AS successful_orders,

    ROUND(
        AVG(order_amount)::numeric,
        2
    ) AS avg_order_value,

    ROUND(
        SUM(order_amount)::numeric,
        2
    ) AS realised_revenue,

    ROUND(
        (
            100.0 * SUM(order_amount)
            / SUM(SUM(order_amount)) OVER ()
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(
        SUM(profit_amount)::numeric,
        2
    ) AS realised_profit,

    ROUND(
        (
            100.0 * SUM(profit_amount)
            / NULLIF(SUM(order_amount), 0)
        )::numeric,
        2
    ) AS profit_margin_pct

FROM ecommerce_orders

WHERE LOWER(order_status) <> 'cancelled'
  AND returned = FALSE

GROUP BY membership_status

ORDER BY realised_revenue DESC;

-- Repeat purchase behaviour
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS successful_orders,
        SUM(order_amount) AS realised_revenue,
        SUM(profit_amount) AS realised_profit

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY customer_id
),

purchase_frequency AS (
    SELECT
        customer_id,
        successful_orders,
        realised_revenue,
        realised_profit,

        CASE
            WHEN successful_orders = 1 THEN '1 Order'
            WHEN successful_orders BETWEEN 2 AND 3 THEN '2-3 Orders'
            WHEN successful_orders BETWEEN 4 AND 5 THEN '4-5 Orders'
            ELSE '6+ Orders'
        END AS purchase_frequency_group

    FROM customer_orders
)

SELECT
    purchase_frequency_group,

    COUNT(*) AS customers,

    ROUND(
        (
            100.0 * COUNT(*)
            / SUM(COUNT(*)) OVER ()
        )::numeric,
        2
    ) AS customer_share_pct,

    SUM(successful_orders) AS successful_orders,

    ROUND(
        AVG(successful_orders)::numeric,
        2
    ) AS avg_successful_orders,

    ROUND(
        SUM(realised_revenue)::numeric,
        2
    ) AS realised_revenue,

    ROUND(
        (
            100.0 * SUM(realised_revenue)
            / SUM(SUM(realised_revenue)) OVER ()
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(
        AVG(realised_revenue)::numeric,
        2
    ) AS avg_revenue_per_customer,

    ROUND(
        SUM(realised_profit)::numeric,
        2
    ) AS realised_profit

FROM purchase_frequency

GROUP BY purchase_frequency_group

ORDER BY
    CASE purchase_frequency_group
        WHEN '1 Order' THEN 1
        WHEN '2-3 Orders' THEN 2
        WHEN '4-5 Orders' THEN 3
        WHEN '6+ Orders' THEN 4
    END;