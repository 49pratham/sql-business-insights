-- Q3: Funnel Conversion by Acquisition Channel
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: Where in the funnel does each channel's traffic leak: browse, cart, checkout, or payment?
-- Sanity check: all rates are between 0 and 1; stage counts are monotonically non-increasing within each channel.

with instrumented_sessions as (
    select
        s.session_id
      , coalesce(sc.channel, 'direct') as channel
    from ecom.sessions s
    left join ecom.session_channels sc
        on s.session_id = sc.session_id
    where s.started_at::date >= date '2026-04-19'
)

, session_stage_flags as (
    select
        se.session_id
      , max(case when se.event_type = 'product_view' then 1 else 0 end) as saw_product_view
      , max(case when se.event_type = 'add_to_cart' then 1 else 0 end) as saw_add_to_cart
      , max(case when se.event_type = 'begin_checkout' then 1 else 0 end) as saw_begin_checkout
      , max(case when se.event_type = 'purchase' then 1 else 0 end) as saw_purchase
    from ecom.session_events se
    where se.occurred_at::date >= date '2026-04-19'
    group by 1
)

select
    ins.channel
  , count(distinct ins.session_id) as sessions
  , count(distinct case when ssf.saw_product_view = 1 then ins.session_id end) as product_view_sessions
  , count(distinct case when ssf.saw_add_to_cart = 1 then ins.session_id end) as add_to_cart_sessions
  , count(distinct case when ssf.saw_begin_checkout = 1 then ins.session_id end) as begin_checkout_sessions
  , count(distinct case when ssf.saw_purchase = 1 then ins.session_id end) as purchase_sessions
  , count(distinct case when ssf.saw_add_to_cart = 1 then ins.session_id end) * 1.0
        / nullif(count(distinct case when ssf.saw_product_view = 1 then ins.session_id end), 0) as view_to_cart_rate
  , count(distinct case when ssf.saw_begin_checkout = 1 then ins.session_id end) * 1.0
        / nullif(count(distinct case when ssf.saw_add_to_cart = 1 then ins.session_id end), 0) as cart_to_checkout_rate
  , count(distinct case when ssf.saw_purchase = 1 then ins.session_id end) * 1.0
        / nullif(count(distinct case when ssf.saw_begin_checkout = 1 then ins.session_id end), 0) as checkout_to_purchase_rate
  , count(distinct case when ssf.saw_purchase = 1 then ins.session_id end) * 1.0
        / nullif(count(distinct ins.session_id), 0) as session_to_purchase_rate
from instrumented_sessions ins
left join session_stage_flags ssf
    on ins.session_id = ssf.session_id
group by 1
order by purchase_sessions desc, sessions desc;
