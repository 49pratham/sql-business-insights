-- Q7: Delivery SLA Breach by Carrier × Shipping Method
-- Business Question: Which carriers and shipping methods are missing the 5-day SLA, and by how much?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-10
-- SLA Definition:
-- delivery_days = delivered_at::date - shipped_at::date
-- Late delivery = delivery_days > 5
-- Sanity Check:
-- 1. avg_delivery_days <= p90_delivery_days.
-- 2. late_rate is between 0 and 1.
-- 3. Shipments with delivered_at is null are excluded (still in transit).
-- 4. Investigate records where shipped_at > delivered_at.

with shipment_delivery_metrics as (
    select
        sc.carrier_name                                         as carrier
      , sm.method_name                                          as shipping_method
      , s.delivered_at::date
            - s.shipped_at::date                                as delivery_days
    from ecom.shipments s
    join ecom.shipping_carriers sc
        on s.carrier_id = sc.carrier_id
    join ecom.shipping_methods sm
        on s.shipping_method_id = sm.shipping_method_id
    where s.delivered_at is not null
)

, delivery_sla_performance as (
    select
        carrier
      , shipping_method
      , count(*)                                                as delivered_orders
      , avg(delivery_days)                                      as avg_delivery_days
      , percentile_cont(0.5)
            within group (
                order by delivery_days
            )                                                   as median_delivery_days
      , percentile_cont(0.9)
            within group (
                order by delivery_days
            )                                                   as p90_delivery_days
      , count(*) filter (
            where delivery_days > 5
        )                                                       as late_deliveries
      , count(*) filter (
            where delivery_days > 5
        ) * 1.0
            / nullif(count(*), 0)                               as late_rate
    from shipment_delivery_metrics
    group by
        carrier
      , shipping_method
)

select
    carrier
  , shipping_method
  , delivered_orders
  , avg_delivery_days
  , median_delivery_days
  , p90_delivery_days
  , late_deliveries
  , late_rate
from delivery_sla_performance
order by
    late_rate desc,
    p90_delivery_days desc;