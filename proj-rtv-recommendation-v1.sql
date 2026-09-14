
/*--------------------------------------------------------

Purpose         :   contain logic related to Rtv Recommendation 
Created         :   ronaldn/20260914
CTE Flow        : 

                -- stockOnhand_agg
                -- L3MSalesQty_agg
                -- L3Mreception_agg
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
    where storetype not in ('InterCompany', 'Demo', 'Defective')
    group by month, upper(company), productkey, productid
    ),

-- L3M Sales Qty 
-- ensure storetype is updated once PBI-277 is completed.
L3MSalesQty_agg as (
	select upper(company) companyid, productkey, productid, 
		sum(qty) qtysold
	from factsalesnew a
	where date between dateadd(day,-90,cast(getdate()-1 as date)) and cast(getdate()-1 as date)
    and storetype not in ('InterCompany', 'Demo', 'Defective')
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
    and c.storetype not in ('InterCompany', 'Demo', 'Defective')
	Group by upper(a.companyid), a.productkey, b.productid
	),


-- Open Purchase Order
OpenPurchaseOrder_agg as (
	select upper(a.companyid) companyid,  a.productkey, b.productid,
		sum(purchqty)purchqty , sum(lineamount) lineamount, sum(orderedqty)orderedqty, sum(remainpurchphysical)remainpurchphysical
	from factpurchaseorder a
	left join dimproduct b
		on a.productkey=b.productkey and upper(a.companyid)=upper(b.companyid)
    left join dimstore c
        on a.storekey = c.locationkey
	where 
        purchstatus = 1 -- 1 Open Order, 2 Received, 3 Invoiced, 4 Cancelled
		and ltreceivedstatus <> 2 -- 0 Not Received, 1 Partially Received, 2 Fully Received 
		and purchasetype = 3 -- 0 Journal, 3 Purchase Order, 4 Returned order
		and intercompanyorder = 0 -- 0 interco order no, 1 interco order yes
        and c.storetype not in ('InterCompany', 'Demo', 'Defective')
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
    and storetype not in ('InterCompany', 'Demo', 'Defective')
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
    Select a.month, a.companyid, a.productkey, a.productid,  g.productname, g.vendorgroup, g.producttype, g.itemmodelgroup, g.apntreturnablestatus returnstatus,
        g.productlifecyclestateid, g.pgdescription, cast(f.FRD as date) as FRD, cast(h.lrdentity as date) as LRD,cast(g.creationdate as date) creationdate,
        g.hir1 department, g.hir2 subdepartment, g.hir3 class, g.hir4 subclass, g.ltbrand brand, g.vendorid, g.vendorname,
        a.ohqty, a.stock_usd, a.prov_usd, b.qtysold L3Msalesqty, e.qtysold YTDsalesqty, c.qtypurchased L3Mrcpqty, d.remainpurchphysical OpenPOqty, 

        (b.qtysold)/
                nullif(
                (a.ohqty+b.qtysold)
                    ,0) as SellThru,

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
            case 
                when (
                        productlifecyclestateid <> '3' -- non demo
                        -- and returnstatus = 1 /* To be reinstated once correct flag is available. */
                        and DATEDIFF(DAY,LRD,GETDATE()-1)>=90) -- not newness
                        and prov_usd <> 0 -- non moving
                        and OpenPOqty <> 0 -- no new order
                        and (ohqty >=5 or  stock_usd >= 200) -- amount is material
                    then 'YES'
                    else 'NO'
            end as recommendation
            , a.*
    from BaseQuery a
)

-- This script will be part of the SP to update 'fact_inventory_with_provision_aging' table on daily basis
SELECT *
from (
select 
    case 
        when (a.popgradeno = '3' and a.storetype = 'Demo') then '1-NR Demo' 
        when a.storetype = 'Defective' then '2-NR Defective'
        when a.storetype = 'InterCompany' then '3-NR Intercompany'
        when DATEDIFF(DAY,LRD,GETDATE()-1)<=90 then '4-NR Newness'
        when b.recommendation='YES' then '5-Recommended'
        else '6-NR Others'
    end isRecommended,
    b.recommendation,
    a.*
from fact_inventory_with_provision_aging a
LEFT JOIN recommendation_agg b
    on a.company=b.companyid
    and a.productkey=b.productkey
        ) t
where isRecommended = '6-NR Others'


/*

*/


