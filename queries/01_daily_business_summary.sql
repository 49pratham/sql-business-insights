-- Q1: Daily Business Summary + DoD / Same-Weekday WoW Comparisons
-- Business Question: How are we doing today vs yesterday and vs the same weekday last week?
-- Owner: Prathamesh D S
-- Last updated: 2026-06-29
-- Sanity Check:
-- 1. paid_order_rate ∈ [0,1]
-- 2. sum(orders) = count(*) from ecom.orders

with daily_summary as (
    select
        date_trunc('day', o.created_at)::date       as order_date

      , sum(o.total) filter (
            where lower(o.status) <> 'cancelled'
              and lower(o.payment_status) = 'paid'
        )                                           as revenue

      , count(*) filter (
            where lower(o.status) <> 'cancelled'
              and lower(o.payment_status) = 'paid'
        )                                           as orders

      , count(*) filter (
            where lower(o.payment_status) = 'paid'
        )                                           as paid_orders

      , count(*) filter (
            where lower(o.status) = 'cancelled'
        )                                           as cancelled_orders

    from ecom.orders o

    group by
        1
)

, daily_refunds as (
    select
        date_trunc('day', created_at)::date           as order_date
      , sum(amount)                                   as refunds_amount
    from ecom.refunds
    group by
        1
)

, daily_metrics as (
    select
        ds.order_date
      , ds.revenue
      , ds.orders
      , ds.revenue * 1.0
            / nullif(ds.orders, 0)                    as aov
      , ds.paid_orders * 1.0
            / nullif(ds.orders, 0)                    as paid_order_rate
      , ds.cancelled_orders * 1.0
            / nullif(ds.orders, 0)                    as cancelled_order_rate
      , coalesce(dr.refunds_amount, 0)                as refunds_amount
      , lag(ds.revenue) over (
            order by ds.order_date
        )                                             as yesterday_revenue
      , lag(ds.revenue, 7) over (
            order by ds.order_date
        )                                             as last_week_revenue
    from daily_summary ds
    left join daily_refunds dr
        on ds.order_date = dr.order_date
)

, final_report as (
    select
        order_date
      , revenue
      , orders
      , aov
      , paid_order_rate
      , cancelled_order_rate
      , refunds_amount
      , (revenue - yesterday_revenue) * 1.0
            / nullif(yesterday_revenue, 0)            as revenue_vs_yesterday_pct
      , (revenue - last_week_revenue) * 1.0
            / nullif(last_week_revenue, 0)            as revenue_vs_last_weekday_pct
    from daily_metrics
)

select
    *
from final_report
order by
    order_date;