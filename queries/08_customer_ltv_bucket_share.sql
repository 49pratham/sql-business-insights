-- Q8: Customer LTV + Bucket Share of Revenue
-- Business Question: Who are our highest-value customers, and what share of total revenue does each LTV bucket contribute?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-10
-- Sanity Check:
-- 1. sum(total_revenue) across customers ≈ revenue from non-cancelled orders.
-- 2. Sum of distinct ltv_bucket_share_of_revenue values equals 1.0.
-- 3. AOV should always be <= total_revenue.

with customer_ltv as (
    select
        c.customer_id
      , min(o.created_at)::date                             as first_order_date
      , max(o.created_at)::date                             as last_order_date
      , count(distinct o.order_id)                          as total_orders
      , sum(o.total)                                        as total_revenue
      , sum(o.total) * 1.0
            / count(distinct o.order_id)                    as aov
    from ecom.customers c
    join ecom.orders o
        on c.customer_id = o.customer_id
    where lower(o.status) <> 'cancelled'
    group by
        c.customer_id
)

, customer_ltv_bucketed as (
    select
        customer_id
      , first_order_date
      , last_order_date
      , total_orders
      , total_revenue
      , aov
      , case
            when total_revenue < 1000
                then '0-999'

            when total_revenue < 5000
                then '1000-4999'

            when total_revenue < 20000
                then '5000-19999'

            else '20000+'
        end                                                 as ltv_bucket
    from customer_ltv
)

, final_report as (
    select
        customer_id
      , first_order_date
      , last_order_date
      , total_orders
      , total_revenue
      , aov
      , ltv_bucket
      , sum(total_revenue) over (
            partition by ltv_bucket
        ) * 1.0
            / sum(total_revenue) over ()                    as ltv_bucket_share_of_revenue
    from customer_ltv_bucketed
)

select
    customer_id
  , first_order_date
  , last_order_date
  , total_orders
  , total_revenue
  , aov
  , ltv_bucket
  , ltv_bucket_share_of_revenue
from final_report
order by
    total_revenue desc;