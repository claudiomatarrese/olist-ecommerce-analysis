-- ============================================================
-- PROJECT: OLIST E-COMMERCE ANALYSIS
-- PHASE 06 – SELLER ANALYSIS
-- FILE: 06_seller_analysis.sql
-- AUTHOR: Claudio Matarrese
-- TOOLS: PostgreSQL + Power BI
-- ============================================================


-- ============================================================
-- 06.1) SELLERS BASE VIEW
-- ============================================================
-- Grain: 1 row = 1 product item sold by a seller.

CREATE OR REPLACE VIEW olist_sellers_base_v AS
SELECT
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,

    oi.order_id,
    oi.product_id,
    oi.price,
    oi.freight_value,
    oi.price AS revenue,

    o.order_purchase_timestamp,

    lg.purchase_to_carrier_days,
    lg.carrier_to_delivery_days,
    lg.purchase_to_delivery_days,
    lg.delivery_delay_days,
    lg.is_delayed,
    lg.is_on_time,

    r.review_score

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
   AND o.order_status = 'delivered'
JOIN sellers s
    ON oi.seller_id = s.seller_id
JOIN olist_orders_logistics_clean_v lg
    ON oi.order_id = lg.order_id
LEFT JOIN olist_reviews_clean_v r
    ON oi.order_id = r.order_id;


-- ============================================================
-- 06.2) CLEAN SELLERS VIEW
-- ============================================================

CREATE OR REPLACE VIEW olist_sellers_clean_v AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,

    order_id,
    product_id,

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
    is_on_time

FROM olist_sellers_base_v;


-- ============================================================
-- 06.3) SELLER KPIs (ONE ROW PER SELLER)
-- ============================================================

CREATE OR REPLACE VIEW olist_sellers_kpi_v AS
SELECT
    seller_id,
    seller_city,
    seller_state,

    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*)                 AS total_items_sold,

    SUM(revenue) AS total_revenue,
    AVG(price)   AS avg_price,

    AVG(review_score) AS avg_rating,
    100.0 * SUM(CASE WHEN is_high_rating THEN 1 ELSE 0 END) / COUNT(*) AS pct_high_rating,

    AVG(purchase_to_delivery_days) AS avg_lead_time_days,
    AVG(delivery_delay_days)       AS avg_delay_days,

    100.0 * SUM(is_on_time) / COUNT(*)  AS pct_on_time,
	100.0 * SUM(is_delayed) / COUNT(*)  AS pct_delayed

FROM olist_sellers_clean_v
GROUP BY seller_id, seller_city, seller_state
ORDER BY total_revenue DESC;


-- ============================================================
-- 06.4) GLOBAL SELLER KPIs (SINGLE ROW)
-- ============================================================

CREATE OR REPLACE VIEW olist_sellers_kpi_global_v AS
SELECT
    SUM(total_revenue)        AS sellers_total_revenue,
    AVG(avg_rating)           AS sellers_avg_rating,
    AVG(avg_lead_time_days)   AS sellers_avg_lead_time_days,
    AVG(avg_delay_days)       AS sellers_avg_delay_days,
    SUM(total_orders)         AS sellers_total_orders,
    SUM(total_items_sold)     AS sellers_total_items_sold
FROM olist_sellers_kpi_v;