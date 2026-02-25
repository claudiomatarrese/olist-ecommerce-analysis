-- ============================================================
-- PROJECT: OLIST E-COMMERCE ANALYSIS
-- PHASE 07 – KPI MASTER DASHBOARD
-- FILE: 07_kpi_master.sql
-- AUTHOR: Claudio Matarrese
-- TOOLS: PostgreSQL + Power BI
-- ============================================================
-- DESCRIPTION:
--   This script defines:
--   - Global Delivered Orders / Logistics KPI view
--   - Final KPI Master view, combining all global KPI views into a single output (Retention, Products, Payments, Sellers are referenced from their phase scripts).
-- ============================================================


-- ============================================================
-- 07.1) GLOBAL DELIVERED ORDERS / LOGISTICS KPIs
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_delivered_kpi_global_v AS
SELECT
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    (
        COUNT(DISTINCT o.order_id) FILTER (WHERE o.delivery_delay_days > 0)::numeric
        / NULLIF(COUNT(DISTINCT o.order_id), 0)::numeric
    ) AS delayed_orders_pct
FROM olist_orders_logistics_clean_v o
WHERE o.order_status = 'delivered';


-- ============================================================
-- 07.2) FINAL KPI MASTER VIEW
-- ============================================================

CREATE OR REPLACE VIEW olist_kpi_master_v AS
SELECT
    -- PHASE 01 – RETENTION
    r.total_customers,
    r.returning_customers,
    r.retention_rate_percent,
    r.avg_purchase_frequency_days,
    r.active_customers,
    r.churned_customers,
    r.inactive_12_months,
    r.at_risk_customers,
    r.new_customers,

    -- PHASE 02 – DELIVERED ORDERS / LOGISTICS
    o.total_delivered_orders,
    o.delayed_orders_pct,

    -- EXECUTIVE DERIVED KPI (DELIVERED)
    (pay.total_payments_amount / NULLIF(o.total_delivered_orders, 0)) AS aov_product,

    -- PHASE 03 – GLOBAL PRODUCTS
    p.total_revenue           AS products_total_revenue,
    p.avg_product_price,
    p.avg_product_rating,
    p.avg_product_lead_time_days,
    p.avg_product_delay_days,

    -- PHASE 04 – GLOBAL REVIEWS
    rev.avg_rating            AS reviews_avg_rating,
    rev.pct_positive,
    rev.pct_negative,
    rev.pct_neutral,
    rev.avg_purchase_to_review_days,
    rev.avg_review_response_days,
    rev.pct_fast_response,
    rev.pct_timely_review,
    rev.total_reviews,

    -- PHASE 05 – GLOBAL PAYMENTS
    pay.total_payments_amount,
    pay.avg_payment_amount,
    pay.total_paid_orders,
    pay.total_payments_count,
    pay.total_installments,
    pay.avg_installments,
    pay.avg_installment_payments_pct,
    pay.avg_single_payment_pct,

    -- PHASE 06 – GLOBAL SELLERS
    s.sellers_total_revenue,
    s.sellers_avg_rating,
    s.sellers_avg_lead_time_days,
    s.sellers_avg_delay_days,
    s.sellers_total_orders,
    s.sellers_total_items_sold

FROM olist_kpi_retention_v r
CROSS JOIN olist_orders_delivered_kpi_global_v o
CROSS JOIN olist_products_kpi_global_v p
CROSS JOIN olist_reviews_kpi_global_v rev
CROSS JOIN olist_payments_kpi_global_v pay
CROSS JOIN olist_sellers_kpi_global_v s;