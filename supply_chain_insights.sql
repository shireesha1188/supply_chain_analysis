
-- 1. Most used transport mode and shipment carrier by supplier
WITH CTE AS (
    SELECT
        s.supplier_key,
        s.ship_mode,
        s.shipment_carrier,
        COUNT(*) AS mode_carrier_count,
        ROW_NUMBER() OVER (PARTITION BY s.supplier_key ORDER BY COUNT(*) DESC) AS rn
    FROM sales AS s
    GROUP BY s.supplier_key, s.ship_mode, s.shipment_carrier
)
SELECT supplier_key, ship_mode AS most_used_transport_mode, shipment_carrier AS most_used_carrier
FROM CTE
WHERE rn = 1;

-- 2. Supplier's most opted payment mode
WITH SupplierPaymentRank AS (
    SELECT supplier_key, payment_mode,
           COUNT(*) AS count,
           ROW_NUMBER() OVER (PARTITION BY supplier_key ORDER BY COUNT(*) DESC) AS rank
    FROM sales
    GROUP BY supplier_key, payment_mode
)
SELECT supplier_key, payment_mode AS most_used_payment_mode FROM SupplierPaymentRank
WHERE rank = 1;

-- 3. Year-wise ship_mode revenue percentage

WITH ShipSales AS (
    SELECT YEAR(order_date) AS year, ship_mode, SUM(total_amount) AS revenue
    FROM sales GROUP BY YEAR(order_date), ship_mode
), 
TotalYearlySales AS (
    SELECT year, SUM(revenue) AS total_revenue FROM ShipSales GROUP BY year
)
SELECT ss.year, ss.ship_mode, ss.revenue,
       CAST(ss.revenue * 100.0 / tys.total_revenue AS DECIMAL(5,2)) AS percentage
FROM ShipSales ss JOIN TotalYearlySales tys ON ss.year = tys.year
ORDER BY ss.year, percentage DESC;

-- 4. Supplier delivery performance by year
SELECT supplier_key, YEAR(order_date) AS year,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN delivery_status = 'Delivered' THEN 1 ELSE 0 END) AS successful_orders,
       AVG(DATEDIFF(DAY, order_date, due_date)) AS avg_delivery_time
FROM sales GROUP BY supplier_key, YEAR(order_date)
ORDER BY supplier_key, year;

-- 5. High-margin products and their suppliers
SELECT p.product_name, su.supplier_name,
       SUM(s.total_amount) AS revenue,
       SUM(p.cost * s.quantity) AS cost,
       SUM(s.total_amount - p.cost * s.quantity) AS profit,
       RANK() OVER (ORDER BY SUM(s.total_amount - p.cost * s.quantity) DESC) AS profit_rank
FROM sales s
JOIN products p ON s.product_key = p.product_key
JOIN suppliers su ON p.supplier_key = su.supplier_key
GROUP BY p.product_name, su.supplier_name;

-- 6. Supplier revenue contribution %
SELECT su.supplier_name,
       SUM(s.total_amount) AS supplier_revenue,
       CAST(SUM(s.total_amount) * 100.0 / (SELECT SUM(total_amount) FROM sales) AS DECIMAL(5,2)) AS revenue_percent
FROM sales s
JOIN products p ON s.product_key = p.product_key
JOIN suppliers su ON p.supplier_key = su.supplier_key
GROUP BY su.supplier_name
ORDER BY supplier_revenue DESC;

-- 7. Sales forecast using customer order pattern (CLTV)
SELECT c.first_name + ' ' + c.last_name AS customer_name,
       COUNT(DISTINCT s.order_number) AS orders,
       SUM(s.total_amount) AS total_spent,
       AVG(s.total_amount) AS avg_order_value,
       SUM(s.total_amount) * COUNT(DISTINCT s.order_number) AS cltv_score
FROM sales s
JOIN customers c ON s.customer_key = c.customer_key
GROUP BY c.first_name, c.last_name
ORDER BY cltv_score DESC;

-- 8. Peak ordering days and average delivery time
WITH DeliveryStats AS (
    SELECT DATENAME(WEEKDAY, CAST(order_date AS DATE)) AS order_day,
           COUNT(*) AS total_orders,
           AVG(DATEDIFF(DAY, CAST(order_date AS DATE), CAST(delivered_date AS DATE))) AS avg_delivery_time
    FROM sales GROUP BY DATENAME(WEEKDAY, CAST(order_date AS DATE))
)
SELECT * FROM DeliveryStats ORDER BY total_orders DESC;

-- 9. Products with high late delivery rate
SELECT p.product_name,
       COUNT(s.order_number) AS total_orders,
       SUM(CASE WHEN s.delivery_status = 'Late' THEN 1 ELSE 0 END) AS late_deliveries,
       CAST(SUM(CASE WHEN s.delivery_status = 'Late' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(s.order_number) AS late_delivery_rate
FROM sales s
JOIN products p ON s.product_key = p.product_key
GROUP BY p.product_name
HAVING COUNT(s.order_number) > 5
ORDER BY late_delivery_rate DESC;

-- 10. Customers who never ordered
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN sales s ON c.customer_key = s.customer_key
WHERE s.order_number IS NULL;
