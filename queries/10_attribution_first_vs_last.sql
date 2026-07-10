-- Q10: Attribution Comparison
-- Business Question:
-- How does channel performance differ under first-touch
-- versus last-touch attribution?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-10
-- Assumption:
-- Attribution is customer-level because
-- attribution_touches does not contain order_id.
-- Sanity Checks:
-- 1. Revenue under both attribution models should equal
--    total non-cancelled order revenue.
-- 2. share_of_revenue should sum to 1.0
--    within each attribution model.

with customer_touches as (
    select
        s.customer_id
      , at.channel
      , at.touched_at
    from ecom.attribution_touches at
    join ecom.sessions s
        on at.session_id = s.session_id
    where s.customer_id is not null
)

, first_touch as (
    select
        customer_id
      , channel
    from (
        select
            customer_id
          , channel
          , row_number() over (
                partition by customer_id
                order by touched_at
            ) as rn
        from customer_touches
    ) t
    where rn = 1
)

, last_touch as (
    select
        customer_id
      , channel
    from (
        select
            customer_id
          , channel
          , row_number() over (
                partition by customer_id
                order by touched_at desc
            ) as rn
        from customer_touches
    ) t
    where rn = 1
)

, first_touch_revenue as (
    select
        'first_touch' as attribution_model
      , coalesce(ft.channel, 'direct') as channel
      , sum(o.total) as revenue
      , count(distinct o.order_id) as orders
    from ecom.orders o
    left join first_touch ft
        on o.customer_id = ft.customer_id
    where o.status <> 'cancelled'
    group by
        coalesce(ft.channel, 'direct')
)

, last_touch_revenue as (
    select
        'last_touch' as attribution_model
      , coalesce(lt.channel, 'direct') as channel
      , sum(o.total) as revenue
      , count(distinct o.order_id) as orders
    from ecom.orders o
    left join last_touch lt
        on o.customer_id = lt.customer_id
    where o.status <> 'cancelled'
    group by
        coalesce(lt.channel, 'direct')
)

, attribution_comparison as (
    select *
    from first_touch_revenue

    union all

    select *
    from last_touch_revenue
)

select
    attribution_model
  , channel
  , revenue
  , orders
  , revenue * 1.0
        / sum(revenue) over (
            partition by attribution_model
        ) as share_of_revenue
from attribution_comparison
order by
    attribution_model
  , revenue desc;