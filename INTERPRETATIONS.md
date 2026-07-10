# Executive SQL Analytics
This repo provides a comprehensive overview of the core analytical queries designed to track business performance, customer retention, checkout funnels, operations, and marketing attribution. Each section outlines the mechanics of the query, the design pattern choices made, concrete business interpretations, and strategic follow-up questions.

---

## Q1 — Revenue Trend Analysis

**What the query does :** Measures daily revenue, order volume, AOV, refund activity, and compares performance against both the previous day and the same weekday in the prior week.

**Pattern choice :** Used `date_trunc()` to aggregate order-level data into daily business metrics and lag() window functions to compute day-over-day (DoD) and same-weekday week-over-week (WoW) comparisons without requiring self-joins. This provides a clean view of short-term momentum while controlling for weekday seasonality.

**Business interpretation  :** Revenue peaked at ₹7.65M on April 5 before steadily declining to only ₹0.42M by June 14, representing a ~94% decline from peak levels, indicating a significant deterioration in demand or traffic acquisition. Order volume followed the same pattern, falling from 951 orders on April 5 to just 72 orders by June 14. Despite this collapse in volume, AOV remained relatively stable between ₹7k-8k on most days, suggesting that the business problem is primarily declining customer traffic rather than weakening customer spending behavior. Refunds remained comparatively small relative to revenue, although spikes above ₹50k occurred on April 9 and April 13, potentially indicating isolated operational or product issues.

**What I'd ask next:** Why did revenue decline by nearly 80-90% between April and June? Did marketing spend decrease, acquisition channels deteriorate, inventory go out of stock, or did a tracking issue emerge around this period?

---

## Q2 — Monthly Signup Cohort Retention

**What the query does :** Tracks how many customers from each signup cohort return to make purchases in subsequent months and measures retention decay over time.

**Pattern choice :** Used cohort analysis by grouping customers according to their signup month and calculating month offsets between signup and future purchases. Future months are intentionally shown as `0`/`NULL` equivalents rather than treated as churn, preventing newer cohorts from being unfairly penalized.

**Business interpretation :** The March cohort demonstrates the strongest retention, with 50% of customers returning in Month 1, 42% in Month 2, and 19% still active by Month 3. In contrast, the April cohort retains only 43% in Month 1 and drops sharply to 18% by Month 2, while the May cohort exhibits a particularly weak Month 1 retention rate of just 18%. This deterioration suggests that customer acquisition quality worsened materially over time, potentially due to changes in marketing mix, onboarding experience, or product-market fit. The June cohort has no observable retention yet because insufficient time has elapsed since signup, so treating it as churn would be misleading.

**What I'd ask next:** Which acquisition channels are responsible for the retention decline from 50% (March) to 18% (May)? Did marketing campaigns, promotions, pricing changes, or product assortment shift during this period?

---

## Q3 — Funnel Conversion by Acquisition Channel

**What the query does  :** Aggregates customer sessions through the product-view → add-to-cart → checkout → purchase funnel and compares performance across acquisition channels.

**Pattern choice :** Used `count(distinct session_id) filter (where ...)` to compute all funnel stages in a single pass over `session_events`, avoiding multiple self-joins and row explosion. This approach is both computationally efficient and easier to maintain as additional funnel stages are added.

**Business interpretation  :** Funnel efficiency is remarkably consistent across channels. Organic drives the largest volume with 19,539 sessions and 5,491 purchases, while Paid follows closely with 17,169 sessions and 4,806 purchases. Session-to-purchase conversion is nearly identical across all channels at 28-29%, indicating that differences in total purchases are driven primarily by traffic volume rather than channel quality. The largest drop-off occurs between product view and add-to-cart, where only 40-41% of visitors proceed, whereas checkout completion remains very strong at 85-87%, suggesting that product consideration and merchandising are bigger bottlenecks than checkout friction.

**What I'd ask next:**Why are nearly 60% of visitors abandoning before adding products to cart? Which products, landing pages, or acquisition campaigns exhibit the lowest view-to-cart rates, and can improvements in product content, pricing presentation, or recommendations materially improve funnel performance?

---

## Q4 — Top Products by Net Revenue (After Refunds)

**What the query does  :** Measures product-level profitability by comparing gross revenue against returns and allocated refunds to identify the products generating the highest net revenue.

