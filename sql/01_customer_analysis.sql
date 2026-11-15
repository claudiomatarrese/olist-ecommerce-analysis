-- ============================================================
-- Olist e-commerce analysis
-- Phase 01: customers (retention and purchase frequency)
-- File: 01_customer_analysis.sql
-- Author: Claudio Matarrese
-- Tools: PostgreSQL, Power BI
-- ============================================================
-- What it does:
--   Builds the customer views: delivered orders per customer, time between orders,
--   one row per customer with a repeat flag, and a single-row retention summary.
--   Customers are identified by customer_unique_id (customer_id changes on every order).
--   These views use all delivered orders, not only the clean set from phase 02.
-- ============================================================


-- ============================================================
-- 01.1) Delivered orders (base)
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
-- 01.2) Delivered orders with the real customer id (customer_unique_id)
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
-- 01.3) Previous order date for each customer (LAG)
-- The gap between two orders is measured on timestamps, so two orders placed on the same
-- day count as two separate purchases.
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
-- 01.4) One row per customer: number of orders, repeat flag, first purchase,
-- average days between orders
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
-- 01.5) Retention summary (single row)
-- The 90-day, 60-day, 30-day and 365-day rules below are measured from the latest order date in the data.
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
    -- All customers with a delivered order
    (SELECT COUNT(DISTINCT customer_unique_id)
       FROM olist_per_customer_delivered_v) AS total_customers,

    -- Repeat customers (more than 1 delivered order)
    (SELECT COUNT(*)
       FROM olist_customer_retention_v
       WHERE is_returning_customer = true) AS returning_customers,

    -- Repeat rate (%)
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

    -- Average days between orders
    (SELECT ROUND(AVG(avg_purchase_frequency_days), 2)
       FROM olist_customer_retention_v) AS avg_purchase_frequency_days,

    -- Active customers (at least 1 delivered order, so same as the total)
    (SELECT COUNT(DISTINCT customer_unique_id)
       FROM olist_per_customer_delivered_v) AS active_customers,

    -- Churned: last order more than 90 days before the latest date in the data
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.last_order < a.as_of_date - INTERVAL '90 days') AS churned_customers,

    -- Inactive: last order more than 365 days before the latest date in the data
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.last_order < a.as_of_date - INTERVAL '365 days') AS inactive_12_months,

    -- At risk: last order between 60 and 90 days before the latest date in the data
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.last_order BETWEEN
           a.as_of_date - INTERVAL '90 days'
       AND a.as_of_date - INTERVAL '60 days') AS at_risk_customers,

    -- New: first order in the 30 days before the latest date in the data
    (SELECT COUNT(*)
       FROM last_orders lo
       CROSS JOIN as_of a
     WHERE lo.first_order > a.as_of_date - INTERVAL '30 days') AS new_customers;