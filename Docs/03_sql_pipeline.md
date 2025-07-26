# SQL Pipeline

The PostgreSQL pipeline is built in **three stages** to convert raw scraped data into aggregated, actionable city-level insights.

---

## **Stage 1: Data Cleaning & Preparation**

* **Deduplication:**
  Removed duplicate SKU snapshots using `DISTINCT ON (created_at, store_id, sku_id)`.
* **Null Filtering:**
  Filtered out rows missing `created_at`, `store_id`, or `sku_id`.
* **Category & City Mapping:**
  Deduplicated and normalized `blinkit_categories` and `blinkit_city_map`.

**Core SQL Snippet:**

```sql
CREATE TABLE all_blinkit_category_scraping_stream AS
SELECT DISTINCT ON (created_at, store_id, sku_id)
    created_at,
    store_id,
    sku_id,
    ...
FROM raw_all_blinkit_category_scraping_stream
WHERE created_at IS NOT NULL
ORDER BY created_at, store_id, sku_id, inventory DESC;
```

---

## **Stage 2: Derived Insights & Sales Estimation**

* **Inventory Tracking with Window Functions:**
  Utilized `LAG()` and `LEAD()` to detect inventory drops or restocks for each SKU.
* **Sales Estimation Logic:**

  * If inventory dropped: `sales = current_inventory - next_inventory`.
  * If inventory increased (restock): Median of last 3 inventory drops is used as the estimate.
* **Time-Series Transformation:**
  Extracted daily-level SKU sales per city.

**Core SQL Snippet:**

```sql
SELECT
    created_at::date AS date,
    sku_id,
    CASE
        WHEN inventory > next_inventory THEN inventory - next_inventory
        WHEN inventory < next_inventory THEN ...
    END AS est_qty_sold
FROM inventory_lagged;
```

---

## **Stage 3: Aggregation & Reporting**

* **City-Level Aggregation:**
  Combined SKU sales with city and category metadata (`blinkit_city_map` and `blinkit_categories`).
* **Revenue and Discount Metrics:**
  Computed `est_sales_sp`, `est_sales_mrp`, and `discount` percentages.
* **Final Output:**
  The processed insights are stored in `blinkit_city_insights` and exported as `blinkit_city_insights.csv`.

**Core SQL Snippet:**

```sql
SELECT
    date,
    sku_id,
    SUM(est_qty_sold) AS est_qty_sold,
    SUM(est_qty_sold * selling_price) AS est_sales_sp,
    ROUND(((mrp - sp) * 1.0 / NULLIF(mrp, 0))::numeric, 2) AS discount
FROM enriched
GROUP BY date, sku_id, city_name;
```