**Pattern choice :** Built separate CTEs for product revenue, returns, and refund allocation before combining them in the final report. Refunds are proportionally allocated at the product level because refunds exist only at the order level and cannot be directly mapped back to individual items.

**Business interpretation  :** Revenue is highly concentrated in electronics, particularly Headphones and Smartwatches. The top product, Eastlight Clarity ANC Headphones, generated ₹918.4K gross revenue and retained almost all of it, ending with ₹917.7K net revenue after only ₹764 in refunds. In contrast, Marigold Home Craft Lite Wireless Earbuds generated ₹890.3K gross revenue but lost more than ₹10.4K through refunds, reducing net revenue to ₹879.9K. Several high-selling products exhibit return rates between 7% and 10%, such as Tarang Active Smartwatch (7.1%) and Mirae Essentials Luxe Smartwatch (10%), suggesting potential quality or expectation issues despite strong sales performance.

**What I'd ask next:** Which products experience the largest percentage decline from gross to net revenue, and are these losses driven by specific variants, pricing tiers, regions, or customer segments?
---

## Q5 — Category Health: Purchases → Returns

**What the query does  :** Compares category-level revenue generation with return behavior to identify which categories are both large and operationally healthy.

**Pattern choice :** Built independent sales and return aggregations and joined them at the category level using the `return_items` → `product_variants` → `products` → `categories` relationship. Separating sales and returns prevents double counting and makes return-rate calculations straightforward.

**Business interpretation  :** Smartwatches are the company's largest category, generating ₹59.7M in revenue, nearly 57% more than the next-largest category, Headphones at ₹38.1M. However, revenue leaders are not necessarily operational leaders. Accessories have the highest return rate at 3.11%, followed by Kitchen (2.93%), Shoes (2.88%), and Haircare (2.87%), all materially above the best-performing category, Bedding, at only 2.44%. Interestingly, Smartwatches generate the most revenue while maintaining a relatively low return rate of 2.45%, making them both a growth engine and an operationally healthy category.

**What I'd ask next:** Are high-return categories driven by a small number of problematic SKUs, sizing issues, product quality concerns, or misleading product descriptions?

---

## Q6 — Payment Failure Analysis (Method × Top Error Code)

**What the query does  :** Measures payment attempts and failures by payment method while identifying the most common failure reason for each method.

**Pattern choice :** Used `row_number()` to rank error codes within each payment method and solve the classic top-N-per-group problem. Separating payment summaries from error rankings keeps the query modular and avoids complex nested aggregations.

**Business interpretation  :** UPI processes a substantial payment volume with 12,835 attempts but also exhibits the highest failure rate at 5.5%, resulting in 711 failed transactions. In comparison, Card payments handle even higher volume at 14,166 attempts while maintaining a lower failure rate of 4.2%, leading to 592 failures. The dominant UPI issue is `GATEWAY_TIMEOUT`, accounting for 24% of all UPI failures, suggesting infrastructure or third-party reliability issues rather than customer behavior. Meanwhile, Card failures are primarily driven by `FRAUD` checks (28% of failures), indicating that risk controls may be sacrificing conversion.

**What I'd ask next:** How many failed transactions are eventually recovered through retries, and have payment failure rates changed over time or during peak traffic periods?

---

## Q7 — Delivery SLA Breach by Carrier × Shipping Method

**What the query does  :** Measures delivery performance across carriers and shipping methods by analyzing average delivery times, tail behavior, and SLA breach rates.

**Pattern choice :** Used `percentile_cont()` to compute median and p90 delivery times because averages alone often hide customer pain in logistics operations. Separating mean, median, and tail metrics makes it possible to identify carriers that are inconsistent rather than universally slow.

**Business interpretation  :** Carrier performance differs materially across providers. EcomExpress performs significantly worse than competitors, with its Express and Same-Day services missing the 5-day SLA approximately 20-21% of the time, compared with only 3.1% for Delhivery Standard and 5.7% for Bluedart Standard. EcomExpress also exhibits much worse delivery tails, with a p90 delivery time of 8 days versus only 5 days for Delhivery. Surprisingly, premium shipping methods do not deliver materially faster outcomes. EcomExpress Same-Day shipments still require an average of 4.08 days, nearly identical to its Express service (4.14 days), suggesting that premium shipping options may be operationally misconfigured or marketed inaccurately.

