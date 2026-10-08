

use AzadeaWarehouse

-- select top 10 * from factinventory
-- select top 10 * from factscrdwh
-- select top 10 * from dimproduct

---------------------------------------------------------------------------------------------------------------------------------------

-- update all variables
declare @finyear as varchar(10)         = '2026-27'
declare @monthperiod as varchar(10)     = 'Jul'
declare @dateperiod as date             = '2026-07-31'

-- FACTINVENTORY
; with factinventory_agg as (
    select upper(a.companyid) companyid, c.warehouseid warehouseid, a.apntprimaryvendorid_it vendorid, a.ltitemgroupid_it itemgroupid, 
            b.hir1 department, b.hir2 subdepartment, b.hir3 class, b.hir4 subclass, 
            b.ltbrand brand, b.productid, 
            sum(a.netqty) netqty, sum(a.netcost) netcost,
            SUM(a.netcost * d.exchangeratenew) netcost_usd,  'factinventory' as tablesource
    from factinventory a    
    left join dimproduct b  
            on upper(a.companyid) = upper(b.companyid) 
            and a.productkey=b.productkey
    left join dimstore c    
            on a.locationkey = c.locationkey
    left join dimexchangeratedwh d
        on upper(a.companyid)=upper(d.companyid)
    where a.date <= @dateperiod    -- update with preferred month period
    and upper(a.companyid) not in ('KWT','JOR','EGP')       
    and b.itemmodelgroup <> 'FIFO'
    and b.producttype = '0'
    -- and b.vendorgroup not in ('F','M')
    group by upper(a.companyid) , c.warehouseid , a.apntprimaryvendorid_it , a.ltitemgroupid_it , 
            b.hir1 , b.hir2 , b.hir3 , b.hir4  , 
            b.ltbrand , b.productid
),

-- FACTSCRDWH
factscr_agg as (
    select upper(dataareaid) companyid, warehouse warehouseid, vendid vendorid, itemgroupid,  
        deptname department, subdeptname subdepartment, classname class, subclassname subclass, 
        brand, itemid productid, 
        sum(qtystkend) netqty, sum(ancpstkend) netcost, sum(ancpstkend_usd) netcost_usd, 
         'factscr' as tablesource
    from factscrdwh
    where finyear = @finyear
    and [month] = @monthperiod -- update month here to match the first 
    and producttype = 1
    group by upper(dataareaid) , warehouse , vendid , itemgroupid,  
        deptname , subdeptname , classname , subclassname , 
        brand, itemid 
),

base_agg as (
    select * from factinventory_agg
    UNION ALL
    select * from factscr_agg
)

-- high level
select *, (qty_FI-qty_SCR) qty_var, (costusd_FI-costusd_SCR) costusd_var
from (
    select companyid, warehouseid, vendorid, itemgroupid, 
        sum(case when tablesource = 'factinventory' then netqty else 0 end) qty_FI,
        sum(case when tablesource = 'factinventory' then netcost_usd else 0 end) costusd_FI,
        sum(case when tablesource = 'factscr' then netqty else 0 end) qty_SCR,
        sum(case when tablesource = 'factscr' then netcost_usd else 0 end) costusd_SCR
    from base_agg
    group by companyid, warehouseid, vendorid, itemgroupid
) t


-- -- granular
-- select *, (qty_FI-qty_SCR) qty_var, (costusd_FI-costusd_SCR) costusd_var
-- from (
--     select companyid,  warehouseid,  vendorid, itemgroupid,  
--          department,  subdepartment,  class,  subclass, 
--         brand,  productid,
--         sum(netqty) netqty, sum(netcost) netcost, sum(netcost_usd) netcost_usd, 
--         sum(case when tablesource = 'factinventory' then netqty else 0 end) qty_FI,
--         sum(case when tablesource = 'factinventory' then netcost_usd else 0 end) costusd_FI,
--         sum(case when tablesource = 'factscr' then netqty else 0 end) qty_SCR,
--         sum(case when tablesource = 'factscr' then netcost_usd else 0 end) costusd_SCR
--     from base_agg
--     group by companyid,  warehouseid,  vendorid, itemgroupid,  
--          department,  subdepartment,  class,  subclass, 
--         brand,  productid
-- ) t
-- where companyid = 'QAT'
;


