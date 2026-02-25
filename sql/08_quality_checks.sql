-- ============================================================
-- PROJECT: OLIST E-COMMERCE ANALYSIS
-- PHASE 08 – FULL QUALITY CHECKS
-- FILE: 08_quality_checks.sql
-- AUTHOR: Claudio Matarrese
-- TOOLS: PostgreSQL + Power BI
-- ============================================================
-- PURPOSE:
--   Quality checks across all phases: customers, orders, logistics, products,
--   payments, reviews, and sellers.
--   No views are created. Diagnostic SELECT statements only.
-- ============================================================


-- ============================================================
-- 08.1) CUSTOMERS / ORDERS CHECKS
-- ============================================================

-- Total raw orders
SELECT COUNT(*) AS total_orders_raw
FROM orders;

-- Total delivered orders
SELECT COUNT(*) AS total_orders_delivered
FROM orders
WHERE order_status = 'delivered';

-- Total raw customers
SELECT COUNT(*) AS total_customers_raw
FROM customers;

-- Check for anomalous NULL customer_id (should not happen)
SELECT COUNT(*) AS orders_with_null_customer_id
FROM orders
WHERE customer_id IS NULL;


-- ============================================================
-- 08.2) LOGISTICS CHECKS (Phase 02)
-- ============================================================

-- Temporal errors in logistics
SELECT COUNT(*) AS orders_with_temporal_errors
FROM olist_orders_logistics_v
WHERE has_temporal_error = true;

-- Delivery before shipment
SELECT COUNT(*) AS delivery_before_shipment
FROM olist_orders_logistics_v
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- Negative lead time
SELECT COUNT(*) AS negative_lead_time
FROM olist_orders_logistics_v
WHERE purchase_to_delivery_days < 0;

-- Extreme negative delays (< -30 days)
SELECT COUNT(*) AS extreme_negative_delays
FROM olist_orders_logistics_v
WHERE delivery_delay_days < -30;


-- ============================================================
-- 08.3) REVIEW CHECKS (Phase 04)
-- ============================================================

-- Negative response time (<0)
SELECT COUNT(*) AS negative_response_time
FROM olist_reviews_clean_v
WHERE review_response_days < 0;

-- Total valid reviews
SELECT COUNT(*) AS total_valid_reviews
FROM olist_reviews_clean_v;

-- Review score distribution
SELECT review_score, COUNT(*) AS review_count
FROM olist_reviews_clean_v
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 08.4) PRODUCT CHECKS (Phase 03)
-- ============================================================

-- Negative or zero prices
SELECT COUNT(*) AS invalid_prices
FROM olist_products_clean_v
WHERE price <= 0;

-- Negative freight values
SELECT COUNT(*) AS negative_freight
FROM olist_products_clean_v
WHERE freight_value < 0;

-- Products without rating (possible missing review)
SELECT COUNT(*) AS products_without_rating
FROM olist_products_clean_v
WHERE review_score IS NULL;


-- ============================================================
-- 08.5) SELLER CHECKS (Phase 06)
-- ============================================================

-- Sellers with highest revenue (top 30 diagnostic)
SELECT seller_id, SUM(revenue) AS raw_revenue
FROM olist_sellers_clean_v
GROUP BY seller_id
ORDER BY raw_revenue DESC
LIMIT 30;

-- Negative delivery days
SELECT COUNT(*) AS negative_lead_time_seller
FROM olist_sellers_clean_v
WHERE purchase_to_delivery_days < 0;

-- Sellers per state
SELECT seller_state, COUNT(DISTINCT seller_id) AS seller_count
FROM olist_sellers_clean_v
GROUP BY seller_state
ORDER BY seller_count DESC;


-- ============================================================
-- 08.6) RETENTION CHECKS (Phase 01)
-- ============================================================

-- Unique real customers with at least 1 delivered order (customer_unique_id)
SELECT COUNT(DISTINCT customer_unique_id) AS unique_real_customers_delivered
FROM olist_per_customer_delivered_v;

-- Real customers (unique_id) with delivered orders
SELECT COUNT(DISTINCT customer_unique_id) AS real_customers_with_orders
FROM olist_per_customer_delivered_v;

-- Returning customers raw (>1 order)
SELECT COUNT(*) AS returning_customers_raw
FROM olist_customer_retention_v
WHERE total_orders > 1;

-- Raw retention rate (diagnostic)
SELECT
    COUNT(DISTINCT customer_unique_id) AS total_customers_raw,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS returning_customers_raw,
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)::numeric
        / COUNT(DISTINCT customer_unique_id),
        2
    ) AS raw_retention_rate_percent
FROM olist_customer_retention_v;

-- Top customers by number of orders (diagnostic)
SELECT customer_unique_id, total_orders AS orders
FROM olist_customer_retention_v
ORDER BY total_orders DESC
LIMIT 30;


-- ============================================================
-- 08.7) OVERALL SELLER CHECKS (Phase 06)
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
-- 08.8) RANDOM DELIVERED ORDERS CHECK (SANITY CHECK)
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