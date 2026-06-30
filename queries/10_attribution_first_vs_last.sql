-- Q10: Attribution Comparison - First Touch vs Last Touch Revenue by Channel
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: Does channel mix look different under first-touch vs last-touch attribution, and which channels open vs close the funnel?
-- Sanity check: total revenue under first_touch equals total revenue under last_touch equals total non-cancelled order revenue.

with eligible_orders as (
    select
        o.order_id
      , o.session_id
      , o.total as revenue
    from ecom.orders o
    where lower(o.status) <> 'cancelled'
)

, order_touches as (
    select
        eo.order_id
      , eo.revenue
      , coalesce(at.channel, 'direct') as channel
      , at.touched_at
      , row_number() over (
            partition by eo.order_id
            order by at.touched_at asc nulls last, at.touch_id
        ) as first_touch_rn
      , row_number() over (
            partition by eo.order_id
            order by at.touched_at desc nulls last, at.touch_id desc
        ) as last_touch_rn
    from eligible_orders eo
    left join ecom.attribution_touches at
        on eo.session_id = at.session_id
)

, first_touch as (
    select
        'first_touch' as attribution_model
      , coalesce(ot.channel, 'direct') as channel
      , sum(ot.revenue) as revenue
      , count(distinct ot.order_id) as orders
    from order_touches ot
    where ot.first_touch_rn = 1
    group by 1, 2
)

, last_touch as (
    select
        'last_touch' as attribution_model
      , coalesce(ot.channel, 'direct') as channel
      , sum(ot.revenue) as revenue
      , count(distinct ot.order_id) as orders
    from order_touches ot
    where ot.last_touch_rn = 1
    group by 1, 2
)

, combined as (
    select * from first_touch
    union all
    select * from last_touch
)

select
    c.attribution_model
  , c.channel
  , c.revenue
  , c.orders
  , c.revenue * 1.0 / nullif(sum(c.revenue) over (partition by c.attribution_model), 0) as share_of_revenue
from combined c
order by c.attribution_model, c.revenue desc;