-- Product Analysis
-- Category revenue and profit analysis
WITH category_metrics AS (
    SELECT
        product_category,

        COUNT(DISTINCT order_id) AS orders,

        SUM(quantity) AS units_sold,

        SUM(order_amount) AS revenue,

        SUM(profit_amount) AS profit,

        AVG(discount_percent) AS avg_discount_pct

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY product_category
)

SELECT
    product_category,

    orders,

    units_sold,

    ROUND(
        (revenue / NULLIF(orders, 0))::numeric,
        2
    ) AS avg_order_value,

    ROUND(avg_discount_pct::numeric, 2)
        AS avg_discount_pct,

    ROUND(revenue::numeric, 2) AS revenue,

    ROUND(
        (
            100.0 * revenue
            / NULLIF(SUM(revenue) OVER (), 0)
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(profit::numeric, 2) AS profit,

    ROUND(
        (
            100.0 * profit
            / NULLIF(revenue, 0)
        )::numeric,
        2
    ) AS profit_margin_pct

FROM category_metrics

ORDER BY revenue DESC;

-- Electronice profitability drivers
WITH category_costs AS (
    SELECT
        product_category,

        COUNT(DISTINCT order_id) AS orders,

        SUM(order_amount) AS revenue,

        SUM(profit_amount) AS profit,

        SUM(order_amount - profit_amount) AS implied_cost,

        AVG(shipping_cost) AS avg_shipping_cost,

        AVG(discount_percent) AS avg_discount_pct

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY product_category
)

SELECT
    product_category,

    orders,

    ROUND(revenue::numeric, 2) AS revenue,

    ROUND(profit::numeric, 2) AS profit,

    ROUND(implied_cost::numeric, 2) AS implied_cost,

    ROUND(
        (
            100.0 * implied_cost
            / NULLIF(revenue, 0)
        )::numeric,
        2
    ) AS implied_cost_pct,

    ROUND(
        (
            100.0 * profit
            / NULLIF(revenue, 0)
        )::numeric,
        2
    ) AS profit_margin_pct,

    ROUND(avg_discount_pct::numeric, 2)
        AS avg_discount_pct,

    ROUND(avg_shipping_cost::numeric, 2)
        AS avg_shipping_cost

FROM category_costs

ORDER BY profit_margin_pct;

-- Electronics subcategory profitability
WITH electronics_performance AS (
    SELECT
        product_subcategory,

        COUNT(DISTINCT order_id) AS orders,

        SUM(order_amount) AS revenue,

        SUM(profit_amount) AS profit,

        SUM(order_amount - profit_amount) AS implied_cost,

        AVG(discount_percent) AS avg_discount_pct,

        AVG(shipping_cost) AS avg_shipping_cost

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE
      AND product_category = 'Electronics'

    GROUP BY product_subcategory
)

SELECT
    product_subcategory,

    orders,

    ROUND(revenue::numeric, 2) AS revenue,

    ROUND(
        (
            100.0 * revenue
            / NULLIF(SUM(revenue) OVER (), 0)
        )::numeric,
        2
    ) AS electronics_revenue_share_pct,

    ROUND(profit::numeric, 2) AS profit,

    ROUND(
        (
            100.0 * profit
            / NULLIF(revenue, 0)
        )::numeric,
        2
    ) AS profit_margin_pct,

    ROUND(
        (
            100.0 * implied_cost
            / NULLIF(revenue, 0)
        )::numeric,
        2
    ) AS implied_cost_pct,

    ROUND(avg_discount_pct::numeric, 2)
        AS avg_discount_pct,

    ROUND(avg_shipping_cost::numeric, 2)
        AS avg_shipping_cost,

    RANK() OVER (
        ORDER BY profit / NULLIF(revenue, 0) DESC
    ) AS margin_rank

FROM electronics_performance

ORDER BY profit_margin_pct DESC;

-- Product and subcategory ranking
WITH subcategory_performance AS (
    SELECT
        product_category,
        product_subcategory,

        COUNT(DISTINCT order_id) AS orders,

        SUM(quantity) AS units_sold,

        SUM(order_amount) AS revenue,

        SUM(profit_amount) AS profit

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY
        product_category,
        product_subcategory
),

subcategory_rankings AS (
    SELECT
        product_category,
        product_subcategory,
        orders,
        units_sold,
        revenue,
        profit,

        100.0 * revenue
            / NULLIF(
                SUM(revenue) OVER (
                    PARTITION BY product_category
                ), 0
            ) AS category_revenue_share_pct,

        RANK() OVER (
            PARTITION BY product_category
            ORDER BY revenue DESC
        ) AS revenue_rank,

        RANK() OVER (
            PARTITION BY product_category
            ORDER BY profit DESC
        ) AS profit_rank

    FROM subcategory_performance
)

SELECT
    product_category,
    product_subcategory,

    orders,
    units_sold,

    ROUND(revenue::numeric, 2) AS revenue,

    ROUND(
        category_revenue_share_pct::numeric,
        2
    ) AS category_revenue_share_pct,

    ROUND(profit::numeric, 2) AS profit,

    ROUND(
        (
            100.0 * profit
            / NULLIF(revenue, 0)
        )::numeric,
        2
    ) AS profit_margin_pct,

    revenue_rank,
    profit_rank

FROM subcategory_rankings

ORDER BY
    product_category,
    revenue_rank;

-- Returns analysis by product category
WITH return_performance AS (
    SELECT
        product_category,

        COUNT(DISTINCT order_id)
            FILTER (
                WHERE LOWER(order_status) <> 'cancelled'
            ) AS eligible_orders,

        COUNT(DISTINCT order_id)
            FILTER (
                WHERE LOWER(order_status) <> 'cancelled'
                  AND returned = TRUE
            ) AS returned_orders,

        SUM(order_amount)
            FILTER (
                WHERE LOWER(order_status) <> 'cancelled'
                  AND returned = TRUE
            ) AS returned_order_value,

        SUM(profit_amount)
            FILTER (
                WHERE LOWER(order_status) <> 'cancelled'
                  AND returned = TRUE
            ) AS returned_order_profit

    FROM ecommerce_orders

    GROUP BY product_category
)

SELECT
    product_category,

    eligible_orders,
    returned_orders,

    ROUND(
        (
            100.0 * returned_orders
            / NULLIF(eligible_orders, 0)
        )::numeric,
        2
    ) AS return_rate_pct,

    ROUND(
        returned_order_value::numeric,
        2
    ) AS returned_order_value,

    ROUND(
        (
            returned_order_value
            / NULLIF(returned_orders, 0)
        )::numeric,
        2
    ) AS avg_returned_order_value,

    ROUND(
        (
            100.0 * returned_order_value
            / NULLIF(
                SUM(returned_order_value) OVER (),
                0
            )
        )::numeric,
        2
    ) AS returned_value_share_pct,

    ROUND(
        returned_order_profit::numeric,
        2
    ) AS returned_order_profit

FROM return_performance

ORDER BY returned_order_value DESC;

-- Fashion resturns analysis
WITH fashion_returns AS (
    SELECT
        product_subcategory,

        COUNT(DISTINCT order_id)
            FILTER (
                WHERE LOWER(order_status) <> 'cancelled'
            ) AS eligible_orders,

        COUNT(DISTINCT order_id)
            FILTER (
                WHERE LOWER(order_status) <> 'cancelled'
                  AND returned = TRUE
            ) AS returned_orders,

        SUM(order_amount)
            FILTER (
                WHERE LOWER(order_status) <> 'cancelled'
                  AND returned = TRUE
            ) AS returned_order_value

    FROM ecommerce_orders

    WHERE product_category = 'Fashion'

    GROUP BY product_subcategory
)

SELECT
    product_subcategory,

    eligible_orders,
    returned_orders,

    ROUND(
        (
            100.0 * returned_orders
            / NULLIF(eligible_orders, 0)
        )::numeric,
        2
    ) AS return_rate_pct,

    ROUND(
        returned_order_value::numeric,
        2
    ) AS returned_order_value,

    ROUND(
        (
            returned_order_value
            / NULLIF(returned_orders, 0)
        )::numeric,
        2
    ) AS avg_returned_order_value,

    ROUND(
        (
            100.0 * returned_order_value
            / NULLIF(
                SUM(returned_order_value) OVER (),
                0
            )
        )::numeric,
        2
    ) AS fashion_returned_value_share_pct,

    RANK() OVER (
        ORDER BY
            100.0 * returned_orders
            / NULLIF(eligible_orders, 0) DESC
    ) AS return_rate_rank

FROM fashion_returns

ORDER BY return_rate_pct DESC;