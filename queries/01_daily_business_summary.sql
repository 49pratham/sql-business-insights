-- Q1: Daily Business Summary with DoD and Same-Weekday WoW
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: How are we doing today vs yesterday, and vs the same day last week?
-- Sanity check: paid_order_rate between 0 and 1 on every row; sum(orders) equals count(*) from ecom.orders for the same date window.

with orders_base as (
    select
        o.order_id
      , date_trunc('day', o.created_at)::date as order_date
      , lower(o.status)                       as normalized_status
      , lower(o.payment_status)               as normalized_payment_status
      , o.total
    from ecom.orders o
    where o.created_at >= (
        select max(created_at)
        from ecom.orders
    ) - interval '90 days'
)

, daily_orders as (
    select
        ob.order_date
      , count(*) as orders
      , sum(ob.total) as revenue
      , count(*) filter (
            where ob.normalized_payment_status = 'paid'
        ) as paid_orders
      , count(*) filter (
            where ob.normalized_status = 'cancelled'
        ) as cancelled_orders
    from orders_base ob
    group by 1
)

, daily_refunds as (
    select
        date_trunc('day', r.created_at)::date as order_date
      , sum(r.amount) as refunds_amount
    from ecom.refunds r
    where r.created_at >= (
        select max(created_at)
        from ecom.orders
    ) - interval '90 days'
    group by 1
)

, daily_metrics as (
    select
        dord.order_date
      , dord.revenue
      , dord.orders
      , dord.revenue * 1.0 / nullif(dord.orders, 0) as aov
      , dord.paid_orders * 1.0 / nullif(dord.orders, 0) as paid_order_rate
      , dord.cancelled_orders * 1.0 / nullif(dord.orders, 0) as cancelled_order_rate
      , coalesce(dr.refunds_amount, 0) as refunds_amount
    from daily_orders dord
    left join daily_refunds dr
        on dord.order_date = dr.order_date
)

select
    dm.order_date
  , dm.revenue
  , dm.orders
  , dm.aov
  , dm.paid_order_rate
  , dm.cancelled_order_rate
  , dm.refunds_amount
  , (
        dm.revenue - lag(dm.revenue, 1) over (order by dm.order_date)
    ) / nullif(lag(dm.revenue, 1) over (order by dm.order_date), 0) as revenue_vs_yesterday_pct
  , (
        dm.revenue - lag(dm.revenue, 7) over (order by dm.order_date)
    ) / nullif(lag(dm.revenue, 7) over (order by dm.order_date), 0) as revenue_vs_last_weekday_pct
from daily_metrics dm
order by dm.order_date desc;
