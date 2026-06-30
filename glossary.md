## Q1 — Daily Business Summary with DoD and Same-Weekday WoW

**What the query does :** Aggregates daily order performance over the last 90 days, including revenue, orders, AOV, paid-order rate, cancelled-order rate, refunds, and revenue change versus yesterday and the same weekday last week.

**Pattern choice:** Used daily aggregation from `orders`, a separate refunds CTE to avoid mixing sales and refund logic in one pass, and `lag(..., 1)` / `lag(..., 7)` to compare each day with the previous day and the same weekday last week. The same-weekday comparison is more decision-useful than plain day-over-day because ecommerce demand usually varies by weekday.

**Business interpretation:** This query works like a daily health dashboard for the business: revenue movement matters, but only in the context of order volume, AOV, payment success, cancellations, and refunds. A day with strong revenue but worsening paid-order rate or higher cancellation/refund leakage is not necessarily healthy growth, because the top line can hide operational weakness. The week-over-week same-weekday comparison is especially useful here because it helps separate real business movement from normal weekly seasonality.

**What I'd ask next:** On the biggest up and down days, was the change driven more by order volume, basket size, payment conversion, or cancellation/refund leakage?

## Q2 — Monthly Signup Cohort Retention

**What the query does :** Groups customers by signup month and measures how many return to place a non-cancelled order in months 1, 2, and 3 after signup.

**Pattern choice :** Used `customers.created_at` to define monthly signup cohorts and joined those customers to later order months to calculate month-offset retention. Censored future cells are shown as `NULL` rather than `0`, so recent cohorts are not treated as if they had already had a full observation window.

**Business interpretation :** The earliest fully observed cohort retained best, while later cohorts weakened more quickly after signup, especially by month 2. That suggests retention is not only decaying naturally over time, but may also be sensitive to acquisition quality, onboarding, or product mix. The blank cells in recent cohorts are a timing limitation, not a performance failure, so they should not be interpreted as zero retention.

**What I'd ask next:** Did acquisition channel, discount usage, or first-purchase category shift enough across cohorts to explain why later cohorts retained worse?

## Q3 — Funnel Conversion by Acquisition Channel

**What the query does :** Aggregates sessions through the product-view → add-to-cart → checkout → purchase funnel, split by acquisition channel for the instrumented event period.

**Pattern choice :** Used one pass over `session_events` to create stage flags per session and joined those flags to `session_channels` for attribution, rather than repeatedly joining raw event data. This keeps the logic at the session grain, avoids row explosion, and makes the funnel easier to audit.

**Business interpretation:** Organic and paid drive the most absolute purchase volume, but conversion efficiency is surprisingly similar across channels. The biggest drop happens between product view and add to cart for every channel, while checkout-to-purchase conversion is very strong once customers reach the end of the funnel. That suggests the main commercial bottleneck is in merchandising or product-page persuasion, not in checkout or payment.

**What I'd ask next:** What product, pricing, or merchandising factors are causing such a large drop between product view and add to cart in the highest-volume channels?

## Q4 — Top Products by Net Revenue (After Refunds)

**What the query does:** Ranks products by net revenue after combining item-level sales with product-level returns and proportionally allocated order-level refunds.

**Pattern choice :** Built separate CTEs for product sales, returns, and refunds rather than trying to do everything in one join, which avoids double-counting. Because refunds exist at the order level rather than the item level, each order refund was allocated across that order’s items in proportion to `line_total`, giving a defensible product-level estimate of refund leakage.

**Business interpretation:** The top net-revenue products are concentrated in core categories such as headphones and smartwatches, which appear to be the catalog’s commercial anchors. Most leading products have relatively low return rates, but some still lose meaningful value once refunds are allocated, which shows that gross revenue alone can overstate product quality. The strongest products are therefore the ones that not only sell well, but also hold onto revenue after post-purchase leakage.

**What I'd ask next:** Which products lose the most rank when moving from gross revenue to net revenue, and is that driven more by refunds or by returns?

## Q5 — Category Health: Purchases → Returns

**What the query does:** Aggregates paid, non-cancelled order-item sales to the category level and compares category revenue with category-level return counts and return rates.

**Pattern choice :** Built sales and returns in separate CTEs and joined them at the category level instead of mixing item sales with return records in one large join, which avoids duplication. The category mapping runs through `order_items → product_variants → products → categories`, matching the schema grain cleanly.

**Business interpretation :** Revenue is concentrated in a small set of categories led by smartwatches, headphones, and speakers, and those top categories do not appear to have unusually high return rates. Most categories sit in a fairly narrow return-rate band, which suggests the bigger business difference across categories is scale rather than radically different product quality. Accessories stands out as a smaller but more return-prone category, making it a good candidate for deeper SKU-level investigation.

**What I'd ask next:** Are the higher-return categories being driven by a few problematic SKUs, or is return behavior spread broadly across the category?

