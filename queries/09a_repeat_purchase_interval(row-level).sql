-- Q9A: Repeat Purchase Interval (Row-Level)
-- Business Question:
-- How long does it take for customers to place
-- their next order?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-10
-- Notes:
-- 1. Cancelled orders are excluded.
-- 2. Last order per customer will have
--    next_order_date = NULL.
-- 3. Same-day repeat orders are retained in
--    the row-level output and handled separately
--    in summary metrics.
-- Sanity Checks:
-- 1. days_to_next_order >= 0

with customer_order_intervals as (
    select
        o.customer_id
      , o.order_id
      , o.created_at::date                         as order_date
      , lead(o.created_at::date) over (
            partition by o.customer_id
            order by o.created_at
        )                                          as next_order_date
    from ecom.orders o
    where lower(o.status) <> 'cancelled'
)

, repeat_purchase_intervals as (
    select
        customer_id
      , order_id
      , order_date
      , next_order_date
      , next_order_date - order_date              as days_to_next_order
    from customer_order_intervals
)

select
    customer_id
  , order_id
  , order_date
  , next_order_date
  , days_to_next_order
from repeat_purchase_intervals
order by
    customer_id
  , order_date;