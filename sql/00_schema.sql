-- ============================================================
-- PROJECT: OLIST E-COMMERCE ANALYSIS
-- FILE: 00_schema.sql
-- PURPOSE: Create RAW tables and indexes
-- AUTHOR: Claudio Matarrese
-- ============================================================


-- ============================================================
-- 01) CUSTOMERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR PRIMARY KEY,
    customer_unique_id VARCHAR,
    customer_zip_code_prefix INT,
    customer_city VARCHAR,
    customer_state VARCHAR(2)
);

CREATE INDEX IF NOT EXISTS idx_customers_unique_id
    ON customers(customer_unique_id);


-- ============================================================
-- 02) ORDERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
    ON orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON orders(order_status);

CREATE INDEX IF NOT EXISTS idx_orders_purchase_ts
    ON orders(order_purchase_timestamp);


-- ============================================================
-- 03) ORDER_ITEMS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR,
    order_item_id INT,
    product_id VARCHAR,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
    ON order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_seller_id
    ON order_items(seller_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items(order_id);


-- ============================================================
-- 04) ORDER_PAYMENTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS order_payments (
    order_id VARCHAR,
    payment_sequential INT,
    payment_type VARCHAR,
    payment_installments INT,
    payment_value NUMERIC,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE INDEX IF NOT EXISTS idx_order_payments_order_id
    ON order_payments(order_id);

CREATE INDEX IF NOT EXISTS idx_order_payments_type
    ON order_payments(payment_type);


-- ============================================================
-- 05) ORDER_REVIEWS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id VARCHAR PRIMARY KEY,
    order_id VARCHAR,
    review_score INT,
    review_comment_title VARCHAR,
    review_comment_message VARCHAR,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reviews_order_id
    ON order_reviews(order_id);

CREATE INDEX IF NOT EXISTS idx_reviews_score
    ON order_reviews(review_score);


-- ============================================================
-- 05b) ORDER_REVIEWS_FULL (extended version of reviews table)
-- ============================================================

CREATE TABLE IF NOT EXISTS order_reviews_full (
    review_id VARCHAR PRIMARY KEY,
    order_id VARCHAR,
    review_score INT,
    review_comment_title VARCHAR,
    review_comment_message VARCHAR,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reviews_full_order_id
    ON order_reviews_full(order_id);


-- ============================================================
-- 06) PRODUCTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR PRIMARY KEY,
    product_category_name VARCHAR,
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE INDEX IF NOT EXISTS idx_products_category
    ON products(product_category_name);


-- ============================================================
-- 07) SELLERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS sellers (
    seller_id VARCHAR PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR,
    seller_state VARCHAR(2)
);

CREATE INDEX IF NOT EXISTS idx_sellers_state
    ON sellers(seller_state);
