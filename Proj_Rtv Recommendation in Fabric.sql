--USE AzadeaWarehouse
--USE Lakehouse_Curated


-- First Receipt Date (FRD Logic);
;with FRD_agg as (
	select upper(a.companyid) as companyid, c.warehouseid, a.productkey, b.productid, 
		min(date) as FRD
	from factpurchase a
	left join dimproduct b
		on a.productkey = b.productkey and upper(a.companyid) = upper(b.companyid)
	left join dimstore c
		on a.locationkey = c.locationkey
	where a.purchasetype = 'Purchase Order'
	Group by upper(a.companyid), c.warehouseid, a.productkey, b.productid
	),

-- L3M Sales Qty 
-- ensure storetype is updated once PBI-277 is completed.
L3MSalesQty_agg as (
	select company companyid, warehouseid, productkey, productid, 
		sum(qty) qtysold
	from factsalesnew a
	where date between dateadd(day,-90,getdate()-1) and getdate()-1
		   -- and storetype NOT IN ('InterCompany', 'Warehouse')
	group by company, warehouseid, productkey, productid
	),

-- YTD Sales Qty
-- ensure storetype is updated once PBI-277 is completed.
YtdSalesQty_agg as (
	select company companyid, warehouseid, productkey, productid, 
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
	group by company, warehouseid, productkey, productid
	),

---- L3M PO Reception
L3Mreception_agg as (
	select upper(a.companyid) as companyid, c.warehouseid, a.productkey, b.productid, 
		sum(qtypurchased) qtypurchased
	from factpurchase a
	left join dimproduct b
		on a.productkey = b.productkey and upper(a.companyid) = upper(b.companyid)
	left join dimstore c
		on a.locationkey = c.locationkey
	where a.purchasetype = 'Purchase Order'
		and date between dateadd(day,-90,getdate()-1) and getdate()-1
	Group by upper(a.companyid), c.warehouseid, a.productkey, b.productid
	),

-- Open Purchase Order
OpenPurchaseOrder_agg as (
	select upper(a.companyid) companyid,  inventlocationid as warehouseid, a.productkey, b.productid,
		sum(purchqty)purchqty , sum(lineamount) lineamount, sum(orderedqty)orderedqty, sum(remainpurchphysical)remainpurchphysical
	from factpurchaseorder a
	left join dimproduct b
		on a.productkey=b.productkey and upper(a.companyid)=upper(b.companyid)
	where purchstatus = 1 -- 1 Open Order, 2 Received, 3 Invoiced, 4 Cancelled
		and ltreceivedstatus <> 2 -- 0 Not Received, 1 Partially Received, 2 Fully Received 
		and purchasetype = 3 -- 0 Journal, 3 Purchase Order, 4 Returned order
		and intercompanyorder = 0 -- 0 interco order no, 1 interco order yes
	group by upper(a.companyid),  inventlocationid, a.productkey, b.productid
	)

select top 10 * from OpenPurchaseOrder_agg


