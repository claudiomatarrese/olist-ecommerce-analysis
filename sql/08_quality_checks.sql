-- ============================================================
-- Olist e-commerce analysis
-- Phase 08: quality checks
-- File: 08_quality_checks.sql
-- Author: Claudio Matarrese
-- Tools: PostgreSQL, Power BI
-- ============================================================
-- What it does:
--   Final checks on the views of every phase (customers, orders, logistics, products,
--   payments, reviews, sellers). Only SELECTs, no views are created.
--   It is optional: the dashboard does not depend on it.
-- ============================================================


-- ============================================================
-- 08.1) Customers and orders
-- ============================================================

-- Orders (raw)
SELECT COUNT(*) AS total_orders_raw
FROM orders;

-- Delivered orders
SELECT COUNT(*) AS total_orders_delivered
FROM orders
WHERE order_status = 'delivered';

-- Customers (raw)
SELECT COUNT(*) AS total_customers_raw
FROM customers;

-- Orders without a customer_id (should be 0)
SELECT COUNT(*) AS orders_with_null_customer_id
FROM orders
WHERE customer_id IS NULL;


-- ============================================================
-- 08.2) Logistics (phase 02)
-- ============================================================

-- Orders flagged with date errors
SELECT COUNT(*) AS orders_with_temporal_errors
FROM olist_orders_logistics_v
WHERE has_temporal_error = true;

-- Delivered to the customer before the carrier pick-up
SELECT COUNT(*) AS delivery_before_shipment
FROM olist_orders_logistics_v
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- Negative delivery time
SELECT COUNT(*) AS negative_lead_time
FROM olist_orders_logistics_v
WHERE purchase_to_delivery_days < 0;

-- Delivered more than 30 days before the estimated date
SELECT COUNT(*) AS extreme_negative_delays
FROM olist_orders_logistics_v
WHERE delivery_delay_days < -30;


-- ============================================================
-- 08.3) Reviews (phase 04)
-- ============================================================

-- Answer sent before the review was created (should be 0)
SELECT COUNT(*) AS negative_response_time
FROM olist_reviews_clean_v
WHERE review_response_days < 0;

-- Reviews in the clean set
SELECT COUNT(*) AS total_valid_reviews
FROM olist_reviews_clean_v;

-- Reviews per score
SELECT review_score, COUNT(*) AS review_count
FROM olist_reviews_clean_v
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 08.4) Products (phase 03)
-- ============================================================

-- Items with a price of zero or below
SELECT COUNT(*) AS invalid_prices
FROM olist_products_clean_v
WHERE price <= 0;

-- Items with a negative freight value
SELECT COUNT(*) AS negative_freight
FROM olist_products_clean_v
WHERE freight_value < 0;

-- Items whose order has no review
SELECT COUNT(*) AS products_without_rating
FROM olist_products_clean_v
WHERE review_score IS NULL;


-- ============================================================
-- 08.5) Sellers (phase 06)
-- ============================================================

-- Top 30 sellers by revenue
SELECT seller_id, SUM(revenue) AS raw_revenue
FROM olist_sellers_clean_v
GROUP BY seller_id
ORDER BY raw_revenue DESC
LIMIT 30;

-- Negative delivery time (sellers view)
SELECT COUNT(*) AS negative_lead_time_seller
FROM olist_sellers_clean_v
WHERE purchase_to_delivery_days < 0;

-- Sellers per state
SELECT seller_state, COUNT(DISTINCT seller_id) AS seller_count
FROM olist_sellers_clean_v
GROUP BY seller_state
ORDER BY seller_count DESC;


-- ============================================================
-- 08.6) Retention (phase 01)
-- ============================================================

-- Customers (customer_unique_id) with at least 1 delivered order
SELECT COUNT(DISTINCT customer_unique_id) AS unique_real_customers_delivered
FROM olist_per_customer_delivered_v;

-- Same query as the one above, kept as a duplicate check
SELECT COUNT(DISTINCT customer_unique_id) AS real_customers_with_orders
FROM olist_per_customer_delivered_v;

-- Repeat customers (more than 1 order)
SELECT COUNT(*) AS returning_customers_raw
FROM olist_customer_retention_v
WHERE total_orders > 1;

-- Repeat rate from the retention view
SELECT
    COUNT(DISTINCT customer_unique_id) AS total_customers_raw,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS returning_customers_raw,
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)::numeric
        / COUNT(DISTINCT customer_unique_id),
        2
    ) AS raw_retention_rate_percent
FROM olist_customer_retention_v;

-- Customers with the most orders
SELECT customer_unique_id, total_orders AS orders
FROM olist_customer_retention_v
ORDER BY total_orders DESC
LIMIT 30;


-- ============================================================
-- 08.7) Sellers: top 10 by revenue
-- ============================================================

SELECT seller_id, raw_revenue
FROM (
    SELECT seller_id, SUM(revenue) AS raw_revenue
    FROM olist_sellers_clean_v
    GROUP BY seller_id
) t
ORDER BY raw_revenue DESC
LIMIT 10;


-- ============================================================
-- 08.8) Random sample of delivered orders (quick eyeball check)
-- ============================================================

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
ORDER BY random()
LIMIT 15;