## Q6 — Payment Failure Rate by Payment Method

**What the query does:** Measures payment attempts, successful payments, failed payments, failure rate, and the most common failure error code for each payment method.

**Pattern choice :** Split the problem into a payment-method summary CTE and a ranked error-code CTE, then used `row_number()` to pick the top failure reason per method. This is the cleanest way to solve the top-error-per-group problem without losing error-level detail too early.

**Business interpretation:** This query highlights whether any payment method is materially weaker than the others and whether its failures are concentrated in a small set of error codes. If one method combines high payment volume with a high failure rate, it becomes a much more urgent commercial issue than a niche method with similar relative failure. A concentrated top error code would usually suggest a fixable gateway, routing, or integration problem rather than broad customer drop-off.

**What I'd ask next:** Which payment method causes the highest commercial loss once failure rate is combined with payment volume and attempted revenue?

## Q7 — Delivery SLA Breach by Carrier × Shipping Method

**What the query does:** Measures delivered orders by carrier and shipping method, then calculates average, median, p90 delivery time, and the share of shipments that breached the 5-day SLA.

**Pattern choice:** Calculated `delivery_days` from `shipped_at` and `delivered_at`, filtered to completed deliveries only, and used `percentile_cont` to capture both median and p90 delivery performance. This gives a better operational view than averages alone because customer pain is often concentrated in the slow tail rather than in the mean.

**Business interpretation:** Carrier performance is not uniform: some carrier-method combinations look acceptable on average but still show meaningful tail risk in p90 delivery time and late rate. EcomExpress appears weakest overall, especially on `express` and `same_day`, while Delhivery looks strongest, particularly on `standard`, with the lowest late rate and best average delivery time. The result shows that the real operational question is not just “who is fastest on average,” but “who is least likely to create bad delivery experiences at the tail.”

**What I'd ask next:** Are the worst late-rate combinations concentrated in specific regions, hubs, or service zones, or is the weakness consistent across the network?

## Q8 — Customer LTV + Bucket Share of Revenue

**What the query does :** Calculates customer-level lifetime value from non-cancelled orders, assigns each customer to an LTV bucket, and measures how much of total revenue each bucket contributes.

**Pattern choice:** First aggregated order history to one row per customer, then bucketed customers by total revenue and used a window function to calculate each bucket’s share of overall revenue. This keeps the customer grain intact while still surfacing the concentration of value across spend tiers.

**Business interpretation:** Revenue is highly concentrated in the highest-value customer bucket, with the `20000+` segment contributing the overwhelming majority of total revenue. That means the business depends disproportionately on a relatively small group of heavy spenders, making VIP retention and repeat-purchase strategy especially important. The practical implication is that losing a few high-LTV customers would have a much larger impact than small changes in lower-value segments.

**What I'd ask next:** Are the highest-LTV customers concentrated in specific channels, product categories, or geographies that could inform retention and loyalty strategy?

## Q9 — Repeat Purchase Interval

**What the query does :** Measures the time between one non-cancelled order and the next order for the same customer, then summarizes repeat-purchase timing for win-back planning.

**Pattern choice:** Used `lead(...)` over customer order history to identify the next purchase date for each order. Same-day repeat orders were kept in the row-level output for transparency, but excluded from the summary because they likely reflect split-order behavior rather than a true customer return cycle.

**Business interpretation:** Repeat behavior is relatively fast in this dataset: the median repeat customer comes back in 6 days, while the p90 interval is 27 days. The average is higher than the median, which suggests a right-skewed pattern with a core of fast repeaters and a smaller long-tail group of slower-returning customers. That makes this business look more like a frequent-repeat ecommerce model than a long-consideration purchase cycle.

**What I'd ask next:** Does repeat timing differ meaningfully by category, channel, or LTV bucket, and should win-back timing be segmented instead of using one default trigger?

## Q10 — Attribution Comparison: First-Touch vs Last-Touch Revenue by Channel

**What the query does:** Compares channel-attributed revenue and order volume under first-touch and last-touch attribution for non-cancelled orders.

**Pattern choice :** Joined non-cancelled orders to attribution touches through `session_id` and used `row_number()` to identify the earliest and latest touch per order. This preserves the same underlying revenue base while allowing the same orders to be reallocated under two attribution models.

**Business interpretation:** In this dataset, first-touch and last-touch attribution produce identical results because almost every order has exactly one recorded attribution touch. That means the data behaves like a single-touch attribution model in practice, so there is no meaningful distinction here between channels that open demand and channels that close it. Organic and paid dominate attributed revenue, while direct contributes only a very small share of total non-cancelled order revenue.

**What I'd ask next:** If the business wants a meaningful multi-touch attribution view, are additional pre-conversion touchpoints being captured anywhere outside the current `attribution_touches` table?