-- Q9: Repeat Purchase Interval
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: How long does it take for a customer to place their next order?
-- Sanity check: days_to_next_order is never negative.

with customer_orders as (
    select
        o.customer_id
      , o.order_id
      , o.created_at::date as order_date
      , lead(o.created_at::date) over (
            partition by o.customer_id
            order by o.created_at, o.order_id
        ) as next_order_date
    from ecom.orders o
    where lower(o.status) <> 'cancelled'
      and o.customer_id is not null
)

select
    co.customer_id
  , co.order_id
  , co.order_date
  , co.next_order_date
  , (co.next_order_date - co.order_date) as days_to_next_order
from customer_orders co
where co.next_order_date is not null
order by co.customer_id, co.order_date, co.order_id;

-- Q9 Summary: Repeat Purchase Interval
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: How long does it take for a customer to return for another purchase, excluding same-day split-order behavior from the summary?
-- Sanity check: median_days_to_next_order <= p90_days_to_next_order; days_to_next_order is never negative.

with customer_orders as (
    select
        o.customer_id
      , o.order_id
      , o.created_at::date as order_date
      , lead(o.created_at::date) over (
            partition by o.customer_id
            order by o.created_at, o.order_id
        ) as next_order_date
    from ecom.orders o
    where lower(o.status) <> 'cancelled'
      and o.customer_id is not null
)

, repeat_intervals as (
    select
        co.customer_id
      , co.order_id
      , co.order_date
      , co.next_order_date
      , (co.next_order_date - co.order_date) as days_to_next_order
    from customer_orders co
    where co.next_order_date is not null
)

select
    avg(ri.days_to_next_order * 1.0) as avg_days_to_next_order
  , percentile_cont(0.5) within group (order by ri.days_to_next_order) as median_days_to_next_order
  , percentile_cont(0.9) within group (order by ri.days_to_next_order) as p90_days_to_next_order
  , count(distinct ri.customer_id) as customers_with_repeat_order
from repeat_intervals ri
where ri.days_to_next_order > 0;