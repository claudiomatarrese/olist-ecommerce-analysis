-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FASE 03 – ANALISI PRODOTTI E CATEGORIE
-- FILE: 03_analisi_prodotti.sql
-- AUTORE: Claudio Matarrese
-- STRUMENTI: PostgreSQL + Power BI
-- ============================================================


-- ============================================================
-- 03.1) VISTA BASE PRODOTTI
-- ============================================================

CREATE OR REPLACE VIEW olist_products_base_v AS
SELECT
    oi.order_id,
    oi.product_id,
    p.product_category_name,
    oi.price,
    oi.freight_value,
    oi.price AS revenue,

    -- rating aggregato per ordine (evita duplicazioni)
    (
        SELECT MAX(review_score)
        FROM order_reviews r
        WHERE r.order_id = oi.order_id
    ) AS review_score,

    o.order_purchase_timestamp,

    lg.giorni_acquisto_spedizione,
    lg.giorni_spedizione_consegna,
    lg.giorni_acquisto_consegna,
    lg.giorni_ritardo,
    lg.is_in_ritardo,
    lg.is_puntuale

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
   AND o.order_status = 'delivered'
JOIN products p
    ON oi.product_id = p.product_id
JOIN olist_orders_logistics_clean_v lg
    ON oi.order_id = lg.order_id;



-- ============================================================
-- 03.2) VISTA CLEAN PRODOTTI
-- ============================================================

CREATE OR REPLACE VIEW olist_products_clean_v AS
SELECT
    order_id,
    product_id,
    product_category_name,

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
    is_puntuale,

    CASE WHEN price > 100 THEN true ELSE false END AS is_expensive,
    CASE WHEN giorni_acquisto_consegna < 7 THEN true ELSE false END AS is_fast_delivery

FROM olist_products_base_v;



-- ============================================================
-- 03.3) KPI PER CATEGORIA
-- ============================================================

CREATE OR REPLACE VIEW olist_products_kpi_v AS
SELECT
    product_category_name,

    SUM(revenue) AS total_revenue,
    AVG(price)   AS avg_price,
    COUNT(order_id) AS total_products_sold,

    AVG(review_score) AS avg_rating,
    100.0 * SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END) / COUNT(*) AS pct_high_rating,

    AVG(giorni_acquisto_consegna) AS lead_time_medio,
    AVG(giorni_ritardo)           AS ritardo_medio,

    100.0 * SUM(CASE WHEN is_puntuale THEN 1 ELSE 0 END) / COUNT(*)   AS pct_puntuali,
    100.0 * SUM(CASE WHEN is_in_ritardo THEN 1 ELSE 0 END) / COUNT(*) AS pct_in_ritardo,

    MIN(price) AS min_price,
    MAX(price) AS max_price

FROM olist_products_clean_v
GROUP BY product_category_name
ORDER BY total_revenue DESC;



-- ============================================================
-- 03.4) KPI GLOBALI PRODOTTI
-- ============================================================

CREATE OR REPLACE VIEW olist_products_kpi_global_v AS
SELECT
    SUM(total_revenue) AS revenue_totale,
    AVG(avg_price)     AS prezzo_medio_prodotto,
    AVG(avg_rating)    AS rating_medio_prodotto,
    AVG(lead_time_medio) AS lead_time_medio_prodotto,
    AVG(ritardo_medio)   AS ritardo_medio_prodotto
FROM olist_products_kpi_v;

