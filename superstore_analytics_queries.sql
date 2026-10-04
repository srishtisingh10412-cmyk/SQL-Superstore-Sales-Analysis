-- =======================================================
-- SUPERSTORE SALES ANALYTICS MASTER PROJECT SCRIPT
-- Database: superstore_db
-- =======================================================

USE superstore_db;

-- -------------------------------------------------------
-- 1. DATA AUDIT & OVERVIEW
-- -------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM sales_orders;

-- -------------------------------------------------------
-- 2. CUSTOMER SEGMENT PERFORMANCE
-- -------------------------------------------------------
SELECT 
    segment,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(AVG(sales), 2) AS avg_order_value
FROM sales_orders
GROUP BY segment
ORDER BY total_revenue DESC;

-- -------------------------------------------------------
-- 3. CATEGORY & SUB-CATEGORY BREAKDOWN
-- -------------------------------------------------------
SELECT 
    category, 
    sub_category, 
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_revenue
FROM sales_orders
GROUP BY category, sub_category
ORDER BY total_revenue DESC;

-- -------------------------------------------------------
-- 4. PERFORMANCE BY SHIPPING MODE
-- -------------------------------------------------------
SELECT 
    ship_mode, 
    COUNT(order_id) AS order_count, 
    ROUND(SUM(sales), 2) AS revenue_generated
FROM sales_orders
GROUP BY ship_mode
ORDER BY revenue_generated DESC;

-- -------------------------------------------------------
-- 5. REGIONAL RANKING & TOP CUSTOMERS (WINDOW FUNCTION)
-- -------------------------------------------------------
WITH customer_regional_sales AS (
    SELECT 
        region,
        customer_id,
        customer_name,
        ROUND(SUM(sales), 2) AS total_spent
    FROM sales_orders
    GROUP BY region, customer_id, customer_name
),
ranked_customers AS (
    SELECT 
        region,
        customer_name,
        total_spent,
        DENSE_RANK() OVER (PARTITION BY region ORDER BY total_spent DESC) AS regional_rank
    FROM customer_regional_sales
)
SELECT * 
FROM ranked_customers
WHERE regional_rank <= 5
ORDER BY region, regional_rank;

-- -------------------------------------------------------
-- 6. YEAR-OVER-YEAR (YoY) SALES GROWTH (WINDOW FUNCTION)
-- -------------------------------------------------------
WITH yearly_sales AS (
    SELECT 
        YEAR(order_date) AS sales_year,
        ROUND(SUM(sales), 2) AS current_year_sales
    FROM sales_orders
    GROUP BY YEAR(order_date)
)
SELECT 
    sales_year,
    current_year_sales,
    COALESCE(LAG(current_year_sales, 1) OVER (ORDER BY sales_year), 0) AS previous_year_sales,
    ROUND(
        (current_year_sales - LAG(current_year_sales, 1) OVER (ORDER BY sales_year)) 
        / NULLIF(LAG(current_year_sales, 1) OVER (ORDER BY sales_year), 0) * 100, 2
    ) AS yoy_growth_percentage
FROM yearly_sales;

-- -------------------------------------------------------
-- 7. ABOVE-AVERAGE ORDER VALUE IDENTIFICATION
-- -------------------------------------------------------
WITH order_totals AS (
    SELECT 
        order_id,
        customer_name,
        ROUND(SUM(sales), 2) AS order_value
    FROM sales_orders
    GROUP BY order_id, customer_name
),
global_avg AS (
    SELECT AVG(order_value) AS avg_order_value FROM order_totals
)
SELECT 
    ot.order_id,
    ot.customer_name,
    ot.order_value,
    ROUND(ga.avg_order_value, 2) AS global_avg_order_value
FROM order_totals ot
CROSS JOIN global_avg ga
WHERE ot.order_value > ga.avg_order_value
ORDER BY ot.order_value DESC;

-- -------------------------------------------------------
-- 8. MONTHLY REVENUE TRENDS
-- -------------------------------------------------------
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS year_months,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS monthly_revenue
FROM sales_orders
GROUP BY year_months
ORDER BY year_months;