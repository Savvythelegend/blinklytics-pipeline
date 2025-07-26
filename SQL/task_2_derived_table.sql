/*
===========================================================
 TASK 2: Final Derived Table with Inferred Sales
===========================================================
 Objective:
   1. Track inventory movements using LAG/LEAD to infer sales.
   2. Enrich with city/category metadata.
   3. Aggregate sales metrics for insights.
-----------------------------------------------------------
*/

DROP TABLE IF EXISTS blinkit_city_insights;

CREATE TABLE blinkit_city_insights AS

-- Step 1: Inventory Lagging to detect drops and restocks
WITH inventory_lagged AS (
    SELECT
        *,
        LEAD(inventory) OVER (PARTITION BY store_id, sku_id ORDER BY created_at) AS next_inventory,
        LAG(inventory) OVER (PARTITION BY store_id, sku_id ORDER BY created_at) AS prev_inventory_1,
        LAG(inventory, 2) OVER (PARTITION BY store_id, sku_id ORDER BY created_at) AS prev_inventory_2,
        LAG(inventory, 3) OVER (PARTITION BY store_id, sku_id ORDER BY created_at) AS prev_inventory_3,
        LEAD(created_at) OVER (PARTITION BY store_id, sku_id ORDER BY created_at) AS next_time
    FROM all_blinkit_category_scraping_stream
),

-- Step 2: Estimate quantity sold
-- Rules:
--   - Inventory drop → sales = inventory - next_inventory
--   - Inventory rise → restock event → median of last 3 drops (or avg if <3)
estimation AS (
    SELECT
        created_at::date AS date,
        store_id,
        sku_id,
        brand_id,
        brand,
        image_url,
        l1_category_id,
        l2_category_id,
        sku_name,
        selling_price,
        mrp,
        CASE
            WHEN inventory > next_inventory THEN inventory - next_inventory
            WHEN inventory < next_inventory THEN (
                SELECT
                    CASE
                        WHEN COUNT(drop_val) = 3 THEN
                            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY drop_val)
                        WHEN COUNT(drop_val) = 2 THEN
                            AVG(drop_val)
                        WHEN COUNT(drop_val) = 1 THEN
                            MAX(drop_val)
                        ELSE 0
                    END
                FROM UNNEST(ARRAY[
                    CASE WHEN prev_inventory_1 > inventory THEN prev_inventory_1 - inventory ELSE NULL END,
                    CASE WHEN prev_inventory_2 > prev_inventory_1 THEN prev_inventory_2 - prev_inventory_1 ELSE NULL END,
                    CASE WHEN prev_inventory_3 > prev_inventory_2 THEN prev_inventory_3 - prev_inventory_2 ELSE NULL END
                ]) AS drop_val
            )
            ELSE 0
        END AS est_qty_sold
    FROM inventory_lagged
    WHERE next_inventory IS NOT NULL
),

-- Step 3: Enrich with city & category data
enriched AS (
    SELECT
        e.*,
        c.city_name,
        cat.l1_category AS category_name,
        cat.l2_category AS sub_category_name
    FROM estimation e
    JOIN blinkit_city_map c
      ON e.store_id = c.store_id
    JOIN blinkit_categories cat
      ON e.l2_category_id = cat.l2_category_id
),

-- Step 4: Aggregate by SKU and city
aggregated AS (
    SELECT
        date,
        sku_id,
        MAX(brand_id) AS brand_id,
        MAX(brand) AS brand,
        MAX(image_url) AS image_url,
        city_name,
        MAX(category_name) AS category_name,
        MAX(l1_category_id) AS category_id,
        MAX(sub_category_name) AS sub_category_name,
        MAX(l2_category_id) AS sub_category_id,
        MAX(sku_name) AS sku_name,
        SUM(est_qty_sold) AS est_qty_sold,
        SUM(est_qty_sold * selling_price) AS est_sales_sp,
        SUM(est_qty_sold * mrp) AS est_sales_mrp,
        COUNT(DISTINCT store_id) AS listed_ds_count,
        (SELECT COUNT(DISTINCT store_id) FROM all_blinkit_category_scraping_stream) AS ds_count,
        ROUND(COUNT(*) FILTER (WHERE est_qty_sold > 0) * 1.0 / COUNT(DISTINCT store_id), 3) AS wt_osa_ls,
        ROUND(COUNT(*) FILTER (WHERE est_qty_sold > 0) * 1.0 /
              (SELECT COUNT(DISTINCT store_id) FROM all_blinkit_category_scraping_stream), 3) AS wt_osa,
        MODE() WITHIN GROUP (ORDER BY mrp) AS mrp,
        MODE() WITHIN GROUP (ORDER BY selling_price) AS sp
    FROM enriched
    GROUP BY date, sku_id, city_name
)

-- Step 5: Final Selection with Discount Calculation
SELECT
    *,
    ROUND(((mrp - sp) * 1.0 / NULLIF(mrp, 0))::numeric, 2) AS discount
FROM aggregated;
