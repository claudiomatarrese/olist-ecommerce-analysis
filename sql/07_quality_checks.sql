-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FASE 07 – QUALITY CHECKS COMPLETI
-- FILE: 07_quality_checks.sql
-- AUTORE: Claudio Matarrese
-- STRUMENTI: PostgreSQL + Power BI
-- ============================================================
-- SCOPO:
--   Controlli qualità su tutte le fasi: clienti, ordini, logistica, prodotti, pagamenti, recensioni e seller.
--   Nessuna vista viene creata. Solo SELECT diagnostiche.
-- ============================================================


-- ============================================================
-- 07.1) CHECK CLIENTI / ORDINI
-- ============================================================

-- Conta totale ordini grezzi
SELECT COUNT(*) AS totale_ordini_raw
FROM orders;

-- Conta totale ordini delivered
SELECT COUNT(*) AS totale_ordini_delivered
FROM orders
WHERE order_status = 'delivered';

-- Verifica coerenza clienti (customer_id non null)
SELECT COUNT(*) AS totale_clienti_raw
FROM customers;

SELECT customer_id, COUNT(*)
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1 AND customer_id IS NULL;


-- ============================================================
-- 07.2) CHECK LOGISTICA (Fase 02)
-- ============================================================

-- Errori temporali nella logistica
SELECT COUNT(*) AS ordini_con_errori_temporali
FROM olist_orders_logistics_v
WHERE has_error_temporale = true;

-- Consegna prima della spedizione
SELECT COUNT(*) AS consegna_prima_spedizione
FROM olist_orders_logistics_v
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- Lead time negativo
SELECT COUNT(*) AS lead_time_negativo
FROM olist_orders_logistics_v
WHERE giorni_acquisto_consegna < 0;

-- Ritardi negativi estremi (< –30 giorni)
SELECT COUNT(*) AS ritardi_negativi_estremi
FROM olist_orders_logistics_v
WHERE giorni_ritardo < -30;


-- ============================================================
-- 07.3) CHECK RECENSIONI (Fase 04)
-- ============================================================

-- Risposte negative (<0)
SELECT COUNT(*) AS risposta_negativa
FROM olist_reviews_clean_v
WHERE giorni_risposta_review < 0;

-- Totale recensioni valide
SELECT COUNT(*) AS totale_recensioni_valid
FROM olist_reviews_clean_v;

-- Distribuzione punteggi recensioni
SELECT review_score, COUNT(*) AS num_recensioni
FROM olist_reviews_clean_v
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 07.4) CHECK PRODOTTI (Fase 03)
-- ============================================================

-- Prezzi negativi o null
SELECT COUNT(*) AS prezzi_invalidi
FROM olist_products_clean_v
WHERE price <= 0;

-- Freight negativi
SELECT COUNT(*) AS freight_negativi
FROM olist_products_clean_v
WHERE freight_value < 0;

-- Prodotti senza rating (possibile assenza recensione)
SELECT COUNT(*) AS prodotti_senza_rating
FROM olist_products_clean_v
WHERE review_score IS NULL;


-- ============================================================
-- 07.5) CHECK SELLER (Fase 05)
-- ============================================================

-- Seller con revenue massimi (top 30 diagnostici)
SELECT seller_id, SUM(revenue) AS revenue_grezzo
FROM olist_sellers_clean_v
GROUP BY seller_id
ORDER BY revenue_grezzo DESC
LIMIT 30;

-- Giorni consegna negativi
SELECT COUNT(*) AS lead_time_negativo_seller
FROM olist_sellers_clean_v
WHERE giorni_acquisto_consegna < 0;

-- Numero seller per stato
SELECT seller_state, COUNT(DISTINCT seller_id) AS numero_seller
FROM olist_sellers_clean_v
GROUP BY seller_state
ORDER BY numero_seller DESC;


-- ============================================================
-- 07.6) CHECK RETENTION (Fase 01)
-- ============================================================

-- Totale clienti unici che hanno almeno 1 delivered
SELECT COUNT(DISTINCT customer_id) AS clienti_unici_delivered
FROM olist_orders_base_v;

-- Clienti reali (unique_id)
SELECT COUNT(DISTINCT customer_unique_id) AS clienti_reali_con_ordini
FROM olist_delivered_base_v;

-- Clienti fedeli grezzi (>1 ordine)
SELECT COUNT(*) AS clienti_fedeli_grezzi
FROM olist_customer_retention_v
WHERE num_ordini > 1;

-- Tasso fedeltà grezzo vs finale
SELECT
    COUNT(DISTINCT customer_unique_id) AS clienti_totali_grezzi,
    SUM(CASE WHEN num_ordini > 1 THEN 1 ELSE 0 END) AS clienti_fedeli_grezzi,
    ROUND(100.0 * SUM(CASE WHEN num_ordini > 1 THEN 1 ELSE 0 END)::numeric /
          COUNT(DISTINCT customer_unique_id), 2) AS tasso_grezzo
FROM olist_customer_retention_v;


-- Top clienti per numero di ordini (diagnostico)
SELECT customer_unique_id, num_ordini AS ordini
FROM olist_customer_retention_v
ORDER BY num_ordini DESC
LIMIT 30;


-- ============================================================
-- 07.7) CHECK COMPLESSIVI SELLER (Fase 05)
-- ============================================================

SELECT seller_id, revenue_grezzo
FROM (
    SELECT seller_id, SUM(revenue) AS revenue_grezzo
    FROM olist_sellers_clean_v
    GROUP BY seller_id
) t
ORDER BY revenue_grezzo DESC
LIMIT 10;


-- ============================================================
-- 07.8) CHECK ORDINI RANDOM (sanity check)
-- ============================================================

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
ORDER BY random()
LIMIT 15;

