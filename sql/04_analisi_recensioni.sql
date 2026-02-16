-- ============================================================
-- PROGETTO: OLIST E-COMMERCE ANALYSIS
-- FASE 04 – ANALISI RECENSIONI
-- FILE: 04_analisi_recensioni.sql
-- AUTORE: Claudio Matarrese
-- STRUMENTI: PostgreSQL + Power BI
-- ============================================================


-- ============================================================
-- 04.1) VISTA BASE RECENSIONI
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_base_v AS
SELECT
    r.review_id,
    r.order_id,
    o.customer_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp,
    o.order_purchase_timestamp,

    EXTRACT(EPOCH FROM (r.review_creation_date - o.order_purchase_timestamp))/86400
        AS giorni_acquisto_recensione,

    EXTRACT(EPOCH FROM (r.review_answer_timestamp - r.review_creation_date))/86400
        AS giorni_risposta_review

FROM order_reviews_full r
JOIN orders o
  ON r.order_id = o.order_id
WHERE o.order_status = 'delivered';



-- ============================================================
-- 04.2) VISTA CLEAN RECENSIONI
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_clean_v AS
SELECT
    review_id,
    order_id,
    customer_id,
    review_score,
    review_comment_title,
    review_comment_message,

    CASE WHEN review_score >= 4 THEN true ELSE false END AS is_positive,
    CASE WHEN review_score <= 2 THEN true ELSE false END AS is_negative,
    CASE WHEN review_score = 3 THEN true ELSE false END AS is_neutral,

    ROUND(giorni_acquisto_recensione, 2) AS giorni_acquisto_recensione,
    ROUND(giorni_risposta_review, 2)     AS giorni_risposta_review,

    CASE
        WHEN giorni_risposta_review IS NOT NULL
         AND giorni_risposta_review <= 2
        THEN true ELSE false
    END AS risposta_veloce,

    CASE WHEN giorni_acquisto_recensione <= 5 THEN true ELSE false END AS review_tempestiva

FROM olist_reviews_base_v;



-- ============================================================
-- 04.3) VISTE DI DETTAGLIO
-- (Rating per categoria, stato, delivery time)
-- ============================================================

-- 04.3.1 – Rating medio per categoria prodotto
CREATE OR REPLACE VIEW olist_reviews_rating_per_categoria_v AS
WITH prod AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        product_category_name
    FROM olist_products_clean_v
)
SELECT
    p.product_category_name,
    AVG(r.review_score) AS rating_medio
FROM olist_reviews_clean_v r
JOIN prod p USING (order_id)
GROUP BY p.product_category_name;


-- 04.3.2 – Rating medio per stato cliente
CREATE OR REPLACE VIEW olist_reviews_rating_per_state_v AS
SELECT
    c.customer_state,
    AVG(r.review_score) AS rating_medio
FROM olist_reviews_clean_v r
JOIN customers c
  ON r.customer_id = c.customer_id
GROUP BY c.customer_state;


-- 04.3.3 – Rating medio per lead time consegna
CREATE OR REPLACE VIEW olist_reviews_rating_per_delivery_time_v AS
WITH lt AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        giorni_acquisto_consegna
    FROM olist_products_clean_v
)
SELECT
    lt.giorni_acquisto_consegna,
    AVG(r.review_score) AS rating_medio
FROM olist_reviews_clean_v r
JOIN lt USING (order_id)
GROUP BY lt.giorni_acquisto_consegna
ORDER BY lt.giorni_acquisto_consegna;



-- ============================================================
-- 04.4) KPI PER RECENSIONI (RIGA PER OGNI DIMENSIONE)
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_kpi_v AS
SELECT
    AVG(review_score) AS rating_medio,

    100.0 * SUM(CASE WHEN is_positive THEN 1 ELSE 0 END) / COUNT(*) AS pct_positive,
    100.0 * SUM(CASE WHEN is_negative THEN 1 ELSE 0 END) / COUNT(*) AS pct_negative,
    100.0 * SUM(CASE WHEN is_neutral  THEN 1 ELSE 0 END) / COUNT(*) AS pct_neutral,

    AVG(giorni_acquisto_recensione) AS giorni_medio_acquisto_recensione,
    AVG(giorni_risposta_review)     AS giorni_medio_risposta_recensione,

    100.0 * SUM(CASE WHEN risposta_veloce   THEN 1 ELSE 0 END) / COUNT(*) AS pct_risposta_veloce,
    100.0 * SUM(CASE WHEN review_tempestiva THEN 1 ELSE 0 END) / COUNT(*) AS pct_review_tempestiva,

    COUNT(*) AS totale_recensioni

FROM olist_reviews_clean_v;



-- ============================================================
-- 04.5) KPI GLOBALI RECENSIONI (UNA SOLA RIGA)
-- ============================================================

CREATE OR REPLACE VIEW olist_reviews_kpi_global_v AS
SELECT
    AVG(rating_medio)                     AS rating_medio,
    AVG(pct_positive)                     AS pct_positive,
    AVG(pct_negative)                     AS pct_negative,
    AVG(pct_neutral)                      AS pct_neutral,
    AVG(giorni_medio_acquisto_recensione) AS giorni_medio_acquisto_recensione,
    AVG(giorni_medio_risposta_recensione) AS giorni_medio_risposta_recensione,
    AVG(pct_risposta_veloce)              AS pct_risposta_veloce,
    AVG(pct_review_tempestiva)            AS pct_review_tempestiva,
    SUM(totale_recensioni)                AS totale_recensioni
FROM olist_reviews_kpi_v;

