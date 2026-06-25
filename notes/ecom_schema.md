# Ecom Schema Notes


## A. Table Inventory

| Table | Approx Rows | Grain | Description | Important Columns |
|--------|------------:|-------|-------------|-------------------|
| addresses | | One row per address | Stores customer addresses | address_id, city, state, country |
| attribution_campaigns | | One row per touch-campaign mapping | Links attribution touches to campaigns | touch_id, campaign_id |
| attribution_touches | | One row per marketing touch | Stores marketing attribution events | touch_id, session_id, channel |
| brands | | One row per brand | Product brands | brand_id, brand_name |
| categories | | One row per category | Product categories | category_id, parent_id |
| collection_products | | One row per product in collection | Bridge table | collection_id, product_id |
| collections | | One row per collection | Product collections | collection_id, collection_name |
| consents | | One row per customer consent | Privacy and consent records | consent_id, customer_id |
| coupons | | One row per coupon | Coupon master | coupon_id, code |
| customer_addresses | | One row per customer-address mapping | Bridge table | customer_id, address_id |
| customer_segments | | One row per segment | Customer segmentation | segment_id, segment_name |
| customers | | One row per customer | Customer master table | customer_id, primary_email |
| devices | | One row per device | Device information | device_id, device_type |
| experiment_assignments | | One row per experiment assignment | A/B test assignments | experiment_id, session_id |
| experiment_variants | | One row per variant | Experiment variants | variant_id |
| experiments | | One row per experiment | Experiment definitions | experiment_id |
| inventory_items | | One row per warehouse-variant | Current inventory | warehouse_id, variant_id |
| inventory_movements | | One row per inventory movement | Stock movement history | movement_id |
| loyalty_accounts | | One row per customer | Loyalty account | customer_id |
| loyalty_transactions | | One row per loyalty transaction | Points earned/spent | loyalty_txn_id |
| marketing_campaigns | | One row per campaign | Marketing campaigns | campaign_id |
| notifications | | One row per notification | Customer notifications | notification_id |
| order_items | | One row per order item | Order line items | order_id, variant_id |
| order_refunds | | One row per refunded order | Order refund summary | order_id |
| order_status_history | | One row per status change | Order status timeline | order_id, status |
| orders | | One row per order | Main order table | order_id, customer_id |
| payment_intents | | One row per payment attempt | Payment intent records | payment_intent_id |
| payment_methods | | One row per payment method | Payment methods | payment_method_id |
| payment_transactions | | One row per payment transaction | Gateway transactions | txn_id |
| price_lists | | One row per price list | Price list metadata | price_list_id |
| prices | | One row per variant price | Product pricing | variant_id |
| product_images | | One row per image | Product images | product_id |
| product_reviews | | One row per review | Customer reviews | review_id |
| product_variants | | One row per variant | Product variants | variant_id |
| products | | One row per product | Product catalog | product_id |
| promotion_rules | | One row per rule | Promotion rules | rule_id |
| promotions | | One row per promotion | Promotion master | promo_id |
| refunds | | One row per refund | Refund records | refund_id |
| return_items | | One row per returned item | Return line items | return_id |
| return_reasons | | One row per reason | Return reasons | reason_id |
| return_requests | | One row per return request | Customer returns | return_id |
| segment_memberships | | One row per customer-segment | Customer segmentation membership | customer_id |
| session_channels | | One row per session channel | Session marketing channel | session_id |
| session_events | | One row per event | User event stream | event_id, session_id |
| sessions | | One row per session | User sessions | session_id |
| shipments | | One row per shipment | Shipment information | shipment_id |
| shipping_carriers | | One row per carrier | Shipping carriers | carrier_id |
| shipping_methods | | One row per method | Shipping methods | shipping_method_id |

---

## B. Approximate Row Counts

| Table | Approx Rows |
|--------|------------:|
| session_events | 292,903 |
| order_status_history | 158,414 |
| experiment_assignments | 140,670 |
| attribution_touches | 100,000 |
| sessions | 100,000 |
| devices | 85,168 |
| order_items | 81,806 |
| payment_transactions | 40,034 |
| orders | 40,000 |
| payment_intents | 40,000 |
| attribution_campaigns | 38,405 |
| shipments | 32,089 |
| inventory_movements | 30,207 |
| prices | 24,180 |
| loyalty_transactions | 21,475 |
| segment_memberships | 16,461 |
| addresses | 16,000 |
| customer_addresses | 16,000 |
| product_variants | 12,090 |
| customers | 10,000 |
| product_reviews | 8,000 |
| product_images | 7,188 |
| notifications | 6,856 |
| products | 4,000 |
| loyalty_accounts | 3,000 |
| return_items | 2,004 |
| inventory_items | 2,000 |
| return_requests | 1,603 |
| refunds | 260 |
| brands | 120 |
| marketing_campaigns | 100 |
| coupons | 50 |
| promotion_rules | 30 |
| promotions | 20 |
| categories | 18 |
| experiment_variants | 12 |
| customer_segments | 10 |
| return_reasons | 8 |
| experiments | 6 |
| payment_methods | 5 |
| shipping_methods | 3 |
| shipping_carriers | 3 |
| price_lists | 2 |
| collections | 0 |
| collection_products | 0 |
| consents | 0 |
---

# C. Foreign Keys


# D. Categorical Columns

## orders.status

| Status | Count |
|--------|------:|
| delivered | 19,779 |
| shipped | 7,715 |
| paid | 3,946 |
| packed | 3,887 |
| cancelled | 2,178 |
| placed | 1,897 |
| SHIPPED | 248 |
| DELIVERED | 200 |
| Shipped | 150 |


## orders.payment_status

| Payment Status | Count |
|---------------|------:|
| paid | 37,822 |
| failed | 2,178 |

## orders.price_list_id

| Price List ID | Count |
|--------------:|------:|
| 1 | 36,794 |
| 2 | 3,206 |


## payment_transactions.payment_status

| Payment Status | Count |
|---------------|------:|
| succeeded | 38,134 |
| failed | 1,900 |


## payment_transactions.gateway
| Gateway | Count |
|---------|------:|
| razorpay | 18,072 |
| payu | 9,948 |
| stripe | 7,239 |
| cash | 4,775 |

## session.device_id
| Device ID | Count |
|----------:|------:|
| 141564 | 6 |
| 178497 | 5 |
| 182935 | 5 |
| 152093 | 5 |
| 165854 | 5 |
| 88234 | 5 |
| 54279 | 5 |
| 92633 | 5 |
| 204205 | 5 |
| 217705 | 4 |
| 245046 | 4 |
| 247032 | 4 |
| 215889 | 4 |
| ... | ... |

## customers.country
| Country | Count |
|---------|------:|
| India | 7,641 |
| United States | 1,359 |
| *(empty string)* | 500 |
| N/A | 300 |
| *(whitespace only)* | 200 |
