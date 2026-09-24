
/*--------------------------------------------------------

Purpose         :   contain logic related to Rtv Recommendation 
Created         :   ronaldn/20260914
CTE Flow        : 

                -- stockOnhand_agg          -- excluding interco, demo, defective
                -- L3MSalesQty_agg          -- excluding interco, demo, defective
                -- L3Mreception_agg         -- excluding interco, demo, defective
                -- OpenPurchaseOrder_agg
                -- YtdSalesQty_agg
                -- FRD_agg
                -- BaseQuery
                -- recommendation_agg

*/--------------------------------------------------------

-- Day - 1 On hand Inventory
; with stockOnhand_agg as (
    select month, upper(company) as companyid, productkey, productid, 
        sum(total_stk_qty) as ohqty, sum(total_stk$) as stock_usd, sum(total_prov$) as prov_usd
    from fact_inventory_with_provision_aging a
    where storetype not in ('InterCompany', 'Demo', 'Defective','Ticketing','RTV')
    group by month, upper(company), productkey, productid
    ),

-- L3M Sales Qty 
-- ensure storetype is updated once PBI-277 is completed.
L3MSalesQty_agg as (
	select upper(company) companyid, productkey, productid, 
		sum(qty) qtysold
	from factsalesnew a
	where date between dateadd(day,-90,cast(getdate()-1 as date)) and cast(getdate()-1 as date)
    and storetype not in ('InterCompany', 'Demo', 'Defective','Ticketing','RTV')
	group by upper(company), productkey, productid
	),


---- L3M PO Reception
L3Mreception_agg as (
	select upper(a.companyid) as companyid, a.productkey, b.productid, 
		sum(qtypurchased) qtypurchased
	from factpurchase a
	left join dimproduct b
		on a.productkey = b.productkey and upper(a.companyid) = upper(b.companyid)
	left join dimstore c
		on a.locationkey = c.locationkey
	where a.purchasetype = 'Purchase Order'
		and date between dateadd(day,-90,cast(getdate()-1 as date)) and cast(getdate()-1 as date)
    and c.storetype not in ('InterCompany', 'Demo', 'Defective','Ticketing','RTV')
	Group by upper(a.companyid), a.productkey, b.productid
	),


-- Open Purchase Order
OpenPurchaseOrder_agg as (
	select upper(a.companyid) companyid,  a.productkey, b.productid,
		sum(purchqty)purchqty , sum(lineamount) lineamount, sum(orderedqty)orderedqty, isnull(sum(remainpurchphysical),0) remainpurchphysical
	from factpurchaseorder a
	left join dimproduct b
		on a.productkey=b.productkey and upper(a.companyid)=upper(b.companyid)
    left join dimstore c
        on a.storekey = c.locationkey
	where 
        DATEDIFF(DAY,podate,cast(GETDATE()-1 as date)) <= 45
        and approvalstatus <> 30        -- 30 Approved, 40 Confirmed, 50 Finalized
        and purchstatus = 1             -- 1 Open Order, 2 Received, 3 Invoiced, 4 Cancelled
		and ltreceivedstatus <> 2       -- 0 Not Received, 1 Partially Received, 2 Fully Received 
		and purchasetype = 3            -- 0 Journal, 3 Purchase Order, 4 Returned order
		-- and intercompanyorder = 0    -- 0 interco order no, 1 interco order yes
        and c.storetype not in ('InterCompany', 'Demo', 'Defective','Ticketing','RTV')
	group by upper(a.companyid),  a.productkey, b.productid
	),

-- YTD Sales Qty
-- ensure storetype is updated once PBI-277 is completed.
YtdSalesQty_agg as (
	select upper(company) companyid, productkey, productid, 
		sum(qty) qtysold
	from factsalesnew 
	WHERE
    date between
        CASE
            WHEN MONTH(GETDATE()-1) = 1
                THEN DATEFROMPARTS(YEAR(GETDATE()-1)-1, 2, 1)
            ELSE DATEFROMPARTS(YEAR(GETDATE()-1), 2, 1)
        END
        AND cast(getdate()-1 as date)
    and storetype not in ('InterCompany', 'Demo', 'Defective','Ticketing','RTV')
	group by upper(company), productkey, productid
	),

