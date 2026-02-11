-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FILE: 00_grezzi_calcoli.sql
-- SCOPO: Quality checks preliminari e calcoli diagnostici grezzi
-- AUTORE: Claudio Matarrese
-- ============================================================


-- ============================================================
-- 01) ORDINI: CONTEGGI BASE
-- ============================================================

-- Totale ordini grezzi
SELECT COUNT(*) AS totale_ordini_raw
FROM orders;

-- Totale ordini delivered
SELECT COUNT(*) AS totale_ordini_delivered
FROM orders
WHERE order_status = 'delivered';


-- ============================================================
-- 02) CLIENTI: DUPLICATI E QUALITÀ
-- ============================================================

-- Conteggio clienti totali raw
SELECT COUNT(*) AS totale_clienti_raw
FROM customers;

-- Verifica customer_unique_id mancanti o anomali
SELECT customer_id, COUNT(*)
FROM customers
WHERE customer_unique_id IS NULL
GROUP BY customer_id;


-- ============================================================
-- 03) ORDINI: CHECK TEMPORALI GREZZI
-- ============================================================

-- 03.1) Ordini con incoerenze temporali grezze
SELECT COUNT(*) AS ordini_con_errori_temporali
FROM orders
WHERE order_purchase_timestamp > order_approved_at
   OR order_approved_at > order_delivered_carrier_date
   OR order_delivered_customer_date < order_delivered_carrier_date
   OR order_delivered_customer_date < order_purchase_timestamp;

-- 03.2) Consegna prima della spedizione
SELECT COUNT(*) AS consegna_prima_spedizione
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- 03.3) Lead time negativi grezzi
SELECT COUNT(*) AS lead_time_negativo
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 03.4) Ritardi estremamente negativi (storture dataset)
SELECT COUNT(*) AS ritardi_negativi_estremi
FROM orders
WHERE EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date)) / 86400 < -30;


-- ============================================================
-- 04) RECENSIONI: DIAGNOSTICA GREZZA
-- ============================================================

-- Risposte negative (risposta prima della creazione)
SELECT COUNT(*) AS risposta_negativa
FROM order_reviews_full
WHERE review_answer_timestamp < review_creation_date;

-- Totale recensioni valide
SELECT COUNT(*) AS totale_recensioni_valid
FROM order_reviews_full;

-- Distribuzione punteggi recensioni
SELECT review_score, COUNT(*) AS num_recensioni
FROM order_reviews_full
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 05) PRODOTTI: QUALITÀ GREZZA
-- ============================================================

-- Prezzi negativi o nulli
SELECT COUNT(*) AS prezzi_invalidi
FROM order_items
WHERE price <= 0 OR price IS NULL;

-- Freight negativi
SELECT COUNT(*) AS freight_negativi
FROM order_items
WHERE freight_value < 0;

-- Prodotti senza rating disponibile (in seguito popolati via JOIN)
SELECT COUNT(*) AS prodotti_senza_rating
FROM order_items oi
LEFT JOIN order_reviews_full r ON oi.order_id = r.order_id
WHERE r.review_score IS NULL;


-- ============================================================
-- 06) SELLER: QUALITÀ E SITUAZIONE GREZZA
-- ============================================================

-- Seller con valori estremi o mancanti
SELECT seller_id
FROM sellers
WHERE seller_state IS NULL
   OR seller_city IS NULL;

-- Numero seller per stato
SELECT seller_state, COUNT(DISTINCT seller_id) AS numero_seller
FROM sellers
GROUP BY seller_state
ORDER BY numero_seller DESC;


-- ============================================================
-- 07) CLIENTI: RETENTION GREZZA
-- ============================================================

-- Clienti unici con delivered
SELECT COUNT(DISTINCT customer_id) AS clienti_unici_delivered
FROM orders
WHERE order_status = 'delivered';

-- Clienti reali (unique_id)
SELECT COUNT(DISTINCT customer_unique_id) AS clienti_reali_con_ordini
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE order_status = 'delivered'
);

-- Clienti fedeli (grezzo) = >1 ordine delivered
SELECT COUNT(*) AS clienti_fedeli_grezzi
FROM (
    SELECT customer_unique_id
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) t;

-- Clienti totali reali (grezzo)
SELECT COUNT(*) AS clienti_totali_grezzi
FROM (
    SELECT DISTINCT customer_unique_id
    FROM customers
    WHERE customer_id IN (SELECT customer_id FROM orders)
) t;

-- Fedeltà grezza vs finale (diagnostica)
SELECT
    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM customers
     WHERE customer_id IN (SELECT customer_id FROM orders)) AS clienti_reali_grezzo,
    (SELECT COUNT(*)
     FROM (
         SELECT customer_unique_id
         FROM orders o
         JOIN customers c ON o.customer_id = c.customer_id
         WHERE o.order_status = 'delivered'
         GROUP BY customer_unique_id
         HAVING COUNT(*) > 1
     ) t) AS fedeli_grezzo,
    ROUND(
        (
            SELECT COUNT(*)
            FROM (
                SELECT customer_unique_id
                FROM orders o
                JOIN customers c ON o.customer_id = c.customer_id
                WHERE o.order_status = 'delivered'
                GROUP BY customer_unique_id
                HAVING COUNT(*) > 1
            ) t
        )::numeric
        /
        (SELECT COUNT(DISTINCT customer_unique_id)
         FROM customers
         WHERE customer_id IN (SELECT customer_id FROM orders))
    * 100, 2
    ) AS tasso_grezzo,
    clienti_reali_grezzo AS clienti_reali_finale,
    fedeli_grezzo AS fedeli_finale,
    tasso_grezzo AS tasso_finale;


-- ============================================================
-- 08) TOP CLIENTI E TOP SELLER (GREZZI)
-- ============================================================

-- Top clienti grezzi
SELECT customer_unique_id, COUNT(*) AS ordini
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY customer_unique_id
ORDER BY ordini DESC
LIMIT 20;

-- Top seller per revenue grezzo
SELECT seller_id, SUM(price) AS revenue_grezzo
FROM order_items
GROUP BY seller_id
ORDER BY revenue_grezzo DESC
LIMIT 20;


-- ============================================================
-- 09) VERIFICA CASUALE ORDINI (campione grezzo)
-- ============================================================

SELECT *
FROM orders
WHERE order_status = 'delivered'
ORDER BY RANDOM()
LIMIT 15;

