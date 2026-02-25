-- ============================================================
-- PROJECT: OLIST E-COMMERCE ANALYSIS
-- PHASE 01 – CUSTOMER ANALYSIS (RETENTION & FREQUENCY)
-- FILE: 01_customer_analysis.sql
-- AUTHOR: Claudio Matarrese
-- TOOLS: PostgreSQL + Power BI
-- ============================================================
-- DESCRIPTION:
--   Construction of customer views: delivered base layer, per-customer aggregation, retention calculation, purchase frequency and final KPIs.
--   Business-ready output.
-- ============================================================


-- ============================================================
-- 01.1) DELIVERED ORDERS BASE (RAW → BUSINESS LAYER)
-- ============================================================

CREATE OR REPLACE VIEW olist_delivered_base_v AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_customer_date
FROM orders o
WHERE o.order_status = 'delivered';


-- ============================================================
-- 01.2) CUSTOMERS WITH DELIVERED ORDERS ONLY
-- ============================================================

CREATE OR REPLACE VIEW olist_per_customer_delivered_v AS
SELECT
    c.customer_unique_id,
    d.customer_id,
    d.order_id,
    d.order_purchase_timestamp
FROM olist_delivered_base_v d
JOIN customers c
  ON d.customer_id = c.customer_id;


-- ============================================================
-- 01.3) ORDER LAG → CALCULATING INTERVALS BETWEEN PURCHASES
-- ============================================================

CREATE OR REPLACE VIEW olist_order_lag_v AS
SELECT
    customer_unique_id,
    order_id,
    order_purchase_timestamp,
    LAG(order_purchase_timestamp)
        OVER (PARTITION BY customer_unique_id
              ORDER BY order_purchase_timestamp) AS previous_order
FROM olist_per_customer_delivered_v;


-- ============================================================
-- 01.4) RETENTION – FREQUENCY & STATISTICS CALCULATION
-- ============================================================

CREATE OR REPLACE VIEW olist_customer_retention_v AS
WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),

first_purchase AS (
    SELECT
        customer_unique_id,
        MIN(order_purchase_timestamp) AS first_purchase_timestamp
    FROM delivered_orders
    GROUP BY customer_unique_id
),

order_count AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM delivered_orders
    GROUP BY customer_unique_id
),

purchase_frequency AS (
    SELECT
        customer_unique_id,
        ROUND(
            AVG(EXTRACT(EPOCH FROM (order_purchase_timestamp - previous_order)) / 86400)::numeric,
        2) AS avg_purchase_frequency_days
    FROM olist_order_lag_v
    WHERE previous_order IS NOT NULL
    GROUP BY customer_unique_id
)

SELECT
    oc.customer_unique_id,
    oc.total_orders,
    (oc.total_orders > 1) AS is_returning_customer,
    CASE WHEN oc.total_orders > 1 THEN 1 ELSE 0 END AS is_returning_flag,
    fp.first_purchase_timestamp,
    pf.avg_purchase_frequency_days
FROM order_count oc
JOIN first_purchase fp
    ON oc.customer_unique_id = fp.customer_unique_id
LEFT JOIN purchase_frequency pf
    ON oc.customer_unique_id = pf.customer_unique_id;


-- ============================================================
-- 01.5) RETENTION KPIs – FINAL VIEW
-- ============================================================

CREATE OR REPLACE VIEW olist_kpi_retention_v AS
WITH as_of AS (
    SELECT MAX(order_purchase_timestamp) AS as_of_date
    FROM olist_per_customer_delivered_v
),
last_orders AS (
    SELECT
        customer_unique_id,
        MIN(order_purchase_timestamp) AS first_order,
        MAX(order_purchase_timestamp) AS last_order
    FROM olist_per_customer_delivered_v
    GROUP BY customer_unique_id
)
SELECT
    -- Total real customers (unique_id)
    (SELECT COUNT(DISTINCT customer_unique_id)
       FROM olist_per_customer_delivered_v) AS total_customers,

    -- Returning customers (>1 delivered order)
    (SELECT COUNT(*)
       FROM olist_customer_retention_v
       WHERE is_returning_customer = true) AS returning_customers,

    -- Retention rate (%)
    ROUND(
        (
            SELECT COUNT(*)::numeric
            FROM olist_customer_retention_v
            WHERE is_returning_customer = true
        )
        /
        (SELECT COUNT(DISTINCT customer_unique_id)
           FROM olist_per_customer_delivered_v)
    * 100, 2) AS retention_rate_percent,

    -- Average purchase frequency (days)
    (SELECT ROUND(AVG(avg_purchase_frequency_days), 2)
       FROM olist_customer_retention_v) AS avg_purchase_frequency_days,

    -- Active customers (at least 1 delivered order)
    (SELECT COUNT(DISTINCT customer_unique_id)
       FROM olist_per_customer_delivered_v) AS active_customers,

    -- Churned customers (no orders in last 90 days)
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.last_order < a.as_of_date - INTERVAL '90 days') AS churned_customers,

    -- Customers inactive in last 12 months
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.last_order < a.as_of_date - INTERVAL '365 days') AS inactive_12_months,

    -- At-risk customers (no order between 60 and 90 days)
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.last_order BETWEEN
           a.as_of_date - INTERVAL '90 days'
       AND a.as_of_date - INTERVAL '60 days') AS at_risk_customers,

    -- New customers (first order in last 30 days)
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.first_order > a.as_of_date - INTERVAL '30 days') AS new_customers;