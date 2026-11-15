-- ============================================================
-- Olist e-commerce analysis
-- File: 00_raw_diagnostics.sql
-- What it does: checks the raw tables before any view is built (counts, date problems,
-- duplicates, strange values). Read-only SELECTs, run it after loading the CSV files.
-- Author: Claudio Matarrese
-- ============================================================


-- ============================================================
-- 01) Orders: basic counts
-- ============================================================

-- Orders in the raw table
SELECT COUNT(*) AS total_orders_raw
FROM orders;

-- Orders with status 'delivered'
SELECT COUNT(*) AS total_orders_delivered
FROM orders
WHERE order_status = 'delivered';


-- ============================================================
-- 02) Customers: duplicates and missing values
-- ============================================================

-- Rows in the customers table
SELECT COUNT(*) AS total_customers_raw
FROM customers;

-- customer_unique_id should never be NULL
SELECT customer_id, COUNT(*)
FROM customers
WHERE customer_unique_id IS NULL
GROUP BY customer_id;


-- ============================================================
-- 03) Orders: date checks on the raw data
-- ============================================================

-- 03.1) Orders whose dates are not in a logical order
SELECT COUNT(*) AS orders_with_temporal_errors
FROM orders
WHERE order_purchase_timestamp > order_approved_at
   OR order_approved_at > order_delivered_carrier_date
   OR order_delivered_customer_date < order_delivered_carrier_date
   OR order_delivered_customer_date < order_purchase_timestamp;

-- 03.2) Delivered to the customer before the carrier picked it up
SELECT COUNT(*) AS delivery_before_shipment
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- 03.3) Delivered before the purchase (negative delivery time)
SELECT COUNT(*) AS negative_lead_time
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 03.4) Delivered more than 30 days before the estimated date.
-- Only looked at here to understand the data, it is not used to filter orders.
SELECT COUNT(*) AS extreme_negative_delays
FROM orders
WHERE EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date)) / 86400 < -30;


-- ============================================================
-- 04) Reviews: raw checks
-- ============================================================

-- Answer sent before the review was created
SELECT COUNT(*) AS negative_response_timing
FROM order_reviews_full
WHERE review_answer_timestamp < review_creation_date;

-- Reviews loaded
SELECT COUNT(*) AS total_valid_reviews
FROM order_reviews_full;

-- Reviews per score
SELECT review_score, COUNT(*) AS review_count
FROM order_reviews_full
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 05) Items: raw checks
-- ============================================================

-- Items with a zero, negative or missing price
SELECT COUNT(*) AS invalid_prices
FROM order_items
WHERE price <= 0 OR price IS NULL;

-- Items with a negative freight value
SELECT COUNT(*) AS negative_freight
FROM order_items
WHERE freight_value < 0;

-- Items whose order has no review
SELECT COUNT(*) AS products_without_rating
FROM order_items oi
LEFT JOIN order_reviews_full r ON oi.order_id = r.order_id
WHERE r.review_score IS NULL;


-- ============================================================
-- 06) Sellers: raw checks
-- ============================================================

-- Sellers with a missing city or state
SELECT seller_id
FROM sellers
WHERE seller_state IS NULL
   OR seller_city IS NULL;

-- Sellers per state
SELECT seller_state, COUNT(DISTINCT seller_id) AS seller_count
FROM sellers
GROUP BY seller_state
ORDER BY seller_count DESC;


-- ============================================================
-- 07) Customers: repeat buyers in the raw data
-- ============================================================

-- customer_id values with a delivered order.
-- customer_id changes with every order, so this is close to the number of delivered orders.
SELECT COUNT(DISTINCT customer_id) AS unique_customers_delivered
FROM orders
WHERE order_status = 'delivered';

-- Real customers (customer_unique_id) with a delivered order
SELECT COUNT(DISTINCT customer_unique_id) AS real_customers_with_orders
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE order_status = 'delivered'
);

-- Repeat customers: more than 1 delivered order
SELECT COUNT(*) AS returning_customers_raw
FROM (
    SELECT customer_unique_id
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) t;

-- Real customers that placed any order
SELECT COUNT(*) AS total_real_customers_raw
FROM (
    SELECT DISTINCT customer_unique_id
    FROM customers
    WHERE customer_id IN (SELECT customer_id FROM orders)
) t;

-- Repeat rate on the raw data, to compare with the retention view of phase 01
SELECT
    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM customers
     WHERE customer_id IN (SELECT customer_id FROM orders)) AS real_customers_raw,
    (SELECT COUNT(*)
     FROM (
         SELECT customer_unique_id
         FROM orders o
         JOIN customers c ON o.customer_id = c.customer_id
         WHERE o.order_status = 'delivered'
         GROUP BY customer_unique_id
         HAVING COUNT(*) > 1
     ) t) AS returning_raw,
    ROUND(
        (
            SELECT COUNT(*)
            FROM (
                SELECT customer_unique_id
                FROM orders o
                JOIN customers c ON o.customer_id = c.customer_id
                WHERE o.order_status = 'delivered'
                GROUP BY customer_unique_id
                HAVING COUNT(*) > 1
            ) t
        )::numeric
        /
        (SELECT COUNT(DISTINCT customer_unique_id)
         FROM customers
         WHERE customer_id IN (SELECT customer_id FROM orders))
    * 100, 2
    ) AS raw_retention_rate;


-- ============================================================
-- 08) Top customers and top sellers
-- ============================================================

-- Customers with the most delivered orders
SELECT customer_unique_id, COUNT(*) AS orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY customer_unique_id
ORDER BY orders DESC
LIMIT 20;

-- Sellers with the highest revenue (item prices, all order statuses)
SELECT seller_id, SUM(price) AS raw_revenue
FROM order_items
GROUP BY seller_id
ORDER BY raw_revenue DESC
LIMIT 20;


-- ============================================================
-- 09) Random sample of delivered orders (quick eyeball check)
-- ============================================================

SELECT *
FROM orders
WHERE order_status = 'delivered'
ORDER BY RANDOM()
LIMIT 15;
