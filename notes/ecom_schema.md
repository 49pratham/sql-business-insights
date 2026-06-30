## A. Table Inventory

| table | approx_rows | what it stores | grain |
|---|---:|---|---|
| addresses |  | reusable address records such as shipping or billing locations | one row per address |
| attribution_campaigns |  | bridge or mapping table between attribution data and campaign entities | one row per attribution campaign mapping |
| attribution_touches |  | marketing touchpoints tied to sessions, customers, or orders for attribution analysis | one row per attribution touch |
| brands |  | brand master data for products | one row per brand |
| categories |  | product category master data | one row per category |
| collection_products |  | mapping between collections and products | one row per collection-product pair |
| collections | 0 | collection metadata for grouped product sets | one row per collection |
| consents |  | customer consent or preference records | one row per consent event or consent state |
| coupons |  | coupon definitions and codes used in promotions | one row per coupon |
| customer_addresses |  | link between customers and saved addresses | one row per customer-address relationship |
| customer_segments |  | segment definitions used for marketing or CRM targeting | one row per segment |
| customers |  | customer master data and signup-level information | one row per customer |
| devices |  | device reference or tracked device-level metadata | one row per device |
| experiment_assignments |  | assignments of users or sessions into experiments/variants | one row per assignment |
| experiment_variants |  | variant definitions for experiments | one row per variant |
| experiments |  | A/B test or experiment definitions | one row per experiment |
| inventory_items |  | inventory tracked at SKU or stock-item level | one row per inventory item |
| inventory_movements |  | stock increases, decreases, or transfers over time | one row per inventory movement |
| loyalty_accounts |  | loyalty program account records for customers | one row per loyalty account |
| loyalty_transactions |  | earn, burn, or adjustment events in loyalty balances | one row per loyalty transaction |
| marketing_campaigns |  | campaign master data for marketing initiatives | one row per marketing campaign |
| notifications |  | outbound communication records such as sends or alerts | one row per notification |
| order_items |  | line items contained within customer orders | one row per order item |
| order_refunds |  | order-level refund linkage or breakdown data | one row per order refund record |
| order_status_history |  | historical changes in order status over time | one row per order status change |
| orders |  | order-level commercial and lifecycle data | one row per order |
| payment_intents |  | payment attempt or intent records linked to orders | one row per payment intent |
| payment_methods |  | payment method reference data | one row per payment method |
| payment_transactions |  | transaction-level payment attempts, captures, or failures | one row per payment transaction |
| price_lists |  | named pricing schedules or catalogs | one row per price list |
| prices |  | product or variant pricing records | one row per price record |
| product_images |  | image metadata associated with products | one row per product image |
| product_reviews |  | customer-submitted product reviews and ratings | one row per review |
| product_variants |  | SKU- or variant-level product records | one row per product variant |
| products |  | product master data | one row per product |
| promotion_rules |  | rule logic behind promotions or discounts | one row per promotion rule |
| promotions |  | promotion definitions and campaign offers | one row per promotion |
| refunds |  | refund transactions issued against orders | one row per refund |
| return_items |  | item-level detail for returned products | one row per returned item |
| return_reasons |  | return reason reference data | one row per return reason |
| return_requests |  | return requests initiated by customers | one row per return request |
| segment_memberships |  | customer membership in segments | one row per customer-segment membership |
| session_channels |  | derived or curated acquisition channel per session | one row per session |
| session_events | 292903 | instrumented event stream for onsite funnel behavior | one row per session event |
| sessions |  | browsing or app sessions | one row per session |
| shipments |  | shipment and delivery records for orders | one row per shipment |
| shipping_carriers |  | carrier reference data | one row per shipping carrier |
| shipping_methods |  | shipping service or method reference data | one row per shipping method |


## B. Per-Column Notes

### orders

