-- ============================================================
-- Olist e-commerce analysis
-- Phase 04: reviews
-- File: 04_reviews_analysis.sql
-- Author: Claudio Matarrese
-- Tools: PostgreSQL, Power BI
-- ============================================================
-- What it does:
--   Reviews linked to clean delivered orders, sentiment flags, average rating by
--   category, state and delivery time, and the review KPIs (single row).
-- ============================================================


-- ============================================================
-- 04.1) Reviews base view (reviews of clean delivered orders)
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_base_v AS
SELECT
    r.review_id,
    r.order_id,
    ol.customer_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp,
    ol.order_purchase_timestamp,

    EXTRACT(EPOCH FROM (r.review_creation_date - ol.order_purchase_timestamp)) / 86400
        AS purchase_to_review_days,

    EXTRACT(EPOCH FROM (r.review_answer_timestamp - r.review_creation_date)) / 86400
        AS review_response_days

FROM order_reviews_full r
JOIN olist_orders_logistics_clean_v ol
  ON r.order_id = ol.order_id
WHERE ol.order_status = 'delivered';


-- ============================================================
-- 04.2) Clean reviews view
-- Positive = 4-5 stars, neutral = 3, negative = 1-2.
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_clean_v AS
SELECT
    review_id,
    order_id,
    customer_id,
    review_score,
    review_comment_title,
    review_comment_message,

    CASE WHEN review_score >= 4 THEN true ELSE false END AS is_positive,
    CASE WHEN review_score <= 2 THEN true ELSE false END AS is_negative,
    CASE WHEN review_score = 3 THEN true ELSE false END AS is_neutral,

    ROUND(purchase_to_review_days, 2) AS purchase_to_review_days,
    ROUND(review_response_days, 2)    AS review_response_days,

    CASE
        WHEN review_response_days IS NOT NULL
         AND review_response_days <= 2
        THEN true ELSE false
    END AS fast_response,

    CASE WHEN purchase_to_review_days <= 5 THEN true ELSE false END AS timely_review

FROM olist_reviews_base_v;


-- ============================================================
-- 04.3) Detail views
-- Average rating by category, customer state and delivery time
-- ============================================================

-- 04.3.1) Average rating by product category
-- Each order is given one category (DISTINCT ON keeps one row per order, with no sort rule),
-- so an order with items from several categories is counted once.
CREATE OR REPLACE VIEW olist_reviews_rating_by_category_v AS
WITH prod AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        product_category_name
    FROM olist_products_clean_v
)
SELECT
    p.product_category_name,
    AVG(r.review_score) AS avg_rating
FROM olist_reviews_clean_v r
JOIN prod p USING (order_id)
GROUP BY p.product_category_name;


-- 04.3.2) Average rating by customer state
CREATE OR REPLACE VIEW olist_reviews_rating_by_state_v AS
SELECT
    c.customer_state,
    AVG(r.review_score) AS avg_rating
FROM olist_reviews_clean_v r
JOIN customers c
  ON r.customer_id = c.customer_id
GROUP BY c.customer_state;


-- 04.3.3) Average rating by days from purchase to delivery
CREATE OR REPLACE VIEW olist_reviews_rating_by_delivery_time_v AS
SELECT
    ol.purchase_to_delivery_days,
    AVG(r.review_score) AS avg_rating
FROM olist_reviews_clean_v r
JOIN olist_orders_logistics_clean_v ol
  ON r.order_id = ol.order_id
GROUP BY ol.purchase_to_delivery_days
ORDER BY ol.purchase_to_delivery_days;


-- ============================================================
-- 04.4) Review KPIs (single row)
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_kpi_v AS
SELECT
    AVG(review_score) AS avg_rating,

	SUM(CASE WHEN is_positive THEN 1 ELSE 0 END)::numeric / COUNT(*) AS pct_positive,
	SUM(CASE WHEN is_negative THEN 1 ELSE 0 END)::numeric / COUNT(*) AS pct_negative,
	SUM(CASE WHEN is_neutral  THEN 1 ELSE 0 END)::numeric / COUNT(*) AS pct_neutral,

    AVG(purchase_to_review_days) AS avg_purchase_to_review_days,
    AVG(review_response_days)    AS avg_review_response_days,

	SUM(CASE WHEN fast_response THEN 1 ELSE 0 END)::numeric / COUNT(*) AS pct_fast_response,
	SUM(CASE WHEN timely_review THEN 1 ELSE 0 END)::numeric / COUNT(*) AS pct_timely_review,

    COUNT(*) AS total_reviews

FROM olist_reviews_clean_v;


-- ============================================================
-- 04.5) Global review KPIs (single row)
-- Same columns as 04.4, under the _global_v name that the KPI master uses.
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_kpi_global_v AS
SELECT
    avg_rating,
    pct_positive,
    pct_negative,
    pct_neutral,
    avg_purchase_to_review_days,
    avg_review_response_days,
    pct_fast_response,
    pct_timely_review,
    total_reviews
FROM olist_reviews_kpi_v;