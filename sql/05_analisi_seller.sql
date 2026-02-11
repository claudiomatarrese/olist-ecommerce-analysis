-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FASE 05 – ANALISI SELLER (VENDITORI)
-- FILE: 05_analisi_seller.sql
-- AUTORE: Claudio Matarrese
-- STRUMENTI: PostgreSQL + Power BI + Python
-- ============================================================


-- ============================================================
-- 05.1) VISTA BASE SELLER
-- ============================================================
-- Grain: 1 riga = 1 product-item venduto da un seller.

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

    lg.giorni_acquisto_spedizione,
    lg.giorni_spedizione_consegna,
    lg.giorni_acquisto_consegna,
    lg.giorni_ritardo,
    lg.is_in_ritardo,
    lg.is_puntuale,

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
-- 05.2) VISTA CLEAN SELLER
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

    ROUND(giorni_acquisto_spedizione, 2) AS giorni_acquisto_spedizione,
    ROUND(giorni_spedizione_consegna, 2) AS giorni_spedizione_consegna,
    ROUND(giorni_acquisto_consegna, 2)   AS giorni_acquisto_consegna,
    ROUND(giorni_ritardo, 2)             AS giorni_ritardo,

    is_in_ritardo,
    is_puntuale

FROM olist_sellers_base_v;



-- ============================================================
-- 05.3) KPI PER SELLER (RIGA PER OGNI SELLER)
-- ============================================================

CREATE OR REPLACE VIEW olist_sellers_kpi_v AS
SELECT
    seller_id,
    seller_city,
    seller_state,

    COUNT(DISTINCT order_id) AS numero_ordini,
    COUNT(*)                 AS numero_prodotti_venduti,

    SUM(revenue) AS ricavo_totale,
    AVG(price)   AS prezzo_medio,

    AVG(review_score) AS rating_medio,
    100.0 * SUM(CASE WHEN is_high_rating THEN 1 ELSE 0 END) / COUNT(*) AS pct_high_rating,

    AVG(giorni_acquisto_consegna) AS lead_time_medio,
    AVG(giorni_ritardo)           AS ritardo_medio,

    100.0 * SUM(CASE WHEN is_puntuale   THEN 1 ELSE 0 END) / COUNT(*) AS pct_puntuali,
    100.0 * SUM(CASE WHEN is_in_ritardo THEN 1 ELSE 0 END) / COUNT(*) AS pct_in_ritardo

FROM olist_sellers_clean_v
GROUP BY seller_id, seller_city, seller_state
ORDER BY ricavo_totale DESC;



-- ============================================================
-- 05.4) KPI GLOBALI SELLER (UNA SOLA RIGA)
-- ============================================================

CREATE OR REPLACE VIEW olist_sellers_kpi_global_v AS
SELECT
    SUM(ricavo_totale) AS ricavo_totale_seller,
    AVG(rating_medio)  AS rating_medio_seller,
    AVG(lead_time_medio) AS lead_time_medio_seller,
    AVG(ritardo_medio)   AS ritardo_medio_seller,
    SUM(numero_ordini)   AS totale_ordini_seller,
    SUM(numero_prodotti_venduti) AS totale_prodotti_seller
FROM olist_sellers_kpi_v;
