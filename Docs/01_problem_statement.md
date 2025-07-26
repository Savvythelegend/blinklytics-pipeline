# Problem Statement

Blinkit, a hyperlocal delivery platform, lists thousands of SKUs across multiple dark stores and cities. While raw scraping data provides inventory snapshots over time, **it does not directly track sales**. The business requires actionable insights derived from these snapshots to estimate **daily sales, revenue, discounts, and on-shelf availability (OSA)** at the SKU and city levels.

### Key Challenges
- Inventory snapshots are not continuous, requiring **time-series analysis** to detect inventory drops (implying sales).
- Restock events (inventory rises) introduce complexity in sales estimation.
- Raw data contains duplicates and inconsistencies due to scraping intervals.
- No direct linkage between SKU inventory data and city-level mapping without data cleaning.

**Goal:**  
Design a robust **PostgreSQL-based data pipeline** that:
1. Cleans and deduplicates raw scraping data.
2. Detects inventory movements using SQL window functions.
3. Estimates sales (`est_qty_sold`) and aggregates revenue by city and SKU.
4. Produces a derived table `blinkit_city_insights` to power analytics dashboards.
