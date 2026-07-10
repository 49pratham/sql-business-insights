-- Q3: Funnel Conversion by Acquisition Channel
-- Business Question: Where does each acquisition channel lose users in the purchase funnel?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-02
-- Sanity Check:
-- 1. All conversion rates are between 0 and 1.
-- 2. Funnel counts satisfy:
--    sessions >= product_view_sessions >= add_to_cart_sessions
--    >= begin_checkout_sessions >= purchase_sessions.
-- Note:
-- Only sessions on or after 2026-04-19 are included because
-- event instrumentation started on that date.

with sessions_summary as (
    select
        sc.channel
      , count(distinct se.session_id)                                              as sessions
      , count(distinct se.session_id)
            filter (where se.event_type = 'product_view')                           as product_view_sessions
      , count(distinct se.session_id)
            filter (where se.event_type = 'add_to_cart')                            as add_to_cart_sessions
      , count(distinct se.session_id)
            filter (where se.event_type = 'begin_checkout')                         as begin_checkout_sessions
      , count(distinct se.session_id)
            filter (where se.event_type = 'purchase')                               as purchase_sessions
    from ecom.session_channels sc
    join ecom.session_events se
        on sc.session_id = se.session_id
    where se.occurred_at >= '2026-04-19'
    group by
        sc.channel
)

, session_funnels as (
    select
        channel
      , sessions
      , product_view_sessions
      , add_to_cart_sessions
      , begin_checkout_sessions
      , purchase_sessions
      , add_to_cart_sessions * 1.0
            / nullif(product_view_sessions, 0)                                      as view_to_cart_rate
      , begin_checkout_sessions * 1.0
            / nullif(add_to_cart_sessions, 0)                                       as cart_to_checkout_rate
      , purchase_sessions * 1.0
            / nullif(begin_checkout_sessions, 0)                                    as checkout_to_purchase_rate
      , purchase_sessions * 1.0
            / nullif(sessions, 0)                                                   as session_to_purchase_rate
    from sessions_summary
)

select
    *
from session_funnels
order by
    channel;