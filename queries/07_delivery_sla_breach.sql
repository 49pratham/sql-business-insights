-- Q7: Delivery SLA Breach by Carrier x Shipping Method
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: Which carrier and shipping method combinations are missing the 5-day SLA, and by how much?
-- Sanity check: avg_delivery_days <= p90_delivery_days on every row; late_rate stays between 0 and 1.

with delivered_shipments as (
    select
        sc.carrier_name as carrier
      , sm.method_name as shipping_method
      , (s.delivered_at::date - s.shipped_at::date) as delivery_days
    from ecom.shipments s
    left join ecom.shipping_carriers sc
        on s.carrier_id = sc.carrier_id
    left join ecom.shipping_methods sm
        on s.shipping_method_id = sm.shipping_method_id
    where s.delivered_at is not null
      and s.shipped_at is not null
)

select
    ds.carrier
  , ds.shipping_method
  , count(*) as delivered_orders
  , avg(ds.delivery_days * 1.0) as avg_delivery_days
  , percentile_cont(0.5) within group (order by ds.delivery_days) as median_delivery_days
  , percentile_cont(0.9) within group (order by ds.delivery_days) as p90_delivery_days
  , count(*) filter (
        where ds.delivery_days > 5
    ) as late_deliveries
  , count(*) filter (
        where ds.delivery_days > 5
    ) * 1.0 / nullif(count(*), 0) as late_rate
from delivered_shipments ds
group by 1, 2
order by late_rate desc, p90_delivery_days desc, delivered_orders desc;