-- Q6: Payment Failure Rate by Payment Method
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: Which payment methods fail most often, and what error code is most responsible?
-- Sanity check: failure_rate stays between 0 and 1; successful_payments + failed_payments = attempts for every payment method.

with payment_attempts as (
    select
        pm.method_name as payment_method
      , pt.txn_id
      , lower(pt.status) as transaction_status
      , coalesce(pt.error_code, 'unknown') as error_code
    from ecom.payment_transactions pt
    join ecom.payment_intents pi
        on pt.payment_intent_id = pi.payment_intent_id
    join ecom.payment_methods pm
        on pi.payment_method_id = pm.payment_method_id
)

, payment_method_summary as (
    select
        pa.payment_method
      , count(*) as attempts
      , count(*) filter (
            where pa.transaction_status = 'succeeded'
        ) as successful_payments
      , count(*) filter (
            where pa.transaction_status = 'failed'
        ) as failed_payments
    from payment_attempts pa
    group by 1
)

, payment_method_errors as (
    select
        pa.payment_method
      , pa.error_code as top_error_code
      , count(*) as top_error_count
      , row_number() over (
            partition by pa.payment_method
            order by count(*) desc, pa.error_code
        ) as rn
    from payment_attempts pa
    where pa.transaction_status = 'failed'
    group by 1, 2
)

select
    pms.payment_method
  , pms.attempts
  , pms.successful_payments
  , pms.failed_payments
  , pms.failed_payments * 1.0 / nullif(pms.attempts, 0) as failure_rate
  , pme.top_error_code
  , pme.top_error_count
from payment_method_summary pms
left join payment_method_errors pme
    on pms.payment_method = pme.payment_method
   and pme.rn = 1
order by failure_rate desc, attempts desc;