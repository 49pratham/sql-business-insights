-- Q4: Top Products by Net Revenue (After Refunds)
-- Business Question: Which products generate the highest net revenue after accounting for returns and refunds?
-- Owner: Prathamesh D S
-- Last Updated: 2026-07-10
-- Sanity Check:
-- 1. sum(gross_revenue) ≈ sum(qty * unit_price) from ecom.order_items.
-- 2. sum(refunds_amount) ≈ sum(refund_amount) from ecom.order_refunds.
-- Assumption:
-- Refunds are recorded at the order level rather than the product level.
-- Refund amounts are allocated proportionally based on each product's
-- contribution to total order value.

with product_revenue as (
    select
        p.product_id
      , p.product_name
      , c.category_name                                              as category
      , sum(oi.qty * oi.unit_price)                                  as gross_revenue
      , count(distinct oi.order_id)                                  as orders_count
      , sum(oi.qty)                                                  as units_sold
    from ecom.products p
    join ecom.product_variants pv
        on p.product_id = pv.product_id
    join ecom.order_items oi
        on pv.variant_id = oi.variant_id
    join ecom.categories c
        on p.category_id = c.category_id
    group by
        p.product_id
      , p.product_name
      , c.category_name
)

, order_totals as (
    select
        oi.order_id
      , sum(oi.qty * oi.unit_price)                                  as order_total
    from ecom.order_items oi
    group by
        oi.order_id
)

, product_returns as (
    select
        pv.product_id
      , count(distinct ri.return_id)                                 as returns_count
    from ecom.return_items ri
    join ecom.product_variants pv
        on ri.variant_id = pv.variant_id
    group by
        pv.product_id
)

, product_refunds as (
    select
        pv.product_id
      , sum(
            orf.refund_amount
            *
            (
                (oi.qty * oi.unit_price) * 1.0
                / nullif(ot.order_total, 0)
            )
        )                                                            as refunds_amount
    from ecom.order_refunds orf
    join ecom.order_items oi
        on orf.order_id = oi.order_id
    join order_totals ot
        on oi.order_id = ot.order_id
    join ecom.product_variants pv
        on oi.variant_id = pv.variant_id
    group by
        pv.product_id
)

, final_report as (
    select
        pr.product_id
      , pr.product_name
      , pr.category
      , pr.gross_revenue
      , pr.orders_count
      , pr.units_sold
      , coalesce(pre.returns_count, 0)                               as returns_count
      , coalesce(pre.returns_count, 0) * 1.0
            / nullif(pr.orders_count, 0)                             as return_rate
      , coalesce(prf.refunds_amount, 0)                              as refunds_amount
      , pr.gross_revenue
            - coalesce(prf.refunds_amount, 0)                        as net_revenue
    from product_revenue pr
    left join product_returns pre
        on pr.product_id = pre.product_id
    left join product_refunds prf
        on pr.product_id = prf.product_id
)

select
    product_id
  , product_name
  , category
  , gross_revenue
  , orders_count
  , units_sold
  , returns_count
  , return_rate
  , refunds_amount
  , net_revenue
from final_report
order by
    net_revenue desc;