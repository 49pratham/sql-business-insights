-- Q8: Customer LTV + Bucket Share of Revenue
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: Who are our top spenders, and what share of revenue do they represent?
-- Sanity check: total_revenue reconciles to non-cancelled order revenue; ltv_bucket_share_of_revenue summed across distinct buckets equals 1.

with customer_ltv as (
    select
        o.customer_id
      , min(o.created_at::date) as first_order_date
      , max(o.created_at::date) as last_order_date
      , count(*) as total_orders
      , sum(o.total) as total_revenue
      , sum(o.total) * 1.0 / nullif(count(*), 0) as aov
    from ecom.orders o
    where lower(o.status) <> 'cancelled'
      and o.customer_id is not null
    group by 1
)

, bucketed_customers as (
    select
        cl.customer_id
      , cl.first_order_date
      , cl.last_order_date
      , cl.total_orders
      , cl.total_revenue
      , cl.aov
      , case
            when cl.total_revenue < 1000 then '0-999'
            when cl.total_revenue < 5000 then '1000-4999'
            when cl.total_revenue < 20000 then '5000-19999'
            else '20000+'
        end as ltv_bucket
    from customer_ltv cl
)

select
    bc.customer_id
  , bc.first_order_date
  , bc.last_order_date
  , bc.total_orders
  , bc.total_revenue
  , bc.aov
  , bc.ltv_bucket
  , sum(bc.total_revenue) over (partition by bc.ltv_bucket) * 1.0
        / nullif(sum(bc.total_revenue) over (), 0) as ltv_bucket_share_of_revenue
from bucketed_customers bc
order by bc.total_revenue desc, bc.customer_id;