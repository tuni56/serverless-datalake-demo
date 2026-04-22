-- ============================================
-- QUERIES DE ANÁLISIS - E-COMMERCE DATA LAKE
-- ============================================
-- Motor: Athena engine v3 (Trino)
-- Database: ecommerce-datalake_dev
-- Tabla orders usa Partition Projection (year, month)
--
-- Nota: usar comillas dobles para nombres con guión
--   FROM "ecommerce-datalake_dev".orders

-- 1. Ventas totales por mes
SELECT
    year,
    month,
    COUNT(*)                      AS total_orders,
    ROUND(SUM(total_amount), 2)   AS revenue,
    ROUND(AVG(total_amount), 2)   AS avg_ticket
FROM "ecommerce-datalake_dev".orders
WHERE status = 'completed'
GROUP BY year, month
ORDER BY year DESC, month DESC
LIMIT 12;

-- 2. Top 10 productos más vendidos
SELECT
    p.product_id,
    p.name,
    p.category,
    COUNT(o.order_id)              AS times_sold,
    SUM(o.quantity)                AS total_quantity,
    ROUND(SUM(o.total_amount), 2)  AS total_revenue
FROM "ecommerce-datalake_dev".orders o
JOIN "ecommerce-datalake_dev".products p ON o.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.product_id, p.name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

-- 3. Revenue por categoría
SELECT
    p.category,
    COUNT(DISTINCT o.order_id)     AS total_orders,
    ROUND(SUM(o.total_amount), 2)  AS revenue,
    ROUND(AVG(o.total_amount), 2)  AS avg_order_value
FROM "ecommerce-datalake_dev".orders o
JOIN "ecommerce-datalake_dev".products p ON o.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- 4. Top 10 clientes por revenue (lifetime value)
SELECT
    c.customer_id,
    c.name,
    c.country,
    COUNT(o.order_id)              AS total_orders,
    ROUND(SUM(o.total_amount), 2)  AS lifetime_value
FROM "ecommerce-datalake_dev".customers c
JOIN "ecommerce-datalake_dev".orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name, c.country
ORDER BY lifetime_value DESC
LIMIT 10;

-- 5. Ventas por país
SELECT
    c.country,
    COUNT(DISTINCT c.customer_id)  AS total_customers,
    COUNT(o.order_id)              AS total_orders,
    ROUND(SUM(o.total_amount), 2)  AS revenue,
    ROUND(AVG(o.total_amount), 2)  AS avg_ticket
FROM "ecommerce-datalake_dev".customers c
JOIN "ecommerce-datalake_dev".orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.country
ORDER BY revenue DESC;

-- 6. Tasa de conversión por status
SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM "ecommerce-datalake_dev".orders
GROUP BY status
ORDER BY order_count DESC;

-- 7. Análisis de cohortes - Clientes por mes de registro
SELECT
    date_trunc('month', c.registration_date) AS cohort_month,
    COUNT(DISTINCT c.customer_id)            AS new_customers,
    COUNT(o.order_id)                        AS total_orders,
    ROUND(SUM(o.total_amount), 2)            AS revenue
FROM "ecommerce-datalake_dev".customers c
LEFT JOIN "ecommerce-datalake_dev".orders o
    ON c.customer_id = o.customer_id AND o.status = 'completed'
GROUP BY 1
ORDER BY 1 DESC;

-- 8. Productos con bajo stock
SELECT
    product_id,
    name,
    category,
    price,
    stock
FROM "ecommerce-datalake_dev".products
WHERE stock < 50
ORDER BY stock ASC
LIMIT 20;

-- 9. Revenue mensual con crecimiento MoM
WITH monthly_revenue AS (
    SELECT
        year,
        month,
        ROUND(SUM(total_amount), 2) AS revenue
    FROM "ecommerce-datalake_dev".orders
    WHERE status = 'completed'
    GROUP BY year, month
)
SELECT
    year,
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY year, month))
        / LAG(revenue) OVER (ORDER BY year, month) * 100, 2
    ) AS growth_pct
FROM monthly_revenue
ORDER BY year DESC, month DESC
LIMIT 12;

-- 10. Análisis de productos por rango de precio
SELECT
    CASE
        WHEN price < 50                THEN 'Budget (< $50)'
        WHEN price BETWEEN 50 AND 200  THEN 'Mid-range ($50-$200)'
        WHEN price BETWEEN 200 AND 500 THEN 'Premium ($200-$500)'
        ELSE                                'Luxury (> $500)'
    END                  AS price_range,
    COUNT(*)             AS product_count,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(stock)           AS total_stock
FROM "ecommerce-datalake_dev".products
GROUP BY 1
ORDER BY avg_price;

-- 11. Partition Projection en acción — filtro por partición (scan mínimo)
SELECT COUNT(*) AS orders_q1_2026, ROUND(SUM(total_amount), 2) AS revenue
FROM "ecommerce-datalake_dev".orders
WHERE year = 2026 AND month BETWEEN 1 AND 3;
