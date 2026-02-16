-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FASE 02 – ANALISI ORDINI & LOGISTICA
-- FILE: 02_analisi_ordini.sql
-- AUTORE: Claudio Matarrese
-- STRUMENTI: PostgreSQL + Power BI
-- ============================================================


-- ============================================================
-- 02.1) VISTA BASE LOGISTICA (CALCOLI GREZZI)
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
        AS giorni_acquisto_spedizione,

    (EXTRACT(EPOCH FROM order_delivered_customer_date - order_delivered_carrier_date) / 86400)
        AS giorni_spedizione_consegna,

    (EXTRACT(EPOCH FROM order_delivered_customer_date - order_purchase_timestamp) / 86400)
        AS giorni_acquisto_consegna,

    (EXTRACT(EPOCH FROM order_delivered_customer_date - order_estimated_delivery_date) / 86400)
        AS giorni_ritardo,

    (EXTRACT(EPOCH FROM order_approved_at - order_purchase_timestamp) / 86400)
        AS giorni_acquisto_approvazione,

    CASE WHEN (EXTRACT(EPOCH FROM order_delivered_customer_date - order_estimated_delivery_date) / 86400) >= 1
         THEN true ELSE false END AS is_in_ritardo,

    CASE WHEN (EXTRACT(EPOCH FROM order_delivered_customer_date - order_estimated_delivery_date) / 86400) <= 0
         THEN true ELSE false END AS is_puntuale,

    CASE 
        WHEN order_purchase_timestamp > order_approved_at
          OR order_approved_at > order_delivered_carrier_date
          OR order_purchase_timestamp > order_delivered_carrier_date
          OR order_delivered_customer_date < order_delivered_carrier_date
          OR order_delivered_customer_date < order_purchase_timestamp
          OR order_estimated_delivery_date < order_purchase_timestamp
          OR order_estimated_delivery_date < order_delivered_carrier_date
        THEN true ELSE false
    END AS has_error_temporale

FROM olist_orders_base_v;



-- ============================================================
-- 02.2) VISTA LOGISTICA PULITA (BUSINESS-READY)
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

    ROUND(giorni_acquisto_spedizione, 2)    AS giorni_acquisto_spedizione,
    ROUND(giorni_spedizione_consegna, 2)    AS giorni_spedizione_consegna,
    ROUND(giorni_acquisto_consegna, 2)      AS giorni_acquisto_consegna,
    ROUND(giorni_ritardo, 2)                AS giorni_ritardo,
    ROUND(giorni_acquisto_approvazione, 2)  AS giorni_acquisto_approvazione,

    is_in_ritardo,
    is_puntuale,
    has_error_temporale

FROM olist_orders_logistics_v
WHERE has_error_temporale = false;



-- ============================================================
-- 02.3) KPI LOGISTICI (PRODUZIONE)
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_kpi_v AS
SELECT
    COUNT(*) AS totale_ordini,

    COUNT(*) FILTER (WHERE is_puntuale)   AS ordini_puntuali,
    COUNT(*) FILTER (WHERE is_in_ritardo) AS ordini_in_ritardo,

    ROUND(AVG(giorni_acquisto_consegna), 2)     AS lead_time_medio,
    ROUND(AVG(giorni_acquisto_spedizione), 2)   AS handling_time_medio,
    ROUND(AVG(giorni_spedizione_consegna), 2)   AS shipping_time_medio,
    ROUND(AVG(giorni_acquisto_approvazione), 2) AS approval_time_medio,

    ROUND(100.0 * COUNT(*) FILTER (WHERE is_puntuale)::NUMERIC / COUNT(*), 2)
        AS percentuale_puntuale,

    ROUND(100.0 * COUNT(*) FILTER (WHERE is_in_ritardo)::NUMERIC / COUNT(*), 2)
        AS percentuale_ritardo

FROM olist_orders_logistics_clean_v
WHERE order_status = 'delivered';



-- ============================================================
-- 02.4) KPI GEOGRAFICI – CUSTOMER STATE
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_geo_customer_v AS
SELECT
    c.customer_state,
    ROUND(AVG(o.giorni_acquisto_consegna), 2) AS lead_time_medio,
    ROUND(AVG(o.giorni_ritardo), 2)          AS ritardo_medio,
    ROUND(
        100.0 * SUM(CASE WHEN o.is_in_ritardo THEN 1 ELSE 0 END)::NUMERIC / COUNT(*),
        2
    ) AS percentuale_ritardo
FROM olist_orders_logistics_clean_v o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state;



-- ============================================================
-- 02.5) KPI GEOGRAFICI – SELLER STATE
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_geo_seller_v AS
SELECT
    s.seller_state,
    ROUND(AVG(o.giorni_acquisto_consegna), 2) AS lead_time_medio,
    ROUND(AVG(o.giorni_ritardo), 2)          AS ritardo_medio
FROM olist_orders_logistics_clean_v o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state;



-- ============================================================
-- 02.6) MATRICE LOGISTICA SELLER → CUSTOMER
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_seller_customer_matrix_v AS
SELECT
    s.seller_state,
    c.customer_state,
    ROUND(AVG(o.giorni_ritardo), 2) AS ritardo_medio
FROM olist_orders_logistics_clean_v o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state, c.customer_state
ORDER BY s.seller_state, c.customer_state;

