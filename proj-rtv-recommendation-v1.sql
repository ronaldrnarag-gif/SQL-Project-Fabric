
/*--------------------------------------------------------
-- USE AzadeaWarehouse
-- USE Lakehouse_Curated

*/--------------------------------------------------------

-- Day - 1 On hand Inventory
; with stockOnhand_agg as (
    select month, upper(company) as companyid, productkey, productid, 
        sum(total_stk_qty) as ohqty, sum(total_stk_usd) as stock_usd, sum(total_prov_usd) as prov_usd
    from fact_inventory_historical a
    where finyear = 
        (select distinct fiscalperiod 
        from dimdate b 
        where cast(b.date as date) = cast(getdate()-1 as date))
    and month = 
        upper(format(cast(getdate()-1 as date), 'MMM'))
    group by month, upper(company), productkey, productid
    ),

-- L3M Sales Qty 
-- ensure storetype is updated once PBI-277 is completed.
L3MSalesQty_agg as (
	select company companyid, productkey, productid, 
		sum(qty) qtysold
	from factsalesnew a
	where date between dateadd(day,-90,getdate()-1) and getdate()-1
		   -- and storetype NOT IN ('InterCompany', 'Warehouse')
	group by company, productkey, productid
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
		and date between dateadd(day,-90,getdate()-1) and getdate()-1
	Group by upper(a.companyid), a.productkey, b.productid
	),

-- Open Purchase Order
OpenPurchaseOrder_agg as (
	select upper(a.companyid) companyid,  a.productkey, b.productid,
		sum(purchqty)purchqty , sum(lineamount) lineamount, sum(orderedqty)orderedqty, sum(remainpurchphysical)remainpurchphysical
	from factpurchaseorder a
	left join dimproduct b
		on a.productkey=b.productkey and upper(a.companyid)=upper(b.companyid)
	where purchstatus = 1 -- 1 Open Order, 2 Received, 3 Invoiced, 4 Cancelled
		and ltreceivedstatus <> 2 -- 0 Not Received, 1 Partially Received, 2 Fully Received 
		and purchasetype = 3 -- 0 Journal, 3 Purchase Order, 4 Returned order
		and intercompanyorder = 0 -- 0 interco order no, 1 interco order yes
	group by upper(a.companyid),  a.productkey, b.productid
	),

-- YTD Sales Qty
-- ensure storetype is updated once PBI-277 is completed.
YtdSalesQty_agg as (
	select company companyid, productkey, productid, 
		sum(qty) qtysold
	from factsalesnew 
	WHERE
    date between
        CASE
            WHEN MONTH(GETDATE()-1) = 1
                THEN DATEFROMPARTS(YEAR(GETDATE()-1)-1, 2, 1)
            ELSE DATEFROMPARTS(YEAR(GETDATE()-1), 2, 1)
        END
        AND getdate()-1
    --and storetype NOT IN ('InterCompany', 'Warehouse')
	group by company, productkey, productid
	),


-- First Receipt Date (FRD Logic);
FRD_agg as (
	select upper(a.companyid) as companyid, a.productkey, b.productid, 
		min(date) as FRD
	from factpurchase a
	left join dimproduct b
		on a.productkey = b.productkey and upper(a.companyid) = upper(b.companyid)
	left join dimstore c
		on a.locationkey = c.locationkey
	where a.purchasetype = 'Purchase Order'
	Group by upper(a.companyid), a.productkey, b.productid
	)

/*
stockOnhand_agg
L3MSalesQty_agg
L3Mreception_agg
OpenPurchaseOrder_agg
YtdSalesQty_agg
FRD_agg
*/

select top 10 a.month, a.companyid, a.productkey, a.productid, 
    a.ohqty, a.stock_usd, a.prov_usd, b.qtysold L3Msalesqty, c.qtypurchased L3Mrcpqty, d.purchqty OpenPOqty, f.FRD,
    (a.ohqty)/
            nullif(
            (a.ohqty+b.qtysold)
                ,0) as SellThru,
    (e.qtysold)/
            nullif(
            (datediff(day, f.FRD, getdate()-1)/7)
                ,0) as AvgWeeklySalesQty,
    (a.ohqty)/nullif(
            (e.qtysold)/
            nullif(
            (datediff(day, f.FRD, getdate()-1)/7)
                ,0) ,0) as weeksOfCover
from stockOnhand_agg a
left join L3MSalesQty_agg b
	on a.companyid = b.companyid and a.productkey = b.productkey
left join L3Mreception_agg c
	on a.companyid = c.companyid and a.productkey = c.productkey
left join OpenPurchaseOrder_agg d
	on a.companyid = d.companyid and a.productkey = d.productkey
left join YtdSalesQty_agg e
	on a.companyid = e.companyid and a.productkey = e.productkey
left join FRD_agg f
	on a.companyid = f.companyid and a.productkey = f.productkey
-- group by a.month, a.companyid, a.productkey, a.productid
    