- `order_id`: primary identifier for the order; joins to `order_items.order_id`, `shipments.order_id`, `payment_intents.order_id`, and likely refund / return tables.
- `customer_id`: identifies the customer who placed the order; joins to `customers.customer_id`.
- `created_at`: order creation timestamp; The main date field for daily and monthly order trends.
- `status`: operational / fulfillment status. Observed values include `delivered`, `shipped`, `paid`, `packed`, `cancelled`, `placed`, plus mixed-case variants like `SHIPPED`, `DELIVERED`, and `Shipped`. Normalize with `lower(status)` before grouping or filtering.
- `payment_status`: payment outcome field, distinct from fulfillment status. Observed values include `paid` and `failed`. Use this for payment conversion logic, not `status`.
- `total`: order-level revenue amount. Do not assume it always matches `sum(order_items.line_total)` without matched filters and definition checks.
- `session_id`: Links the order back to a browsing session when populated; useful for attribution / funnel analysis if coverage is reliable.

### order_items

- `order_id`: foreign key to `orders.order_id`; orphan check returned `0`, so this join appears structurally reliable.
- `variant_id`: links the purchased item to product catalog tables.
- `qty`: quantity of units purchased in the line item.
- `unit_price`: per-unit selling price at time of purchase.
- `line_total`: line-level revenue amount; useful for product and category analysis, but not automatically interchangeable with `orders.total`.

### customers

- `customer_id`: primary identifier for a customer; joins to `orders.customer_id` and `sessions.customer_id`.
- `created_at`: signup timestamp; The correct anchor for customer cohort analysis.
- `country`: customer country field with inconsistent missing-value representation. Observed missing forms include `NULL`, blank string, and `'N/A'`; normalize before grouping.
- `first_name`: user-entered text field; may require trimming or cleaning if used in reporting.
- `dob`: if used later, should be checked for unrealistic or sentinel dates before age-based analysis.

### sessions

- `session_id`: primary identifier for the session; joins to `session_events.session_id`, `session_channels.session_id`, and possibly `attribution_touches.session_id`.
- `customer_id`: links known sessions to customers when available.
- `started_at`: session start timestamp; important for funnel windows and attribution timing.
- `device_id`: may connect sessions to device-level analysis if needed later.

### session_events

- `event_id`: primary identifier for the event row.
- `session_id`: foreign key to `sessions.session_id`; core join for funnel analysis.
- `occurred_at`: event timestamp. Observed coverage starts on `2026-04-19` and runs through `2026-06-14`, so event-based analysis should stay within the instrumented period.
- `event_type`: core funnel field. Values include stages like `product_view`, `add_to_cart`, `add_address`, `add_payment`,`select_shipping`, `begin_checkout` and `purchase`,

- Grain: one row per event generated within a session.

### payment_intents

- `payment_intent_id`: primary identifier for the payment attempt / intent.
- `order_id`: links payment behavior back to the order.
- `payment_method_id`: categorical field used for payment-method analysis; should be profiled for distinct values.
- `status`: Tracks the lifecycle of the payment attempt and should be distinguished from `orders.payment_status`.
- `created_at`: timestamp of payment initiation or attempt.

### shipments

- `shipment_id`: primary identifier for the shipment.
- `order_id`: joins shipment activity back to the order.
- `shipped_at`: shipment dispatch timestamp; starting point for delivery SLA calculation.
- `delivered_at`: delivery completion timestamp; exclude null values when analyzing completed deliveries.
- `carrier_id`: shipping carrier dimension for SLA breakdowns.
- `shipping_method_id`: service level or shipping type used for operational cuts.
- Data quality note: `shipped_at > delivered_at` check returned `0`, which is a good initial sign for timestamp sanity.

### attribution_touches

- `touch_id`: primary identifier for the marketing touch.
- `session_id`: links touches to sessions for session-level attribution.
- `channel`: key marketing dimension for first-touch / last-touch analysis; profile distinct values before use.
- `touched_at`: timestamp used to sequence touches for attribution modeling.


## C. Verified Relationships

