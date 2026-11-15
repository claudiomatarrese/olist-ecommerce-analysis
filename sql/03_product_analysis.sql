-- ============================================================
-- Olist e-commerce analysis
-- Phase 03: products and categories
-- File: 03_product_analysis.sql
-- Author: Claudio Matarrese
-- Tools: PostgreSQL, Power BI
-- ============================================================


-- ============================================================
-- 03.1) Products base view (one row per item sold)
-- ============================================================

CREATE OR REPLACE VIEW olist_products_base_v AS
SELECT
    oi.order_id,
    oi.product_id,
    -- Category name in English. If the category is not in the translation table, keep the
    -- original name. If the product has no category at all, use 'Unknown'.
    COALESCE(
		t.product_category_name_english,
		p.product_category_name,
		'Unknown'
	)::varchar AS product_category_name,
    oi.price,
    oi.freight_value,
    oi.price AS revenue,

    -- Review score of the order (highest score if the order has more than one review).
    -- The score is repeated on every item of the order, so orders with many items
    -- weigh more in item-level averages.
    (
        SELECT MAX(review_score)
        FROM order_reviews r
        WHERE r.order_id = oi.order_id
    ) AS review_score,

    o.order_purchase_timestamp,

    lg.purchase_to_carrier_days,
    lg.carrier_to_delivery_days,
    lg.purchase_to_delivery_days,
    lg.delivery_delay_days,
    lg.is_delayed,
    lg.is_on_time

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
   AND o.order_status = 'delivered'
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
JOIN olist_orders_logistics_clean_v lg
    ON oi.order_id = lg.order_id;


-- ============================================================
-- 03.2) Clean products view (rounded values and flags)
-- ============================================================

CREATE OR REPLACE VIEW olist_products_clean_v AS
SELECT
    order_id,
    product_id,
    product_category_name,

    ROUND(price, 2)         AS price,
    ROUND(freight_value, 2) AS freight_value,
    ROUND(revenue, 2)       AS revenue,

    review_score,
    CASE WHEN review_score >= 4 THEN true ELSE false END AS is_high_rating,

    ROUND(purchase_to_carrier_days, 2)  AS purchase_to_carrier_days,
    ROUND(carrier_to_delivery_days, 2)  AS carrier_to_delivery_days,
    ROUND(purchase_to_delivery_days, 2) AS purchase_to_delivery_days,
    ROUND(delivery_delay_days, 2)       AS delivery_delay_days,

    is_delayed,
    is_on_time,

    CASE WHEN price > 100 THEN true ELSE false END AS is_expensive,
    CASE WHEN purchase_to_delivery_days < 7 THEN true ELSE false END AS is_fast_delivery

FROM olist_products_base_v;


-- ============================================================
-- 03.3) KPIs by category
-- ============================================================

CREATE OR REPLACE VIEW olist_products_kpi_v AS
SELECT
    product_category_name,

    SUM(revenue)      AS total_revenue,
    AVG(price)        AS avg_price,
    COUNT(order_id)   AS total_products_sold,

    AVG(review_score) AS avg_rating,
    100.0 * SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END) / COUNT(*) AS pct_high_rating,

    AVG(purchase_to_delivery_days) AS avg_lead_time_days,
    AVG(delivery_delay_days)       AS avg_delay_days,

    100.0 * SUM(is_on_time) / COUNT(*)  AS pct_on_time,
	100.0 * SUM(is_delayed) / COUNT(*)  AS pct_delayed,		

    MIN(price) AS min_price,
    MAX(price) AS max_price

FROM olist_products_clean_v
GROUP BY product_category_name
ORDER BY total_revenue DESC;


-- ============================================================
-- 03.4) Global product KPIs (single row)
-- These are averages of the category averages, not weighted by items sold.
-- The dashboard cards are calculated on item rows, so they can differ slightly.
-- ============================================================

CREATE OR REPLACE VIEW olist_products_kpi_global_v AS
SELECT
    SUM(total_revenue)     AS total_revenue,
    AVG(avg_price)         AS avg_product_price,
    AVG(avg_rating)        AS avg_product_rating,
    AVG(avg_lead_time_days) AS avg_product_lead_time_days,
    AVG(avg_delay_days)     AS avg_product_delay_days
FROM olist_products_kpi_v;
