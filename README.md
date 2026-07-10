# SQL Business Insights

This repository is a compact SQL analytics case study built on an e-commerce style schema. It contains 10 business-focused SQL queries, schema reconnaissance notes, and written interpretations that explain not just what each query returns, but why the logic matters for decision-making.

## Project Goal

The project is designed to answer practical business questions across:

- Revenue performance
- Customer retention
- Funnel conversion
- Product and category health
- Payments and delivery operations
- Customer lifetime value
- Repeat purchase behavior
- Marketing attribution

The SQL favors analyst-friendly patterns such as CTEs, filtered aggregates, window functions, percentile calculations, and explicit sanity checks.

## Repository Structure

```text
.
|-- README.md
|-- INTERPRETATIONS.md
|-- case_study_link.md
|-- notes/
|   `-- ecom_schema.md
`-- queries/
    |-- 01_daily_business_summary.sql
    |-- 02_monthly_signup_cohort_retention.sql
    |-- 03_funnel_conversion_by_channel.sql
    |-- 04_top_products_by_net_revenue.sql
    |-- 05_category_health_purchases_returns.sql
    |-- 06_payment_failure_rate.sql
    |-- 07_delivery_sla_breach.sql
    |-- 08_customer_ltv_bucket_share.sql
    |-- 09_repeat_purchase_interval.sql
    `-- 10_attribution_first_vs_last.sql
```

## Data Context

The analysis assumes an `ecom` schema with production-like tables for customers, orders, order items, sessions, events, shipments, returns, payments, and attribution. Based on the schema notes:

- `orders` contains about 40,000 rows.
- `session_events` contains about 292,903 rows.
- `sessions` and `attribution_touches` each contain about 100,000 rows.
- The repo mixes commercial, operational, and marketing analytics in one schema.

## Important Data Caveats

These assumptions show up repeatedly in the SQL and are important for interpreting results correctly:

- `orders.status` and `orders.payment_status` are different concepts.
  Use `payment_status` for conversion/payment logic and `status` for fulfillment lifecycle logic.
- `session_events` coverage starts on `2026-04-19`.
  Funnel analysis should stay inside the instrumented period.
- `orders.total` may not equal `sum(order_items.line_total)`.
  Revenue definitions must be stated explicitly because shipping, discounts, refunds, or taxes may create differences.
- Some categorical fields need normalization.
  Examples include mixed-case order statuses and inconsistent missing values.
- Refunds are stored at the order level in some workflows.
  Product-level net revenue therefore requires allocation logic rather than a direct join.

## Query Guide

### 1. Daily Business Summary

File: [queries/01_daily_business_summary.sql](queries\01_daily_business_summary.sql)

Tracks daily revenue, orders, AOV, paid-order rate, cancelled-order rate, refunds, and compares revenue versus yesterday and the same weekday last week. This is the top-level trading view for monitoring short-term business performance.

### 2. Monthly Signup Cohort Retention

File: [queries/02_monthly_signup_cohort_retention.sql](queries\02_monthly_signup_cohort_retention.sql)

Builds signup cohorts by customer creation month and measures Month 1, Month 2, and Month 3 retention based on subsequent non-cancelled orders. It is useful for understanding whether acquisition quality or onboarding effectiveness is improving over time.

### 3. Funnel Conversion by Acquisition Channel

File: [queries/03_funnel_conversion_by_channel.sql](queries\03_funnel_conversion_by_channel.sql)

Measures session progression from product view to add to cart to checkout to purchase, grouped by acquisition channel. The query uses filtered distinct counts to compute the whole funnel in one pass over event data.

### 4. Top Products by Net Revenue After Refunds

File: [queries/04_top_products_by_net_revenue.sql](queries\04_top_products_by_net_revenue.sql)

Ranks products by net revenue after allocating order-level refunds back to products proportionally. This helps separate high-selling products from genuinely profitable ones.

### 5. Category Health: Purchases to Returns

File: [queries/05_category_health_purchases_returns.sql](queries\05_category_health_purchases_returns.sql)

Compares category revenue, unit volume, and return behavior. It is a fast way to spot categories that look strong on sales but weak on post-purchase satisfaction.

### 6. Payment Failure Analysis

File: [queries/06_payment_failure_rate.sql](queries\06_payment_failure_rate.sql)

Measures payment attempts and failures by method, then identifies the dominant error code for each method. It is aimed at revenue recovery and checkout reliability analysis.

### 7. Delivery SLA Breach by Carrier and Shipping Method

File: [queries/07_delivery_sla_breach.sql](queries\07_delivery_sla_breach.sql)

Calculates average, median, and p90 delivery times plus late-delivery rates against a 5-day SLA. It focuses on operational consistency, not just averages, by using percentile metrics.

### 8. Customer LTV and Revenue Concentration

File: [queries/08_customer_ltv_bucket_share.sql](queries\08_customer_ltv_bucket_share.sql)

Aggregates customer-level revenue and orders, assigns customers into LTV buckets, and measures the share of total revenue contributed by each bucket. This is helpful for identifying Pareto-style concentration in the customer base.

### 9. Repeat Purchase Interval

File: [queries/09_repeat_purchase_interval.sql](queries\09_repeat_purchase_interval.sql)

Uses `lead()` to calculate days until the next order for each customer and supports analysis both including and excluding same-day repeat orders. This helps estimate realistic win-back timing.

### 10. First-Touch vs Last-Touch Attribution

File: [queries/10_attribution_first_vs_last.sql](queries\10_attribution_first_vs_last.sql)

Compares revenue and order share by channel under first-touch and last-touch attribution models. Because touches do not contain `order_id`, the logic is intentionally customer-level rather than order-level.

## Supporting Notes

- [notes/ecom_schema.md](/notes\ecom_schema.md) documents table inventory, column-level notes, verified relationships, and schema caveats.
- [INTERPRETATIONS.md](INTERPRETATIONS.md) contains plain-English explanations for each query.
- [case_study_link.md](case_study_link.md) stores the external case study link.

## SQL Techniques Used

- Common table expressions for stepwise logic
- `count(*) filter (where ...)` for compact metric derivation
- Window functions such as `lag()`, `lead()`, and `row_number()`
- Percentile calculations with `percentile_cont()`
- Null-safe division with `nullif()`
- Cohort analysis using month offsets
- Proportional refund allocation for product-level net revenue

## How To Use This Repo

1. Start with [notes/ecom_schema.md](notes\ecom_schema.md) to understand table grain and join reliability.
2. Run the SQL files in numerical order if you want a business walkthrough from topline performance to attribution.
3. Use [INTERPRETATIONS.md](INTERPRETATIONS.md) as the narrative companion when presenting results.
4. Adapt the queries to your own schema by replacing the `ecom` namespace and validating the assumptions called out in each file header.

## Author

Prathamesh D S
