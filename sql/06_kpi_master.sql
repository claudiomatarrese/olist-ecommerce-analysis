-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FASE 06 – KPI MASTER DASHBOARD
-- FILE: 06_kpi_master.sql
-- AUTORE: Claudio Matarrese
-- STRUMENTI: PostgreSQL + Power BI + Python
-- ============================================================
-- DESCRIZIONE:
--   Vista finale che aggrega TUTTI i KPI globali:
--   - Retention (Fase 01)
--   - Ordini/Logistica Delivered (Fase 02)
--   - Prodotti (Fase 03)
--   - Recensioni (Fase 04)
--   - Pagamenti (Fase 04)
--   - Seller (Fase 05)
-- ============================================================


-- ============================================================
-- 06.1) KPI GLOBALI PRODOTTI
-- ============================================================

CREATE OR REPLACE VIEW olist_products_kpi_global_v AS
SELECT
    SUM(total_revenue)     AS revenue_totale,
    AVG(avg_price)         AS prezzo_medio_prodotto,
    AVG(avg_rating)        AS rating_medio_prodotto,
    AVG(lead_time_medio)   AS lead_time_medio_prodotto,
    AVG(ritardo_medio)     AS ritardo_medio_prodotto
FROM olist_products_kpi_v;



-- ============================================================
-- 06.2) KPI GLOBALI PAGAMENTI
-- ============================================================

CREATE OR REPLACE VIEW olist_payments_kpi_global_v AS
SELECT
    SUM(importo_totale)        AS pagamenti_totali,
    AVG(valore_medio_pagato)   AS pagamento_medio,
    SUM(num_ordini)            AS totale_ordini_pagati,
    SUM(num_pagamenti)         AS totale_pagamenti,
    SUM(totale_rate)           AS totale_rate,
    AVG(rate_medie)            AS rate_medie,
    AVG(pct_rateali)           AS pct_rateali_media,
    AVG(pct_non_rateali)       AS pct_non_rateali_media
FROM olist_payments_kpi_v;



-- ============================================================
-- 06.3) KPI GLOBALI SELLER
-- ============================================================

CREATE OR REPLACE VIEW olist_sellers_kpi_global_v AS
SELECT
    SUM(ricavo_totale)           AS ricavo_totale_seller,
    AVG(rating_medio)            AS rating_medio_seller,
    AVG(lead_time_medio)         AS lead_time_medio_seller,
    AVG(ritardo_medio)           AS ritardo_medio_seller,
    SUM(numero_ordini)           AS totale_ordini_seller,
    SUM(numero_prodotti_venduti) AS totale_prodotti_seller
FROM olist_sellers_kpi_v;



-- ============================================================
-- 06.4) KPI GLOBALI RECENSIONI
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_kpi_global_v AS
SELECT
    AVG(rating_medio)                      AS rating_medio,
    AVG(pct_positive)                      AS pct_positive,
    AVG(pct_negative)                      AS pct_negative,
    AVG(pct_neutral)                       AS pct_neutral,
    AVG(giorni_medio_acquisto_recensione)  AS giorni_medio_acquisto_recensione,
    AVG(giorni_medio_risposta_recensione)  AS giorni_medio_risposta_recensione,
    AVG(pct_risposta_veloce)               AS pct_risposta_veloce,
    AVG(pct_review_tempestiva)             AS pct_review_tempestiva,
    SUM(totale_recensioni)::bigint         AS totale_recensioni
FROM olist_reviews_kpi_v;



-- ============================================================
-- 06.5) KPI GLOBALI ORDINI/LOGISTICA (DELIVERED)
-- ============================================================

CREATE OR REPLACE VIEW olist_orders_delivered_kpi_global_v AS
SELECT
    COUNT(DISTINCT o.order_id) AS totale_ordini_consegnati,
    (
        COUNT(DISTINCT o.order_id) FILTER (WHERE o.giorni_ritardo > 0)::numeric
        / NULLIF(COUNT(DISTINCT o.order_id), 0)::numeric
    ) AS pct_ordini_in_ritardo
FROM olist_orders_logistics_clean_v o
WHERE o.order_status = 'delivered';



-- ============================================================
-- 06.6) KPI MASTER FINALE
-- ============================================================

CREATE OR REPLACE VIEW olist_kpi_master_v AS
SELECT
    -- FASE 01 – RETENTION
    r.clienti_totali,
    r.clienti_fedeli,
    r.tasso_fedelta_percent,
    r.frequenza_media_giorni,
    r.clienti_attivi,
    r.clienti_persi,
    r.clienti_persi_12_mesi,
    r.clienti_a_rischio,
    r.nuovi_clienti,

    -- FASE 02 – ORDINI/LOGISTICA (DELIVERED)
    o.totale_ordini_consegnati,
    o.pct_ordini_in_ritardo,

    -- KPI DERIVATO EXECUTIVE (DELIVERED)
    (p.revenue_totale / NULLIF(o.totale_ordini_consegnati, 0)) AS aov_prodotto,

    -- FASE 03 – PRODOTTI GLOBALI
    p.revenue_totale           AS revenue_totale_prodotti,
    p.prezzo_medio_prodotto,
    p.rating_medio_prodotto,
    p.lead_time_medio_prodotto,
    p.ritardo_medio_prodotto,

    -- FASE 04 – RECENSIONI GLOBALI
    rev.rating_medio           AS rating_medio_recensioni,
    rev.pct_positive,
    rev.pct_negative,
    rev.pct_neutral,
    rev.giorni_medio_acquisto_recensione,
    rev.giorni_medio_risposta_recensione,
    rev.pct_risposta_veloce,
    rev.pct_review_tempestiva,
    rev.totale_recensioni,

    -- FASE 04 – PAGAMENTI GLOBALI
    pay.pagamenti_totali,
    pay.pagamento_medio,
    pay.totale_ordini_pagati,
    pay.totale_pagamenti,
    pay.totale_rate,
    pay.rate_medie,
    pay.pct_rateali_media,
    pay.pct_non_rateali_media,

    -- FASE 05 – SELLER GLOBALI
    s.ricavo_totale_seller,
    s.rating_medio_seller,
    s.lead_time_medio_seller,
    s.ritardo_medio_seller,
    s.totale_ordini_seller,
    s.totale_prodotti_seller

FROM olist_kpi_retention_v r
CROSS JOIN olist_orders_delivered_kpi_global_v o
CROSS JOIN olist_products_kpi_global_v p
CROSS JOIN olist_reviews_kpi_global_v rev
CROSS JOIN olist_payments_kpi_global_v pay
CROSS JOIN olist_sellers_kpi_global_v s;
