-- Q4: Top Products by Net Revenue (After Refunds)
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: Which products actually make us money after accounting for returns and refunds?
-- Sanity check: sum(gross_revenue) across products should match sum(qty * unit_price) or sum(line_total) from paid/non-cancelled order_items for the same window within tolerance.

with paid_order_items as (
    select
        oi.order_id
      , oi.variant_id
      , oi.qty
      , oi.unit_price
      , oi.line_discount
      , oi.line_total
    from ecom.order_items oi
    join ecom.orders o
        on oi.order_id = o.order_id
    where lower(o.status) <> 'cancelled'
)

, order_item_enriched as (
    select
        poi.order_id
      , pv.product_id
      , p.product_name
      , c.category_name as category
      , poi.qty
      , poi.unit_price
      , poi.line_discount
      , poi.line_total
    from paid_order_items poi
    join ecom.product_variants pv
        on poi.variant_id = pv.variant_id
    join ecom.products p
        on pv.product_id = p.product_id
    left join ecom.categories c
        on p.category_id = c.category_id
)

, product_revenue as (
    select
        oie.product_id
      , oie.product_name
      , oie.category
      , sum(oie.line_total) as gross_revenue
      , count(distinct oie.order_id) as orders_count
      , sum(oie.qty) as units_sold
    from order_item_enriched oie
    group by 1, 2, 3
)

, order_refunds as (
    select
        r.order_id
      , sum(r.amount) as order_refund_amount
    from ecom.refunds r
    where lower(coalesce(r.status, 'processed')) <> 'failed'
    group by 1
)

, order_totals as (
    select
        oie.order_id
      , sum(oie.line_total) as order_line_total
    from order_item_enriched oie
    group by 1
)

, allocated_product_refunds as (
    select
        oie.product_id
      , sum(
            case
                when ot.order_line_total = 0 then 0
                else coalesce(orf.order_refund_amount, 0) * oie.line_total / ot.order_line_total
            end
        ) as refunds_amount
    from order_item_enriched oie
    join order_totals ot
        on oie.order_id = ot.order_id
    left join order_refunds orf
        on oie.order_id = orf.order_id
    group by 1
)

, product_returns as (
    select
        pv.product_id
      , count(*) as returns_count
    from ecom.return_items ri
    join ecom.product_variants pv
        on ri.variant_id = pv.variant_id
    group by 1
)

select
    pr.product_id
  , pr.product_name
  , pr.category
  , pr.gross_revenue
  , pr.orders_count
  , pr.units_sold
  , coalesce(pre.returns_count, 0) as returns_count
  , coalesce(pre.returns_count, 0) * 1.0 / nullif(pr.orders_count, 0) as return_rate
  , coalesce(apr.refunds_amount, 0) as refunds_amount
  , pr.gross_revenue - coalesce(apr.refunds_amount, 0) as net_revenue
from product_revenue pr
left join product_returns pre
    on pr.product_id = pre.product_id
left join allocated_product_refunds apr
    on pr.product_id = apr.product_id
order by net_revenue desc, gross_revenue desc;