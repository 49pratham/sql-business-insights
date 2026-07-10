-- Q9: Repeat Purchase Interval
-- Business Question: How long does it take for customers to return and when should win-back campaigns be triggered?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-10
-- Notes:
-- 1. Last order per customer is excluded from summary metrics.
-- 2. Summary is computed both including and excluding same-day repeat orders.
-- 3. Same-day repeats may represent split carts rather than genuine reactivation.
-- Sanity Checks:
-- 1. days_to_next_order >= 0.
-- 2. median_days_to_next_order <= p90_days_to_next_order.

with customer_order_intervals as (
    select
        o.customer_id
      , o.order_id
      , o.created_at::date                                   as order_date
      , lead(o.created_at::date) over (
            partition by o.customer_id
            order by o.created_at
        )                                                    as next_order_date
    from ecom.orders o
    where o.status <> 'cancelled'
)

, repeat_purchase_intervals as (
    select
        customer_id
      , order_id
      , order_date
      , next_order_date
      , next_order_date - order_date                         as days_to_next_order
    from customer_order_intervals
)

-- Summary including same-day repeat purchases
, repeat_purchase_summary_all as (
    select
        avg(days_to_next_order)                              as avg_days_to_next_order
      , percentile_cont(0.5)
            within group (
                order by days_to_next_order
            )                                                as median_days_to_next_order
      , percentile_cont(0.9)
            within group (
                order by days_to_next_order
            )                                                as p90_days_to_next_order
      , count(distinct customer_id)                          as customers_with_repeat_order
    from repeat_purchase_intervals
    where next_order_date is not null
)

-- Summary excluding same-day repeat purchases
, repeat_purchase_summary_true_return as (
    select
        avg(days_to_next_order)                              as avg_days_to_next_order
      , percentile_cont(0.5)
            within group (
                order by days_to_next_order
            )                                                as median_days_to_next_order
      , percentile_cont(0.9)
            within group (
                order by days_to_next_order
            )                                                as p90_days_to_next_order
      , count(distinct customer_id)                          as customers_with_repeat_order
    from repeat_purchase_intervals
    where next_order_date is not null
      and days_to_next_order > 0
)

select
    customer_id
  , order_id
  , order_date
  , next_order_date
  , days_to_next_order
from repeat_purchase_intervals
order by
    customer_id,
    order_date;