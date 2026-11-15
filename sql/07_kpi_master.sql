-- ============================================================
-- Olist e-commerce analysis
-- Phase 07: KPI master
-- File: 07_kpi_master.sql
-- Author: Claudio Matarrese
-- Tools: PostgreSQL, Power BI
-- ============================================================
-- What it does:
--   1) A small view with the delivered orders and the share of delayed orders.
--   2) The KPI master: one row that puts together the single-row KPI views of phases 01 to 06.
--   I use the master to check the dashboard numbers. It is not related to the other tables in Power BI.
-- ============================================================


-- ============================================================
-- 07.1) Delivered orders and share of delayed orders
-- Careful: here 'delayed' means any delay above 0 days. The dashboard and the clean views
-- use 1 day or more (is_delayed), so this share is higher than the 6.4% shown in the report.
-- The value is a fraction (0 to 1), not a percentage.
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
-- 07.2) KPI master (single row)
-- ============================================================

CREATE OR REPLACE VIEW olist_kpi_master_v AS
SELECT
    -- Phase 01: customers
    r.total_customers,
    r.returning_customers,
    r.retention_rate_percent,
    r.avg_purchase_frequency_days,
    r.active_customers,
    r.churned_customers,
    r.inactive_12_months,
    r.at_risk_customers,
    r.new_customers,

    -- Phase 02: delivery
    o.total_delivered_orders,
    o.delayed_orders_pct,

    -- Average order value: total payments / delivered orders
    (pay.total_payments_amount / NULLIF(o.total_delivered_orders, 0)) AS aov_product,

    -- Phase 03: products
    p.total_revenue           AS products_total_revenue,
    p.avg_product_price,
    p.avg_product_rating,
    p.avg_product_lead_time_days,
    p.avg_product_delay_days,

    -- Phase 04: reviews
    rev.avg_rating            AS reviews_avg_rating,
    rev.pct_positive,
    rev.pct_negative,
    rev.pct_neutral,
    rev.avg_purchase_to_review_days,
    rev.avg_review_response_days,
    rev.pct_fast_response,
    rev.pct_timely_review,
    rev.total_reviews,

    -- Phase 05: payments
    pay.total_payments_amount,
    pay.avg_payment_amount,
    pay.total_paid_orders,
    pay.total_payments_count,
    pay.total_installments,
    pay.avg_installments,
    pay.avg_installment_payments_pct,
    pay.avg_single_payment_pct,

    -- Phase 06: sellers
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