-- ============================================================
-- PROJECT: OLIST E-COMMERCE ANALYSIS
-- PHASE 02 – ORDERS & LOGISTICS ANALYSIS
-- FILE: 02_orders_logistics.sql
-- AUTHOR: Claudio Matarrese
-- TOOLS: PostgreSQL + Power BI
-- ============================================================


-- ============================================================
-- 02.0) BASE ORDERS VIEW
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_base_v AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders;


-- ============================================================
-- 02.1) BASE LOGISTICS VIEW (RAW CALCULATIONS)
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_logistics_v AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    (EXTRACT(EPOCH FROM order_delivered_carrier_date - order_purchase_timestamp) / 86400)
        AS purchase_to_carrier_days,

    (EXTRACT(EPOCH FROM order_delivered_customer_date - order_delivered_carrier_date) / 86400)
        AS carrier_to_delivery_days,

    (EXTRACT(EPOCH FROM order_delivered_customer_date - order_purchase_timestamp) / 86400)
        AS purchase_to_delivery_days,

    (EXTRACT(EPOCH FROM order_delivered_customer_date - order_estimated_delivery_date) / 86400)
        AS delivery_delay_days,

    (EXTRACT(EPOCH FROM order_approved_at - order_purchase_timestamp) / 86400)
        AS purchase_to_approval_days,

	CASE
		WHEN (EXTRACT(EPOCH FROM order_delivered_customer_date - order_estimated_delivery_date) / 86400) >= 1
		THEN 1 ELSE 0
	END AS is_delayed,

	 CASE
		WHEN (EXTRACT(EPOCH FROM order_delivered_customer_date - order_estimated_delivery_date) / 86400) < 1
		THEN 1 ELSE 0
	END AS is_on_time,	

    CASE
        WHEN order_purchase_timestamp > order_approved_at
          OR order_approved_at > order_delivered_carrier_date
          OR order_purchase_timestamp > order_delivered_carrier_date
          OR order_delivered_customer_date < order_delivered_carrier_date
          OR order_delivered_customer_date < order_purchase_timestamp
          OR order_estimated_delivery_date < order_purchase_timestamp
          OR order_estimated_delivery_date < order_delivered_carrier_date
        THEN true ELSE false
    END AS has_temporal_error

FROM olist_orders_base_v;


-- ============================================================
-- 02.2) CLEAN LOGISTICS VIEW (BUSINESS-READY)
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_logistics_clean_v AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    ROUND(purchase_to_carrier_days, 2)    AS purchase_to_carrier_days,
    ROUND(carrier_to_delivery_days, 2)    AS carrier_to_delivery_days,
    ROUND(purchase_to_delivery_days, 2)   AS purchase_to_delivery_days,
    ROUND(delivery_delay_days, 2)         AS delivery_delay_days,
    ROUND(purchase_to_approval_days, 2)   AS purchase_to_approval_days,

    is_delayed,
    is_on_time,
    has_temporal_error

FROM olist_orders_logistics_v
WHERE has_temporal_error = false
  AND order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- ============================================================
-- 02.3) LOGISTICS KPIs (PRODUCTION)
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_kpi_v AS
SELECT
    COUNT(*) AS total_orders,

	SUM(is_on_time)  AS on_time_orders,
    SUM(is_delayed)  AS delayed_orders,

    ROUND(AVG(purchase_to_delivery_days), 2)   AS avg_lead_time_days,
    ROUND(AVG(purchase_to_carrier_days), 2)    AS avg_handling_time_days,
    ROUND(AVG(carrier_to_delivery_days), 2)    AS avg_shipping_time_days,
    ROUND(AVG(purchase_to_approval_days), 2)   AS avg_approval_time_days,

    ROUND(100.0 * SUM(is_on_time)::NUMERIC / COUNT(*), 2) 
		AS on_time_rate_percent,

    ROUND(100.0 * SUM(is_delayed)::NUMERIC / COUNT(*), 2)
        AS delayed_rate_percent

FROM olist_orders_logistics_clean_v
WHERE order_status = 'delivered';


-- ============================================================
-- 02.4) GEOGRAPHIC KPIs – CUSTOMER STATE
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_geo_customer_v AS
SELECT
    c.customer_state,
    ROUND(AVG(o.purchase_to_delivery_days), 2) AS avg_lead_time_days,
    ROUND(AVG(o.delivery_delay_days), 2)       AS avg_delay_days,
    ROUND(
        100.0 * SUM(o.is_delayed)::NUMERIC / COUNT(*),
        2
    ) AS delayed_rate_percent
FROM olist_orders_logistics_clean_v o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state;


-- ============================================================
-- 02.5) GEOGRAPHIC KPIs – SELLER STATE
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_geo_seller_v AS
WITH order_seller AS (
    SELECT DISTINCT
        o.order_id,
        s.seller_state,
        o.purchase_to_delivery_days,
        o.delivery_delay_days
    FROM olist_orders_logistics_clean_v o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
)
SELECT
    seller_state,
    ROUND(AVG(purchase_to_delivery_days), 2) AS avg_lead_time_days,
    ROUND(AVG(delivery_delay_days), 2)       AS avg_delay_days
FROM order_seller
GROUP BY seller_state;


-- ============================================================
-- 02.6) LOGISTICS MATRIX: SELLER → CUSTOMER
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_seller_customer_matrix_v AS
WITH order_seller_customer AS (
    SELECT DISTINCT
        o.order_id,
        s.seller_state,
        c.customer_state,
        o.delivery_delay_days
    FROM olist_orders_logistics_clean_v o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    JOIN customers c ON o.customer_id = c.customer_id
)
SELECT
    seller_state,
    customer_state,
    ROUND(AVG(delivery_delay_days), 2) AS avg_delay_days
FROM order_seller_customer
GROUP BY seller_state, customer_state
ORDER BY seller_state, customer_state;