- `order_items -> orders` on `order_id`: orphan check returned `0`, so this looks like a reliable one-to-many relationship for product and category analysis.
- `orders -> customers` on `customer_id`: this should be treated as a core customer-to-order relationship and is verified with an orphan check.
- `shipments -> orders` on `order_id`: operationally important for delivery SLA work; timestamp sanity looks good from the `shipped_at > delivered_at` check returning `0`.
- `session_events -> sessions` on `session_id`: important for funnel analysis, but event coverage only begins on `2026-04-19`, so this relationship is only analytically useful in the instrumented period.
- `orders` uses both `payment_status` and `status`, which means structurally valid joins still require semantic care when defining business outcomes or filtering conversions.

## D. ER Diagram
erDiagram
    customers          ||--o{ orders : places
    orders             ||--|{ order_items : contains
    order_items        }o--|| product_variants : ships
    product_variants   }o--|| products : sku_of
    products           }o--|| categories : in
    orders             ||--o{ payment_intents : pays_via
    payment_intents    ||--o{ payment_transactions : attempts
    orders             ||--o{ refunds : may_have
    orders             ||--o{ return_requests : may_return
    return_requests    ||--|{ return_items : with
    orders             ||--o{ shipments : ships
    customers          ||--o{ sessions : starts
    sessions           ||--o{ session_events : logs
    sessions           ||--o{ attribution_touches : has
    attribution_touches }o--o| attribution_campaigns : maps_via_bridge
    attribution_campaigns }o--|| marketing_campaigns : refs

## E. Five Things That Surprised Me

- `orders.status` and `orders.payment_status` are doing two different jobs, and that is easy to miss if you move too fast. From the distributions, `payment_status` is basically the conversion outcome, while `status` tracks where the order is in the fulfillment lifecycle. That matters because using `status = 'paid'` as a proxy for successful payment would be logically wrong in some analyses. My rule is to use `payment_status` for conversion logic and `status` for operational or fulfillment logic.

- The order-item relationship looks cleaner than I expected. My orphan check for `order_items -> orders` came back as `0`, which means every order item I checked has a parent order. That does not guarantee every metric is perfect, but it does make product and category analysis much more trustworthy because I am not leaking line items outside the order table.

- `session_events` is large enough to be useful but narrow enough in date range that time-based comparisons need care. With `292,903` events over a window from `2026-04-19` to `2026-06-14`, the table is clearly active, but only for the post-instrumentation period. That means any funnel trend, conversion baseline, or channel comparison has to stay inside that coverage window to be credible.

- The revenue mismatch between `orders.total` and `order_items.line_total` is probably the most important analytical warning sign in the schema so far. In a real business environment, this kind of gap often comes from shipping fees, discounts, refunds, tax treatment, or order-level amounts that do not roll cleanly down to item rows. That matters because a query can be technically correct and still answer a different revenue question than the one you think you are answering. I need to define the revenue base explicitly in every query that touches money.

- The data already shows signs of normal production messiness rather than textbook cleanliness. Between mixed-case statuses, inconsistent missing values, empty feature tables, and revenue-definition ambiguity, the main lesson is that query correctness here depends as much on business logic and cleaning rules as on SQL syntax. That is probably the biggest Day 1 takeaway.

## Additional Recon Notes

- Shipment timestamps look sane on the most obvious data-quality test. I found `0` cases where `shipped_at > delivered_at`, which means the classic impossible timeline is not showing up here. That matters for Q7 because delivery SLA analysis depends heavily on timestamp quality. I still need to exclude `delivered_at is null` for in-transit shipments, but at least completed deliveries are not immediately failing the simplest logic check.

- The schema includes tables that look like product or marketing features at different stages of maturity. Some are empty, some are populated, and some seem more like future-facing scaffolding than active sources. That is actually realistic for a production-like schema. It means I should think of the database as a living system with abandoned or half-adopted features, not a perfectly curated teaching dataset.

- Empty tables were a useful reminder that not every table in the ER diagram deserves equal attention. It is tempting to over-document everything because it exists in the schema, but the better analyst move is to separate "present in schema" from "actually used in analysis." That will save time later when deciding which join paths are worth trusting and which are just product leftovers.