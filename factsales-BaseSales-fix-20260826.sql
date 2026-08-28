
use Lakehouse_Curated
use Lakehouse_Presentation

select * from sys.tables order by name

select top 10 * 
from factinventory

select distinct sourcemovement
from factinventory

----------------------------------------------------------------------------
/*

view name	: vw_fnl_lrdentity

*/

-- Create TempTable
select companyid, productkey, '' as LRDEntity
into #temp
from dimproduct


-- cte 2 = LRD based on LRD

select companyid, productkey, max(date) as LRDEntity
from Factinventory
where sourcemovement = 'Purchase'
and netqty > 0
and warehouseid not in ('49101','49103','etc')


-- cte 3 = deal with NULL LRD

select companyid, productkey, max(date) as LRDEntity
from Factinventory
where sourcemovement in ('StockAdjustment','OtherMovement')
and netqty > 0
and warehouseid not in ('49101','49013','etc')

-- update #TempTable with correct LRD
update a
set LRDEntity =
	case when  b.LRDEntity is not null then  b.LRDEntity
	else  c.LRDEntity
	end 
from #temp a
left join cte 1 b
	on xxxxx
left join cte 2 c
	on xxxxx


-----------------------------------------------

-- Intercompany warwehouse id's
          WHEN c.warehouseid LIKE '%90'
              OR c.warehouseid LIKE '%99'
              OR c.warehouseid LIKE '491%'
              OR c.warehouseid IN ('49101','49102','49103','49106','49107')

-- List of sourcemovements
TransferOut
StockAdjustment
OtherMovement
Sales
TransferI


select distinct monthshortname, month, monthnumber from dimdate

select top 10 * from factsalesnew where qty > 1 and activesellingprice <> basesalesprice

-------------------------------
-- add new columns
alter table factsalesnew
add origvspsales decimal(19,4)

alter table factsalesnew
add origvspsales_usd decimal(19,4)


-- update local currency total 
UPDATE a
SET origvspsales =
    CAST(basesalesprice AS DECIMAL(18,4)) /
    NULLIF(
        1 + (
            CAST(vat AS DECIMAL(18,4)) /
            NULLIF(CAST(sales AS DECIMAL(18,4)), 0)
        ),
        0
    ) * qty
FROM factsalesnew a;


-- update local currency total 
UPDATE a
SET origvspsales_usd =
    a.origvspsales * b.exchangeratenew
FROM factsalesnew a
left join dimexchangeratedwh b
    on upper(a.companyid)=upper(b.companyid);


    select count(*) FACTSALES
    from factsales 
    where companyid = 'uae'
    and ltbasesalesprice = 0
    and date between '2026-02-01' and '2026-07-31'


    select count(*) FACTSALESNEW -- 1316693/1371368
    from factsalesnew 
    where company = 'UAE'
    and basesalesprice = 0
    and date between '2026-02-01' and '2026-07-31'


SELECT top 10 *
FROM (
    select *
    from factsalesnew 
    where company = 'UAE'
    and basesalesprice = 0
    and date between '2026-02-01' and '2026-07-31'
        ) t



-----


select top 10 *
from pricediscadmtrans
where todate in ('2154-12-31','1900-01-01')
and accountcode = 'Group'
and accountrelation in ('400', '300', '600', '700', '7000')
order by todate asc


select distinct accountrelation
from pricediscadmtrans



; with BaseSales_Agg as (
    select dataareaid, itemrelation as productid, inventdimid, amount
    from [Lakehouse_Curated].[dbo].[pricediscadmtrans]
    where todate in ('2154-12-31','1900-01-01')
        and accountcode = '1'
        and accountrelation in ('400', '300', '600', '700', '7000')
    group by dataareaid, itemrelation as productid, inventdimid, amount
        ),

factsales_agg as (
    select a.companyid, a.productkey, a.productid, c.
    from factsales a
    left join dimproduct b
        on upper(a.companyid) = upper(b.companyid)
        and a.productkey=b.productkey
    where 
    
    )



    select top 10 * from dimproduct




select top 10 *
from factsales a
left join BaseSales_Agg b
    on a.productid = b.itemrelation
    and 
left join dimproduct c
    on upper(a.companyid) = upper(c.companyid)
    and a.productkey=c.productkey
where 



select top 10 * from factsales

select top 10 * from dimproduct











