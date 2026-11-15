-- ============================================================
-- Olist e-commerce analysis
-- Phase 05: payments
-- File: 05_payments_analysis.sql
-- Author: Claudio Matarrese
-- Tools: PostgreSQL, Power BI
-- ============================================================
-- What it does:
--   Payments of delivered orders in the clean set (with customer_id, so the table can be
--   related to the others in Power BI), KPIs by payment type and a single-row summary.
-- ============================================================


-- ============================================================
-- 05.1) Payments (delivered orders in the clean set, one row per payment)
-- ============================================================

CREATE OR REPLACE VIEW olist_payments_clean_v AS
SELECT
    op.order_id,
    o.customer_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
JOIN olist_orders_logistics_clean_v ol
    ON ol.order_id = op.order_id
WHERE ol.order_status = 'delivered';


-- ============================================================
-- 05.2) KPIs by payment type
-- ============================================================

CREATE OR REPLACE VIEW olist_payments_kpi_v AS
SELECT
    payment_type,
    SUM(payment_value) AS total_amount,
    AVG(payment_value) AS avg_payment_value,
    COUNT(DISTINCT order_id) AS orders_count,
    COUNT(*) AS payments_count,
    SUM(payment_installments) AS total_installments,
    AVG(payment_installments) AS avg_installments,
    100.0 * SUM(CASE WHEN payment_installments > 1 THEN 1 ELSE 0 END) / COUNT(*) AS pct_installment_payments,
    100.0 * SUM(CASE WHEN payment_installments <= 1 THEN 1 ELSE 0 END) / COUNT(*) AS pct_single_payment
FROM olist_payments_clean_v
GROUP BY payment_type;


-- ============================================================
-- 05.3) Global payment KPIs (single row)
-- The averages are averages of the per-type values, not of all payments, and
-- total_paid_orders adds up the orders of each type, so an order paid with two methods
-- is counted twice. The dashboard calculates these on payment rows, so a few numbers differ.
-- ============================================================

CREATE OR REPLACE VIEW olist_payments_kpi_global_v AS
SELECT
    SUM(total_amount)             AS total_payments_amount,
    AVG(avg_payment_value)        AS avg_payment_amount,
    SUM(orders_count)             AS total_paid_orders,
    SUM(payments_count)           AS total_payments_count,
    SUM(total_installments)       AS total_installments,
    AVG(avg_installments)         AS avg_installments,
    AVG(pct_installment_payments) AS avg_installment_payments_pct,
    AVG(pct_single_payment)       AS avg_single_payment_pct,
    (SELECT SUM(payment_value) FROM olist_payments_clean_v) AS revenue_delivered_clean
FROM olist_payments_kpi_v;