-- First Receipt Date (FRD Logic);
FRD_agg as (
	select upper(a.companyid) as companyid, a.productkey, b.productid, 
		cast(min(date) as date) as FRD
	from factpurchase a
	left join dimproduct b
		on a.productkey = b.productkey and upper(a.companyid) = upper(b.companyid)
	left join dimstore c
		on a.locationkey = c.locationkey
	where a.purchasetype = 'Purchase Order'
	Group by upper(a.companyid), a.productkey, b.productid
	),

-- base query to get the final output
BaseQuery as (
    Select a.month, a.companyid, a.productkey, a.productid,  g.productname, g.vendorgroup, g.producttype, g.itemmodelgroup, g.returnstatus returnstatus,
        g.productlifecyclestateid, g.pgdescription, cast(f.FRD as date) as FRD, cast(h.lrdentity as date) as LRD,cast(g.creationdate as date) creationdate,
        g.hir1 department, g.hir2 subdepartment, g.hir3 class, g.hir4 subclass, g.ltbrand brand, g.vendorid, g.vendorname,
        a.ohqty, a.stock_usd, a.prov_usd, b.qtysold L3Msalesqty, e.qtysold YTDsalesqty, c.qtypurchased L3Mrcpqty, isnull(d.remainpurchphysical,0) OpenPOqty, 

        -- sell thru
        (b.qtysold)/
                nullif(
                (a.ohqty+b.qtysold)
                    ,0) as SellThru,   

        -- AvgWeeklySalesQty -- to be updated into L3M instead
        e.qtysold /
                (CASE 
                    WHEN CAST(f.FRD AS DATE) < DATEFROMPARTS(2026, 2, 1) -- make this dynamic
                    THEN NULLIF(
                            DATEDIFF(
                                DAY,
                                DATEFROMPARTS(2026, 2, 1), -- make this dynamic
                                CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
                            ) / 7.00,
                            0
                        )
                    ELSE NULLIF(
                            DATEDIFF(
                                DAY,
                                CAST(f.FRD AS DATE),
                                CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
                            ) / 7.00,
                            0
                        )
                END) AS AvgWeeklySalesQty, --based on ytd sales

        -- weeksOfCover
        (a.ohqty)/nullif(
                e.qtysold /
                CASE 
                    WHEN CAST(f.FRD AS DATE) < DATEFROMPARTS(2026, 2, 1) -- make this dynamic
                    THEN NULLIF(
                            cast(DATEDIFF(
                                DAY,
                                DATEFROMPARTS(2026, 2, 1), -- make this dynamic
                                CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
                            ) / 7.00 as DECIMAL),
                            0
                        )
                    ELSE NULLIF(
                            DATEDIFF(
                                DAY,
                                CAST(f.FRD AS DATE),
                                CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
                            ) / 7.00,
                            0
                        )
                END ,0) as weeksOfCover

    from stockOnhand_agg a
    left join L3MSalesQty_agg b
        on upper(a.companyid) = upper(b.companyid) 
            and a.productkey = b.productkey
    left join L3Mreception_agg c
        on upper(a.companyid) = upper(c.companyid) 
            and a.productkey = c.productkey
    left join OpenPurchaseOrder_agg d
        on upper(a.companyid) = upper(d.companyid) 
            and a.productkey = d.productkey
    left join YtdSalesQty_agg e
        on upper(a.companyid) = upper(e.companyid) 
            and a.productkey = e.productkey
    left join FRD_agg f
        on upper(a.companyid) = upper(f.companyid) 
            and a.productkey = f.productkey
    left join dimproduct g
        on upper(a.companyid) = upper(g.companyid) 
            and a.productkey = g.productkey
    left join vw_fnl_lrdentity h
        on a.companyid=h.companyid
        and a.productkey=h.productkey
    ),

