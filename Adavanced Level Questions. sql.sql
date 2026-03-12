-- 1. Moving Average of Order Values
SELECT 
    customer_id, 
    order_purchase_timestamp, 
    payment_value,
    AVG(payment_value) OVER (PARTITION BY customer_id ORDER BY order_purchase_timestamp) AS moving_avg
FROM orders o
JOIN payments p ON o.order_id = p.order_id
limit 10;

-- 2. Cumulative Sales per Month for Each Year
WITH MonthlySales AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS sales_year,
        MONTH(o.order_purchase_timestamp) AS sales_month,
        SUM(p.payment_value) AS monthly_revenue
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY sales_year, sales_month
)
SELECT 
    sales_year, sales_month, monthly_revenue,
    SUM(monthly_revenue) OVER (PARTITION BY sales_year ORDER BY sales_month) AS cumulative_sales
FROM MonthlySales;

-- 3. Year-over-Year (YoY) Growth Rate
WITH YearlySales AS (
    SELECT 
        YEAR(order_purchase_timestamp) AS year, 
        SUM(payment_value) AS total_revenue
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY year
)
SELECT 
    year, 
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year) AS previous_year_revenue,
    ((total_revenue - LAG(total_revenue) OVER (ORDER BY year)) / LAG(total_revenue) OVER (ORDER BY year)) * 100 AS yoy_growth
FROM YearlySales;

-- 4. Retention Rate (Repeat Purchase within 6 Months)
WITH CustomerStats AS (
    SELECT 
        customer_id, 
        MIN(order_purchase_timestamp) AS first_order,
        MAX(order_purchase_timestamp) AS last_order,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    (COUNT(CASE WHEN total_orders > 1 
                AND last_order <= DATE_ADD(first_order, INTERVAL 6 MONTH) 
                THEN 1 END) / COUNT(*)) * 100 AS retention_rate
FROM CustomerStats;

-- 5. Top 3 Customers Who Spent the Most Each Year
WITH CustomerSpending AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS year,
        o.customer_id,
        SUM(p.payment_value) AS total_spent
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY year, o.customer_id
),
RankedCustomers AS (
    SELECT 
        year, customer_id, total_spent,
        RANK() OVER (PARTITION BY year ORDER BY total_spent DESC) AS spend_rank
    FROM CustomerSpending
)
SELECT * FROM RankedCustomers WHERE spend_rank <= 3;