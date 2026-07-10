-- Q2: Monthly Signup Cohort Retention
-- Business Question: For each signup cohort, how many customers returned in Month 1, Month 2 and Month 3?
-- Owner: Prathamesh D S
-- Last updated: 2026-06-29
-- Sanity Check:
-- 1. cohort_size = count(distinct customer_id) from ecom.customers for each signup month.
-- 2. All retention rates are between 0 and 1.
-- Note:
-- Cancelled orders are excluded from retention.
-- Later cohorts may have censored M2/M3 values because the observation window ends.

with customer_signups as (
    select distinct
        c.customer_id
      , date_trunc('month', c.created_at)::date        as signup_month
      , date_trunc('month', o.created_at)::date        as order_month
    from ecom.customers c
    left join ecom.orders o
        on c.customer_id = o.customer_id
       and lower(o.status) <> 'cancelled'
)

, monthly_difference as (
    select
        customer_id
      , signup_month
      , (
            (
                extract(year from order_month)
                - extract(year from signup_month)
            ) * 12
            +
            (
                extract(month from order_month)
                - extract(month from signup_month)
            )
        )                                              as month_diff
    from customer_signups
)

, retained as (
    select
        signup_month
      , count(distinct customer_id)                    as cohort_size
      , count(distinct customer_id)
            filter (where month_diff = 1)              as m1_retained
      , count(distinct customer_id)
            filter (where month_diff = 2)              as m2_retained
      , count(distinct customer_id)
            filter (where month_diff = 3)              as m3_retained
    from monthly_difference
    group by
        signup_month
)

, final_report as (
    select
        signup_month
      , cohort_size
      , m1_retained
      , m2_retained
      , m3_retained
      , m1_retained * 1.0
            / nullif(cohort_size, 0)                   as m1_retention_rate
      , m2_retained * 1.0
            / nullif(cohort_size, 0)                   as m2_retention_rate
      , m3_retained * 1.0
            / nullif(cohort_size, 0)                   as m3_retention_rate
    from retained
)

select
    *
from final_report
order by
    signup_month;