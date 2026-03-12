-- ============================================
-- QUERIES DE ANÁLISIS - E-COMMERCE DATA LAKE
-- ============================================

-- 1. Ventas totales por mes
SELECT 
    year,
    month,
    COUNT(*) as total_orders,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_ticket
FROM orders
WHERE status = 'completed'
GROUP BY year, month
ORDER BY year DESC, month DESC
LIMIT 12;

-- 2. Top 10 productos más vendidos
SELECT 
    p.product_id,
    p.name,
    p.category,
    COUNT(o.order_id) as times_sold,
    SUM(o.quantity) as total_quantity,
    SUM(o.total_amount) as total_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.product_id, p.name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

-- 3. Revenue por categoría
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as revenue,
    AVG(o.total_amount) as avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- 4. Top 10 clientes por revenue
SELECT 
    c.customer_id,
    c.name,
    c.country,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name, c.country
ORDER BY lifetime_value DESC
LIMIT 10;

-- 5. Ventas por país
SELECT 
    c.country,
    COUNT(DISTINCT c.customer_id) as total_customers,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as revenue,
    AVG(o.total_amount) as avg_ticket
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.country
ORDER BY revenue DESC;

-- 6. Tasa de conversión por status
SELECT 
    status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- 7. Análisis de cohortes - Clientes por mes de registro
SELECT 
    DATE_TRUNC('month', CAST(c.registration_date AS DATE)) as cohort_month,
    COUNT(DISTINCT c.customer_id) as new_customers,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'completed'
GROUP BY cohort_month
ORDER BY cohort_month DESC;

-- 8. Productos con bajo stock
SELECT 
    product_id,
    name,
    category,
    price,
    stock
FROM products
WHERE stock < 50
ORDER BY stock ASC
LIMIT 20;

-- 9. Revenue mensual con crecimiento
WITH monthly_revenue AS (
    SELECT 
        year,
        month,
        SUM(total_amount) as revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY year, month
)
SELECT 
    year,
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY year, month) as prev_month_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year, month)) / 
          LAG(revenue) OVER (ORDER BY year, month) * 100, 2) as growth_percentage
FROM monthly_revenue
ORDER BY year DESC, month DESC
LIMIT 12;

-- 10. Análisis de productos por rango de precio
SELECT 
    CASE 
        WHEN price < 50 THEN 'Budget (< $50)'
        WHEN price BETWEEN 50 AND 200 THEN 'Mid-range ($50-$200)'
        WHEN price BETWEEN 200 AND 500 THEN 'Premium ($200-$500)'
        ELSE 'Luxury (> $500)'
    END as price_range,
    COUNT(*) as product_count,
    AVG(price) as avg_price,
    SUM(stock) as total_stock
FROM products
GROUP BY 
    CASE 
        WHEN price < 50 THEN 'Budget (< $50)'
        WHEN price BETWEEN 50 AND 200 THEN 'Mid-range ($50-$200)'
        WHEN price BETWEEN 200 AND 500 THEN 'Premium ($200-$500)'
        ELSE 'Luxury (> $500)'
    END
ORDER BY avg_price;
