--1.Total sales and total order over time
SELECT YEAR(order_date) AS year,COUNT(*) AS orders,SUM(total_amount) AS total_sales FROM sales
GROUP BY YEAR(order_date)
ORDER BY year ASC

--2.Customers with  Cancelled orders

SELECT  
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(s.order_number) AS cancelled_order_count
FROM sales s
JOIN customers c ON c.customer_key = s.customer_key
WHERE s.delivery_status = 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY cancelled_order_count DESC;

--3.Product performance by shipment mode

SELECT p.category,s.ship_mode ,SUM(s.quantity) AS total_quantity FROM sales s
JOIN products p ON p.product_key=s.product_key
GROUP BY p.category,s.ship_mode
ORDER BY total_quantity ASC

--4.Delivery_status by shipmentcarrier and company

SELECT
    shipment_carrier,
    shipment_company,
    CAST(SUM(CASE WHEN delivery_status = 'On-Time' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) AS on_time_delivery_rate
FROM
    sales
GROUP BY
    shipment_carrier, shipment_company
ORDER BY
    on_time_delivery_rate DESC;

--5.Products with high Late delivery_time

SELECT 
    p.product_name,
    COUNT(s.order_number) AS total_orders,
    SUM(CASE WHEN s.delivery_status = 'Late' THEN 1 ELSE 0 END) AS late_deliveries,
    CAST(SUM(CASE WHEN s.delivery_status = 'Late' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(s.order_number) AS late_delivery_rate
FROM
    sales AS s
JOIN
    products AS p ON s.product_key = p.product_key
GROUP BY
    p.product_name
HAVING
    COUNT(s.order_number) > 5
ORDER BY
    late_delivery_rate DESC


--6.Total products supplied by each supplier

SELECT s.supplier_name,s.supplier_key,COUNT(p.product_name) AS count FROM suppliers s
JOIN products p ON p.supplier_key=s.supplier_key
GROUP BY s.supplier_key,s.supplier_name
order by count

--7.Total quantity sold per each product

SELECT p.product_name,SUM(S.quantity) AS total_quantity FROM sales s
JOIN products p ON p.product_key=s.product_key
GROUP BY p.product_name
ORDER BY total_quantity DESC

--8.Customers who are not order anything

SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN sales s ON c.customer_key = s.customer_key
WHERE s.order_number IS NULL;

--9.Late deliveries by suppliers

SELECT su.supplier_name,COUNT(s.delivery_status) AS late_deliveries FROM suppliers su
JOIN sales s ON s.supplier_key=su.supplier_key
WHERE s.delivery_status='Late'
GROUP BY su.supplier_name



