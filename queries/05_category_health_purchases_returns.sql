-- Q5: Category Health - Purchases to Returns
-- Owner: Prathamesh D S  |  Last updated: 2026-06-29
-- Business question: Which categories generate the most revenue, and which have the highest return rates?
-- Sanity check: return_rate_pct stays between 0 and 100; returns <= orders_with_category for every category; sum(revenue) reconciles to paid/non-cancelled item revenue within tolerance.

with category_sales as (
    select
        c.category_name as category
      , count(distinct oi.order_id) as orders_with_category
      , sum(oi.qty) as units_sold
      , sum(oi.line_total) as revenue
    from ecom.order_items oi
    join ecom.orders o
        on oi.order_id = o.order_id
    join ecom.product_variants pv
        on oi.variant_id = pv.variant_id
    join ecom.products p
        on pv.product_id = p.product_id
    left join ecom.categories c
        on p.category_id = c.category_id
    where lower(o.status) <> 'cancelled'
    group by 1
)

, category_returns as (
    select
        c.category_name as category
      , count(distinct rr.return_id) as returns
    from ecom.return_items ri
    join ecom.return_requests rr
        on ri.return_id = rr.return_id
    join ecom.product_variants pv
        on ri.variant_id = pv.variant_id
    join ecom.products p
        on pv.product_id = p.product_id
    left join ecom.categories c
        on p.category_id = c.category_id
    group by 1
)

select
    cs.category
  , cs.orders_with_category
  , cs.units_sold
  , cs.revenue
  , coalesce(cr.returns, 0) as returns
  , coalesce(cr.returns, 0) * 100.0 / nullif(cs.orders_with_category, 0) as return_rate_pct
from category_sales cs
left join category_returns cr
    on cs.category = cr.category
order by cs.revenue desc, return_rate_pct desc;