-- Q2: Monthly Signup Cohort Retention
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: For each month's new signups, how many came back in months 1, 2, and 3?
-- Sanity check: cohort_size equals count(distinct customer_id) from ecom.customers for each cohort month; retention rates stay between 0 and 1; censored months are shown as null, not 0.

with customer_cohorts as (
    select
        c.customer_id
      , date_trunc('month', c.created_at)::date as cohort_month
    from ecom.customers c
)

, eligible_orders as (
    select distinct
        o.customer_id
      , date_trunc('month', o.created_at)::date as order_month
    from ecom.orders o
    where lower(o.status) <> 'cancelled'
      and o.customer_id is not null
)

, cohort_activity as (
    select
        cc.customer_id
      , cc.cohort_month
      , eo.order_month
      , (
            extract(year from age(eo.order_month, cc.cohort_month)) * 12
          + extract(month from age(eo.order_month, cc.cohort_month))
        )::int as month_number
    from customer_cohorts cc
    left join eligible_orders eo
        on cc.customer_id = eo.customer_id
       and eo.order_month >= cc.cohort_month
)

, cohort_sizes as (
    select
        cohort_month
      , count(distinct customer_id) as cohort_size
    from customer_cohorts
    group by 1
)

, cohort_retention as (
    select
        ca.cohort_month
      , count(distinct case when ca.month_number = 1 then ca.customer_id end) as m1_retained
      , count(distinct case when ca.month_number = 2 then ca.customer_id end) as m2_retained
      , count(distinct case when ca.month_number = 3 then ca.customer_id end) as m3_retained
    from cohort_activity ca
    group by 1
)

, max_order_month as (
    select
        date_trunc('month', max(created_at))::date as max_observed_order_month
    from ecom.orders
)

select
    cs.cohort_month
  , cs.cohort_size
  , case
        when cs.cohort_month + interval '1 month' <= mom.max_observed_order_month
            then coalesce(cr.m1_retained, 0)
        else null
    end as m1_retained
  , case
        when cs.cohort_month + interval '2 months' <= mom.max_observed_order_month
            then coalesce(cr.m2_retained, 0)
        else null
    end as m2_retained
  , case
        when cs.cohort_month + interval '3 months' <= mom.max_observed_order_month
            then coalesce(cr.m3_retained, 0)
        else null
    end as m3_retained
  , case
        when cs.cohort_month + interval '1 month' <= mom.max_observed_order_month
            then coalesce(cr.m1_retained, 0) * 1.0 / nullif(cs.cohort_size, 0)
        else null
    end as m1_retention_rate
  , case
        when cs.cohort_month + interval '2 months' <= mom.max_observed_order_month
            then coalesce(cr.m2_retained, 0) * 1.0 / nullif(cs.cohort_size, 0)
        else null
    end as m2_retention_rate
  , case
        when cs.cohort_month + interval '3 months' <= mom.max_observed_order_month
            then coalesce(cr.m3_retained, 0) * 1.0 / nullif(cs.cohort_size, 0)
        else null
    end as m3_retention_rate
from cohort_sizes cs
left join cohort_retention cr
    on cs.cohort_month = cr.cohort_month
cross join max_order_month mom
order by cs.cohort_month;