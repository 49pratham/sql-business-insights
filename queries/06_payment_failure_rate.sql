-- Q6: Payment Failure Analysis (Method × Top Error Code)
-- Business Question: Which payment methods fail most frequently, and what is the primary reason for those failures?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-10
-- Sanity Check:
-- 1. failure_rate is between 0 and 1.
-- 2. top_error_share_of_failures is between 0 and 1.
-- 3. failures <= attempts for every payment method.

with payment_summary as (
    select
        pm.method_name                                            as payment_method
      , count(*)                                                  as attempts
      , count(*) filter (
            where pt.status = 'failed'
              and pt.error_code is not null
        )                                                         as failures
    from ecom.payment_methods pm
    join ecom.payment_intents pi
        on pm.payment_method_id = pi.payment_method_id
    join ecom.payment_transactions pt
        on pi.payment_intent_id = pt.payment_intent_id
    group by
        pm.method_name
)

, payment_error_ranking as (
    select
        pm.method_name                                            as payment_method
      , pt.error_code
      , pt.error_message
      , count(*)                                                  as error_count
      , row_number() over (
            partition by pm.method_name
            order by count(*) desc
        )                                                         as rn
    from ecom.payment_methods pm
    join ecom.payment_intents pi
        on pm.payment_method_id = pi.payment_method_id
    join ecom.payment_transactions pt
        on pi.payment_intent_id = pt.payment_intent_id
    where pt.status = 'failed'
      and pt.error_code is not null
    group by
        pm.method_name
      , pt.error_code
      , pt.error_message
)

, payment_failure_analysis as (
    select
        ps.payment_method
      , ps.attempts
      , ps.failures
      , ps.failures * 1.0
            / nullif(ps.attempts, 0)                              as failure_rate
      , per.error_code                                            as top_error_code
      , per.error_message                                         as top_error_message
      , per.error_count * 1.0
            / nullif(ps.failures, 0)                              as top_error_share_of_failures
    from payment_summary ps
    left join payment_error_ranking per
        on ps.payment_method = per.payment_method
       and per.rn = 1
)

select
    payment_method
  , attempts
  , failures
  , failure_rate
  , top_error_code
  , top_error_message
  , top_error_share_of_failures
from payment_failure_analysis
order by
    failure_rate desc;