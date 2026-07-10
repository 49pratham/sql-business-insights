-- Q5: Category Health, Purchases → Returns
-- Business Question: Which categories generate the most revenue,
-- and which have the highest return rates?
-- Owner: Prathamesh D S  |  Last Updated: 2026-07-10
-- Sanity Checks:
-- 1. return_rate_pct is between 0 and 100.
-- 2. returns <= orders_with_category for every category.
-- 3. sum(revenue) ≈ revenue from paid, non-cancelled orders.
-- Assumptions:
-- 1. Revenue is defined consistently as revenue from
--    paid, non-cancelled orders.
-- 2. return_items cannot be mapped back to orders because
--    order_id is unavailable.
-- 3. Returns are therefore measured at the variant level
--    and may include returns originating from orders outside
--    the paid/non-cancelled subset.

with category_sales as (
    select
        c.category_name                              as category
      , count(distinct oi.order_id)                 as orders_with_category
      , sum(oi.qty)                                 as units_sold
      , sum(oi.qty * oi.unit_price)                 as revenue
    from ecom.order_items oi

    join ecom.orders o
        on oi.order_id = o.order_id

    join ecom.product_variants pv
        on oi.variant_id = pv.variant_id

    join ecom.products p
        on pv.product_id = p.product_id

    join ecom.categories c
        on p.category_id = c.category_id

    where lower(o.status) <> 'cancelled'
      and lower(o.payment_status) = 'paid'

    group by
        c.category_name
)

, category_returns as (
    select
        c.category_name                              as category
      , count(distinct ri.return_id)                as returns
    from ecom.return_items ri

    join ecom.product_variants pv
        on ri.variant_id = pv.variant_id

    join ecom.products p
        on pv.product_id = p.product_id

    join ecom.categories c
        on p.category_id = c.category_id

    group by
        c.category_name
)

, category_health as (
    select
        cs.category
      , cs.orders_with_category
      , cs.units_sold
      , cs.revenue
      , coalesce(cr.returns, 0)                     as returns
      , coalesce(cr.returns, 0) * 100.0
            / nullif(cs.orders_with_category, 0)
                                                     as return_rate_pct
    from category_sales cs

    left join category_returns cr
        on cs.category = cr.category
)

select
    category
  , orders_with_category
  , units_sold
  , revenue
  , returns
  , return_rate_pct
from category_health
order by
    revenue desc;