**What I'd ask next:** Are SLA breaches concentrated in specific regions, warehouses, or seasonal peaks, and is EcomExpress underperforming uniformly or only in certain parts of the network?
---

## Q8 — Customer Lifetime Value (LTV) + Revenue Concentration

**What the query does  :** Calculates customer lifetime value, segments customers into spending buckets, and measures how much total revenue each segment contributes.

**Pattern choice :** Combined customer-level aggregation, `CASE`-based bucketing, and window functions to calculate revenue concentration while preserving individual customer metrics such as order count and AOV.

**Business interpretation  :** Revenue is extremely concentrated among high-value customers. Customers in the 20000+ LTV bucket generate approximately 88% of total company revenue, indicating a very strong Pareto effect where a relatively small group of customers drives the majority of business performance. Several customers individually generated more than ₹1.3M in lifetime revenue and placed more than 150 orders, while maintaining AOVs between ₹7k and ₹10k. Losing even a small percentage of these customers could materially impact revenue growth and profitability.

**What I'd ask next:** Which acquisition channels, products, and retention campaigns are responsible for creating these high-LTV customers, and how early can we identify them?

---

## Q9 — Repeat Purchase Interval

**What the query does  :** Measures the time between one purchase and a customer's next purchase to estimate repurchase behavior and identify the appropriate timing for win-back campaigns.

**Pattern choice :** Used `lead(created_at)` partitioned by `customer_id` to pair each order with the customer's subsequent order. Summary statistics were computed both including and excluding same-day repeat purchases because same-day orders often represent split carts or checkout retries rather than genuine re-engagement..

**Business interpretation  :** The row-level output shows a significant number of same-day repeat purchases `(days_to_next_order = 0)`, confirming the presence of split orders or multiple transactions within a single shopping session. Including these orders reduces the median repurchase interval to just 1 day and the average to 6.25 days. However, excluding same-day repeats increases the median to 6 days and the average to 10.58 days, which is likely a much more realistic estimate of true customer return behavior.

A total of 3,759 customers placed at least one repeat order when same-day purchases are included, but this falls to 3,418 customers after excluding them. This means approximately 341 customers, around 9% of repeat purchasers, only placed same-day follow-up orders and never truly returned.

The p90 interval rises from 20 days to 27 days after removing same-day purchases, indicating that most customers who genuinely return do so within roughly four weeks. This suggests that win-back campaigns should probably be triggered somewhere between the second and fourth week after purchase rather than immediately after checkout, because emailing customers who reordered within hours would be mildly absurd even by ecommerce standards.

**What I'd ask next:** How do repeat intervals differ across acquisition channels, product categories, and high-LTV versus low-LTV customers? A customer buying skincare every 30 days behaves very differently from someone buying headphones once every six months.

---

## Q10 — Attribution Comparison: First-Touch vs Last-Touch Revenue

**What the query does  :** Compares revenue allocation under first-touch and last-touch attribution models to understand which channels primarily acquire customers versus which channels ultimately convert them.

**Pattern choice :** Used dual `row_number()` window functions to identify the earliest and latest marketing touchpoints for each customer and then reallocated order revenue under both attribution frameworks. This allows the business to distinguish between channels that open the funnel and channels that close it.

**Business interpretation  :** Organic and Paid dominate under both attribution models, indicating strong full-funnel influence. Organic contributes ₹113.7M (40% share) under first-touch attribution and still remains the largest channel under last-touch at ₹109.4M (39%), suggesting it is effective both at acquiring and converting customers. Paid remains remarkably stable at roughly ₹101-102M and 36% of revenue under both models, indicating balanced funnel performance rather than specialization in either acquisition or conversion.

Email exhibits the most notable attribution shift. Its revenue increases from ₹17.7M (6.3% share) under first-touch to ₹20.2M (7.2% share) under last-touch, representing approximately a 14% increase in attributed revenue. This strongly suggests that Email functions primarily as a conversion and re-engagement channel rather than a customer acquisition channel.

Affiliate and Referral channels also gain slightly under last-touch attribution, while Organic loses approximately ₹4.3M of attributed revenue, indicating that many customers initially discover the business through Organic search but ultimately convert through downstream channels such as Email or Referral.

**What I'd ask next:** How do CAC, ROAS, and customer LTV differ under different attribution models, and are channels that close conversions also responsible for acquiring high-value customers?
