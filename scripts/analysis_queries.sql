/* ====================================================
Task 1: Revenue & Sales Trend / Step A: Monthly Revenue
=======================================================
*/

SELECT 
strftime('%Y-%m', order_purchase_timestamp) AS time, ROUND(SUM(items.price + items.freight_value), 2) AS total_revenue, 
COUNT(DISTINCT orders.order_id) AS number_of_orders 
FROM olist_orders_dataset AS orders
INNER JOIN olist_order_items_dataset AS items
ON orders.order_id = items.order_id
WHERE orders.order_status = 'delivered'
GROUP BY time 
ORDER BY time ASC;

/* =======================================================================
Task 2: Product portfolio & Profitability / Step A: Top Product Categories
==========================================================================
*/

SELECT 
COALESCE(trans.product_category_name_english, products.product_category_name) AS category, 
ROUND(SUM(items.price + items.freight_value),2) AS sale,
COUNT (items.product_id) AS number_of_items_sold, 
ROUND(AVG(items.price), 2) AS avg_price
FROM olist_orders_dataset AS orders
INNER JOIN olist_order_items_dataset AS items ON orders.order_id = items.order_id 
INNER JOIN olist_products_dataset AS products ON items.product_id = products.product_id
LEFT JOIN product_category_name_translation AS trans ON products.product_category_name = trans.product_category_name 
WHERE orders.order_status = 'delivered'
GROUP BY category
ORDER BY sale DESC 
LIMIT 10;

/* ========================================================================
Task 3: Logistics & Delivery Performance / Step A: Regional Delivery Delays
===========================================================================
*/

WITH delivery_performance AS (
SELECT customers.customer_state, orders.order_id,
CASE 
WHEN (julianday(orders.order_delivered_customer_date) - julianday(orders.order_estimated_delivery_date)) > 3 THEN 'Very Late'
WHEN (julianday(orders.order_delivered_customer_date) - julianday(orders.order_estimated_delivery_date)) > 0 THEN 'Slightly Late'
ELSE 'On-time or Early'
END AS delivery_status
FROM olist_orders_dataset AS orders
JOIN olist_customers_dataset AS customers ON orders.customer_id = customers.customer_id
WHERE orders.order_status = 'delivered'
)
SELECT customer_state,
COUNT(*) AS total_orders,
SUM(CASE WHEN delivery_status = 'Very Late' THEN 1 ELSE 0 END) AS very_late_count,
ROUND((SUM(CASE WHEN delivery_status = 'Very Late' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS percentage_very_late
FROM delivery_performance
GROUP BY customer_state
ORDER BY percentage_very_late DESC
LIMIT 5;

/* ==================================================================
Task 3: Logistics & Delivery Performance / Step B: The Cost Of Delays
=====================================================================
*/

WITH delivery_and_reviews AS (
SELECT orders.order_id, reviews.review_score,
CASE 
WHEN (julianday(orders.order_delivered_customer_date) - julianday(orders.order_estimated_delivery_date)) > 3 THEN 'Very Late'
WHEN (julianday(orders.order_delivered_customer_date) - julianday(orders.order_estimated_delivery_date)) > 0 THEN 'Slightly Late'
ELSE 'On-time or Early'
END AS delivery_status
FROM olist_orders_dataset AS orders
JOIN olist_order_reviews_dataset AS reviews ON orders.order_id = reviews.order_id
WHERE orders.order_status = 'delivered'
)
SELECT 
delivery_status,
COUNT(*) AS number_of_reviews,
ROUND(AVG(review_score), 2) AS average_review_score
FROM delivery_and_reviews
GROUP BY delivery_status
ORDER BY average_review_score DESC;

/* ==============================================================================
Task 4: Customer Retention & Lifecycle / Step A: One-Time vs. Returning Customers
=================================================================================
*/

WITH customer_order_counts AS (
SELECT customers.customer_unique_id,
COUNT(orders.order_id) AS order_count,
SUM(payments.payment_value) AS total_spent
FROM olist_orders_dataset AS orders
INNER JOIN olist_customers_dataset AS customers ON orders.customer_id = customers.customer_id
INNER JOIN olist_order_payments_dataset AS payments ON orders.order_id = payments.order_id
WHERE orders.order_status = 'delivered'
GROUP BY customers.customer_unique_id
),
customer_segmentation AS (
SELECT customer_unique_id, order_count, total_spent,
CASE 
WHEN order_count > 1 THEN 'Returning Customer'
ELSE 'One-time Customer'
END AS loyalty_segment
FROM customer_order_counts
)
SELECT 
loyalty_segment,
COUNT(customer_unique_id) AS number_of_customers,
ROUND(AVG(total_spent / order_count), 2) AS avg_order_value,
ROUND(COUNT(customer_unique_id) * 100.0 / (SELECT COUNT(*) FROM customer_segmentation), 2) AS percentage_share
FROM customer_segmentation
GROUP BY loyalty_segment;
