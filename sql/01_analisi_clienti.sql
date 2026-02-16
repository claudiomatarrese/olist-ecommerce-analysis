-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FASE 01 – ANALISI CLIENTI (RETENTION & FREQUENCY)
-- FILE: 01_analisi_clienti.sql
-- AUTORE: Claudio Matarrese
-- STRUMENTI: PostgreSQL + Power BI
-- ============================================================
-- DESCRIZIONE:
--   Costruzione delle viste clienti: base delivered, per-cliente, calcolo retention, frequenza ordini e KPI finali.
--   Output  business-ready.
-- ============================================================


-- ============================================================
-- 01.1) BASE ORDINI DELIVERED (RAW → BUSINESS)
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
-- 01.2) CLIENTI CON SOLO ORDINI DELIVERED
-- ============================================================

CREATE OR REPLACE VIEW olist_per_cliente_delivered_v AS
SELECT
    c.customer_unique_id,
    d.customer_id,
    d.order_id,
    d.order_purchase_timestamp
FROM olist_delivered_base_v d
JOIN customers c
  ON d.customer_id = c.customer_id;


-- ============================================================
-- 01.3) LAG ORDINI → CALCOLO INTERVALLI TRA ACQUISTI
-- ============================================================

CREATE OR REPLACE VIEW olist_lag_ordini_v AS
SELECT
    customer_unique_id,
    order_id,
    order_purchase_timestamp,
    LAG(order_purchase_timestamp)
        OVER (PARTITION BY customer_unique_id
              ORDER BY order_purchase_timestamp) AS ordine_precedente
FROM olist_per_cliente_delivered_v;


-- ============================================================
-- 01.4) RETENTION – CALCOLO FREQUENCY E STATISTICHE
-- ============================================================

CREATE OR REPLACE VIEW olist_customer_retention_v AS
SELECT
    customer_unique_id,
    COUNT(order_id) AS numero_ordini,
    COUNT(order_id) > 1 AS is_fedele,

    ROUND(AVG(
        EXTRACT(EPOCH FROM (order_purchase_timestamp - ordine_precedente)) / 86400
    )::numeric, 2) AS frequenza_media_giorni
FROM olist_lag_ordini_v
GROUP BY customer_unique_id;


-- ============================================================
-- 01.5) KPI DI RETENTION – VISTA FINALE
-- ============================================================

CREATE OR REPLACE VIEW olist_kpi_retention_v AS
SELECT
    -- Totale clienti reali (unique_id)
    (SELECT COUNT(DISTINCT customer_unique_id)
       FROM olist_per_cliente_delivered_v) AS clienti_totali,

    -- Clienti fedeli (più di 1 ordine)
    (SELECT COUNT(*)
       FROM olist_customer_retention_v
       WHERE is_fedele = true) AS clienti_fedeli,

    -- % fedeltà
    ROUND(
        (
            SELECT COUNT(*)::numeric
            FROM olist_customer_retention_v
            WHERE is_fedele = true
        )
        /
        (SELECT COUNT(DISTINCT customer_unique_id)
           FROM olist_per_cliente_delivered_v)
    * 100, 2) AS tasso_fedelta_percent,

    -- Frequenza media ordini
    (SELECT ROUND(AVG(frequenza_media_giorni), 2)
       FROM olist_customer_retention_v) AS frequenza_media_giorni,

    -- Clienti attivi (almeno 1 ordine delivered)
    (SELECT COUNT(DISTINCT customer_unique_id)
       FROM olist_per_cliente_delivered_v) AS clienti_attivi,

    -- Clienti persi (nessun ordine negli ultimi 90 giorni)
    (SELECT COUNT(*)
       FROM (
             SELECT customer_unique_id,
                    MAX(order_purchase_timestamp) AS last_order
             FROM olist_per_cliente_delivered_v
             GROUP BY customer_unique_id
         ) t
     WHERE last_order < NOW() - INTERVAL '90 days') AS clienti_persi,

    -- Clienti persi negli ultimi 12 mesi
    (SELECT COUNT(*)
       FROM (
             SELECT customer_unique_id,
                    MAX(order_purchase_timestamp) AS last_order
             FROM olist_per_cliente_delivered_v
             GROUP BY customer_unique_id
         ) t
     WHERE last_order < NOW() - INTERVAL '365 days') AS clienti_persi_12_mesi,

    -- Clienti a rischio (nessun ordine da 60 giorni)
    (SELECT COUNT(*)
       FROM (
             SELECT customer_unique_id,
                    MAX(order_purchase_timestamp) AS last_order
             FROM olist_per_cliente_delivered_v
             GROUP BY customer_unique_id
         ) t
     WHERE last_order BETWEEN
           NOW() - INTERVAL '90 days'
       AND NOW() - INTERVAL '60 days') AS clienti_a_rischio,

    -- Nuovi clienti (primo ordine negli ultimi 30 giorni)
    (SELECT COUNT(*)
       FROM (
             SELECT customer_unique_id,
                    MIN(order_purchase_timestamp) AS first_order
             FROM olist_per_cliente_delivered_v
             GROUP BY customer_unique_id
         ) t
     WHERE first_order > NOW() - INTERVAL '30 days') AS nuovi_clienti;
