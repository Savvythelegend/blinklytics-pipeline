/*
===========================================================
 TASK 1: Clean and Prepare Input Tables
===========================================================
 Objective:
   1. Deduplicate raw data while preserving the latest inventory snapshots.
   2. Prepare normalized tables for further processing in Task 2.
-----------------------------------------------------------
*/

-- 1. Create all_blinkit_category_scraping_stream table
--    Deduplicate based on (created_at, store_id, sku_id)
DROP TABLE IF EXISTS all_blinkit_category_scraping_stream;

CREATE TABLE all_blinkit_category_scraping_stream AS
SELECT DISTINCT ON (created_at, store_id, sku_id)
    created_at,
    l1_category_id,
    l2_category_id,
    store_id,
    sku_id,
    sku_name,
    selling_price,
    mrp,
    inventory,
    image_url,
    brand_id,
    brand,
    unit
FROM raw_all_blinkit_category_scraping_stream
WHERE created_at IS NOT NULL
  AND store_id IS NOT NULL
  AND sku_id IS NOT NULL
ORDER BY created_at, store_id, sku_id, inventory DESC;


-- 2. Create blinkit_categories table
--    Deduplicate on l2_category_id
DROP TABLE IF EXISTS blinkit_categories;

CREATE TABLE blinkit_categories AS
SELECT DISTINCT ON (l2_category_id)
       l1_category,
       l1_category_id,
       l2_category,
       l2_category_id
FROM raw_blinkit_categories
WHERE l2_category_id IS NOT NULL;


-- 3. Create blinkit_city_map table
--    Deduplicate on store_id
DROP TABLE IF EXISTS blinkit_city_map;

CREATE TABLE blinkit_city_map AS
SELECT DISTINCT ON (store_id)
       store_id,
       city_name
FROM raw_blinkit_city_map
WHERE store_id IS NOT NULL;
