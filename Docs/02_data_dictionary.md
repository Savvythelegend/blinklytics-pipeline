# Data Dictionary

## Input Tables

### `all_blinkit_category_scraping_stream`
| Column         | Description                                |
|----------------|--------------------------------------------|
| `created_at`   | Timestamp of the data snapshot.            |
| `store_id`     | Dark store ID.                             |
| `sku_id`       | SKU identifier.                            |
| `sku_name`     | SKU name.                                  |
| `selling_price`| Selling price at the time of snapshot.     |
| `mrp`          | Maximum Retail Price of the SKU.           |
| `inventory`    | Current inventory quantity.                |
| `brand_id`     | Unique brand identifier.                   |
| `brand`        | Brand name.                                |
| `l1_category_id` | Top-level category ID.                   |
| `l2_category_id` | Sub-category ID.                         |
| `unit`         | Unit of measure (e.g., g, ml).             |

### `blinkit_categories`
| Column          | Description                               |
|-----------------|-------------------------------------------|
| `l1_category_id`| Top-level category ID.                    |
| `l1_category`   | Top-level category name.                  |
| `l2_category_id`| Sub-category ID.                          |
| `l2_category`   | Sub-category name.                        |

### `blinkit_city_map`
| Column          | Description                               |
|-----------------|-------------------------------------------|
| `store_id`      | Dark store ID.                            |
| `city_name`     | City corresponding to the store.          |

---

## Derived Table: `blinkit_city_insights`
| Column           | Description                              |
|------------------|------------------------------------------|
| `date`           | Snapshot date (aggregated).              |
| `city_name`      | City name.                               |
| `sku_id`         | SKU identifier.                          |
| `sku_name`       | SKU name.                                |
| `est_qty_sold`   | Estimated quantity sold.                 |
| `est_sales_sp`   | Estimated sales at selling price.        |
| `est_sales_mrp`  | Estimated sales at MRP.                  |
| `wt_osa`         | Weighted on-shelf availability (overall).|
| `wt_osa_ls`      | Weighted on-shelf availability (listed). |
| `discount`       | Effective discount = (MRP - SP) / MRP.   |
