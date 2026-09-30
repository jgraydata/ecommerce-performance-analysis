-- Sales Analysis
-- Year on year growth
WITH annual_performance AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::int AS year,
        COUNT(DISTINCT order_id) AS orders,
        SUM(quantity) AS units_sold,
        SUM(order_amount) AS revenue,
        SUM(profit_amount) AS profit
    FROM ecommerce_orders
    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE
    GROUP BY EXTRACT(YEAR FROM order_date)
),

previous_year AS (
    SELECT
        year,
        orders,
        units_sold,
        revenue,
        profit,

        LAG(orders) OVER (ORDER BY year) AS previous_orders,
        LAG(revenue) OVER (ORDER BY year) AS previous_revenue,
        LAG(profit) OVER (ORDER BY year) AS previous_profit

    FROM annual_performance
)

SELECT
    year,
    orders,

    ROUND(
        (
            100.0 * (orders - previous_orders)
            / NULLIF(previous_orders, 0)
        )::numeric,
        2
    ) AS order_growth_pct,

    ROUND(revenue::numeric, 2) AS revenue,

    ROUND(
        (
            100.0 * (revenue - previous_revenue)
            / NULLIF(previous_revenue, 0)
        )::numeric,
        2
    ) AS revenue_growth_pct,

    ROUND(profit::numeric, 2) AS profit,

    ROUND(
        (
            100.0 * (profit - previous_profit)
            / NULLIF(previous_profit, 0)
        )::numeric,
        2
    ) AS profit_growth_pct

FROM previous_year
ORDER BY year;

-- Monthly performance
WITH monthly_performance AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::int AS year,
        EXTRACT(MONTH FROM order_date)::int AS month_number,
        TO_CHAR(order_date, 'Mon') AS month_name,

        COUNT(DISTINCT order_id) AS orders,
        SUM(order_amount) AS revenue,
        SUM(profit_amount) AS profit

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY
        EXTRACT(YEAR FROM order_date),
        EXTRACT(MONTH FROM order_date),
        TO_CHAR(order_date, 'Mon')
),

seasonality AS (
    SELECT
        month_number,
        month_name,

        ROUND(AVG(orders)::numeric, 2) AS avg_monthly_orders,
        ROUND(AVG(revenue)::numeric, 2) AS avg_monthly_revenue,
        ROUND(AVG(profit)::numeric, 2) AS avg_monthly_profit

    FROM monthly_performance

    GROUP BY
        month_number,
        month_name
)

SELECT
    month_number,
    month_name,
    avg_monthly_orders,
    avg_monthly_revenue,
    avg_monthly_profit,

    RANK() OVER (
        ORDER BY avg_monthly_revenue DESC
    ) AS revenue_rank

FROM seasonality

ORDER BY month_number;

-- Revenue growth drivers
WITH annual_metrics AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::int AS year,

        COUNT(DISTINCT order_id) AS orders,

        SUM(order_amount) AS revenue,

        SUM(order_amount)
        / NULLIF(COUNT(DISTINCT order_id), 0) AS avg_order_value

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY EXTRACT(YEAR FROM order_date)
),

growth_metrics AS (
    SELECT
        year,
        orders,
        revenue,
        avg_order_value,

        LAG(orders) OVER (
            ORDER BY year
        ) AS previous_orders,

        LAG(revenue) OVER (
            ORDER BY year
        ) AS previous_revenue,

        LAG(avg_order_value) OVER (
            ORDER BY year
        ) AS previous_aov

    FROM annual_metrics
)

SELECT
    year,

    orders,

    ROUND(
        (
            100.0 * (orders - previous_orders)
            / NULLIF(previous_orders, 0)
        )::numeric,
        2
    ) AS order_growth_pct,

    ROUND(avg_order_value::numeric, 2) AS avg_order_value,

    ROUND(
        (
            100.0 * (avg_order_value - previous_aov)
            / NULLIF(previous_aov, 0)
        )::numeric,
        2
    ) AS aov_growth_pct,

    ROUND(revenue::numeric, 2) AS revenue,

    ROUND(
        (
            100.0 * (revenue - previous_revenue)
            / NULLIF(previous_revenue, 0)
        )::numeric,
        2
    ) AS revenue_growth_pct

FROM growth_metrics

ORDER BY year;

-- Revenue concentration
WITH category_performance AS (
    SELECT
        product_category,

        COUNT(DISTINCT order_id) AS orders,
        SUM(order_amount) AS revenue,
        SUM(profit_amount) AS profit

    FROM ecommerce_orders

    WHERE LOWER(order_status) <> 'cancelled'
      AND returned = FALSE

    GROUP BY product_category
),

category_contribution AS (
    SELECT
        product_category,
        orders,
        revenue,
        profit,

        SUM(revenue) OVER () AS total_revenue,
        SUM(profit) OVER () AS total_profit

    FROM category_performance
)

SELECT
    product_category,

    orders,

    ROUND(revenue::numeric, 2) AS revenue,

    ROUND(
        (
            100.0 * revenue
            / NULLIF(total_revenue, 0)
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(profit::numeric, 2) AS profit,

    ROUND(
        (
            100.0 * profit
            / NULLIF(total_profit, 0)
        )::numeric,
        2
    ) AS profit_share_pct,

    ROUND(
        (
            100.0 * profit
            / NULLIF(revenue, 0)
        )::numeric,
        2
    ) AS profit_margin_pct,

    RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank

FROM category_contribution

ORDER BY revenue DESC;