recommendation_agg as (
    select 
            CASE 
                WHEN (
                        productlifecyclestateid <> '3'                  -- not a demo
                        AND returnstatus = 1                            -- with return clause
                        AND DATEDIFF(DAY,LRD,GETDATE()-1)>=90           -- not new
                        AND prov_usd <> 0                               -- not a moving stock
                        AND OpenPOqty  = 0                              -- no new order
                        AND (ohqty >=5 or  stock_usd >= 200)            -- qty/amount is material
                        AND weeksOfCover <= 12                          -- WOC
                            )
                        THEN 'Yes - no action'
                WHEN (
                        productlifecyclestateid <> '3'                  -- not a demo
                        AND returnstatus = 1                            -- with return clause
                        AND DATEDIFF(DAY,LRD,GETDATE()-1)>=90           -- not new
                        AND prov_usd <> 0                               -- not a moving stock
                        AND OpenPOqty  = 0                              -- no new order
                        AND (ohqty >=5 or  stock_usd >= 200)            -- qty/amount is material
                        AND weeksOfCover <= 25                          -- WOC
                            )
                        THEN 'Yes - for Promo'
                WHEN (
                        productlifecyclestateid <> '3'                  -- not a demo
                        AND returnstatus = 1                            -- with return clause
                        AND DATEDIFF(DAY,LRD,GETDATE()-1)>=90           -- not new
                        AND prov_usd <> 0                               -- not a moving stock
                        AND OpenPOqty  = 0                              -- no new order
                        AND (ohqty >=5 or  stock_usd >= 200)            -- qty/amount is material
                        AND weeksOfCover > 25                           -- WOC
                            )
                        THEN 'Yes - for Rtv'
                ELSE 'NO'
            END as recommendation
            , a.*
    from BaseQuery a
)

-- This script will be part of the SP to update 'fact_inventory_with_provision_aging' table on daily basis

-- SELECT  top 10 *
-- from (
--     select 
--         case 
--             when (a.popgradeno = '3' and a.storetype = 'Demo') then '1-NR Demo' 
--             when a.storetype = 'Defective' then '2-NR Defective'
--             when a.storetype = 'InterCompany' then '3-NR Intercompany'
--             when DATEDIFF(DAY,LRD,GETDATE()-1)<=90 then '4-NR Newness'
--             when b.recommendation='Yes - no action' then '5-Recommended, no action'
--             when b.recommendation='Yes - for Promo' then '5-Recommended for promo'
--             when b.recommendation='Yes - for Rtv' then '5-Recommended for rtv'
--             when b.recommendation='NO' then '5.1-NR'
--             else '6-NR Others'
--         end isRecommended,
--         b.recommendation,

--         a.*
--     from fact_inventory_with_provision_aging a
--     LEFT JOIN recommendation_agg b
--         on a.company=b.companyid
--         and a.productkey=b.productkey
--     LEFT JOIN dimproduct dp
--         ON upper(a.company)=upper(dp.companyid)
--             and a.productkey=dp.productkey
--     where dp.vendorgroup in ('I','N')
--     and dp.hir1 <> 'services'
--     -- and a.productid = '1114135'
--     -- and company = 'QAT'
--             ) t

SELECT  company, isRecommended, 
    SUM(total_stk$)total_stk, sum(total_prov$)total_prov
from (
    select 
        case 
            when (a.popgradeno = '3' and a.storetype = 'Demo') then '1-NR Demo' 
            when a.storetype = 'Defective' then '2-NR Defective'
            when a.storetype = 'InterCompany' then '3-NR Intercompany'
            when DATEDIFF(DAY,LRD,GETDATE()-1)<=90 then '4-NR Newness'
            when b.recommendation='Yes - no action' then '5.1-Recommended, No action'
            when b.recommendation='Yes - for Promo' then '5.2-Recommended, Promotion'
            when b.recommendation='Yes - for Rtv' then '5.3-Recommended, RTV'
            when b.recommendation='NO' then '6-NR Others'
            else '6-NR Others'
        end isRecommended,
        b.AvgWeeklySalesQty,
        b.weeksOfCover,
        a.*
    from fact_inventory_with_provision_aging a
    LEFT JOIN recommendation_agg b
        on a.company=b.companyid
        and a.productkey=b.productkey
    LEFT JOIN dimproduct dp
        ON upper(a.company)=upper(dp.companyid)
            and a.productkey=dp.productkey
    where dp.vendorgroup in ('I','N')
    and dp.hir1 <> 'services'
            ) t
GROUP BY company, isRecommended


--1114135
/*

*/


