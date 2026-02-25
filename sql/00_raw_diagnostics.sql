-- ============================================================
-- PROJECT: OLIST E-COMMERCE ANALYSIS
-- FILE: 00_raw_diagnostics.sql
-- PURPOSE: Preliminary quality checks and raw diagnostic calculations
-- AUTHOR: Claudio Matarrese
-- ============================================================


-- ============================================================
-- 01) ORDERS: BASIC COUNTS
-- ============================================================

-- Total raw orders
SELECT COUNT(*) AS total_orders_raw
FROM orders;

-- Total delivered orders
SELECT COUNT(*) AS total_orders_delivered
FROM orders
WHERE order_status = 'delivered';


-- ============================================================
-- 02) CUSTOMERS: DUPLICATES & DATA QUALITY
-- ============================================================

-- Total raw customers
SELECT COUNT(*) AS total_customers_raw
FROM customers;

-- Check for missing or anomalous customer_unique_id
SELECT customer_id, COUNT(*)
FROM customers
WHERE customer_unique_id IS NULL
GROUP BY customer_id;


-- ============================================================
-- 03) ORDERS: RAW TEMPORAL CHECKS
-- ============================================================

-- 03.1) Orders with raw temporal inconsistencies
SELECT COUNT(*) AS orders_with_temporal_errors
FROM orders
WHERE order_purchase_timestamp > order_approved_at
   OR order_approved_at > order_delivered_carrier_date
   OR order_delivered_customer_date < order_delivered_carrier_date
   OR order_delivered_customer_date < order_purchase_timestamp;

-- 03.2) Delivery before shipment
SELECT COUNT(*) AS delivery_before_shipment
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- 03.3) Negative raw lead time
SELECT COUNT(*) AS negative_lead_time
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 03.4) Extremely negative delays (dataset anomalies)
SELECT COUNT(*) AS extreme_negative_delays
FROM orders
WHERE EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date)) / 86400 < -30;


-- ============================================================
-- 04) REVIEWS: RAW DIAGNOSTICS
-- ============================================================

-- Negative response timing (response before creation)
SELECT COUNT(*) AS negative_response_timing
FROM order_reviews_full
WHERE review_answer_timestamp < review_creation_date;

-- Total valid reviews
SELECT COUNT(*) AS total_valid_reviews
FROM order_reviews_full;

-- Review score distribution
SELECT review_score, COUNT(*) AS review_count
FROM order_reviews_full
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 05) PRODUCTS: RAW DATA QUALITY
-- ============================================================

-- Negative or null prices
SELECT COUNT(*) AS invalid_prices
FROM order_items
WHERE price <= 0 OR price IS NULL;

-- Negative freight values
SELECT COUNT(*) AS negative_freight
FROM order_items
WHERE freight_value < 0;

-- Products without rating (later populated via JOIN)
SELECT COUNT(*) AS products_without_rating
FROM order_items oi
LEFT JOIN order_reviews_full r ON oi.order_id = r.order_id
WHERE r.review_score IS NULL;


-- ============================================================
-- 06) SELLERS: RAW QUALITY STATUS
-- ============================================================

-- Sellers with missing location values
SELECT seller_id
FROM sellers
WHERE seller_state IS NULL
   OR seller_city IS NULL;

-- Number of sellers per state
SELECT seller_state, COUNT(DISTINCT seller_id) AS seller_count
FROM sellers
GROUP BY seller_state
ORDER BY seller_count DESC;


-- ============================================================
-- 07) CUSTOMERS: RAW RETENTION CHECK
-- ============================================================

-- Unique customers with delivered orders
SELECT COUNT(DISTINCT customer_id) AS unique_customers_delivered
FROM orders
WHERE order_status = 'delivered';

-- Real customers (unique_id)
SELECT COUNT(DISTINCT customer_unique_id) AS real_customers_with_orders
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE order_status = 'delivered'
);

-- Returning customers (raw) = more than 1 delivered order
SELECT COUNT(*) AS returning_customers_raw
FROM (
    SELECT customer_unique_id
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) t;

-- Total real customers (raw)
SELECT COUNT(*) AS total_real_customers_raw
FROM (
    SELECT DISTINCT customer_unique_id
    FROM customers
    WHERE customer_id IN (SELECT customer_id FROM orders)
) t;

-- Raw vs final retention diagnostic
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
-- 08) TOP CUSTOMERS & TOP SELLERS (RAW)
-- ============================================================

-- Top customers (raw)
SELECT customer_unique_id, COUNT(*) AS orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY customer_unique_id
ORDER BY orders DESC
LIMIT 20;

-- Top sellers by raw revenue
SELECT seller_id, SUM(price) AS raw_revenue
FROM order_items
GROUP BY seller_id
ORDER BY raw_revenue DESC
LIMIT 20;


-- ============================================================
-- 09) RANDOM ORDER SAMPLE CHECK (RAW)
-- ============================================================

SELECT *
FROM orders
WHERE order_status = 'delivered'
ORDER BY RANDOM()
LIMIT 15;
