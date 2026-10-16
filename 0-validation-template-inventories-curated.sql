

use AzadeaWarehouse

-- select top 10 * from factinventory
-- select top 10 * from factscrdwh
-- select top 10 * from dimproduct

---------------------------------------------------------------------------------------------------------------------------------------

-- update all variables
declare @finyear as varchar(10)         = '2026-27'
declare @monthperiod as varchar(10)     = 'Oct'
declare @dateperiod as date             = '2026-10-15'

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

-- FACTSCR from Curated
factscr_agg as (
    select a.dataareaid as companyid, a.warehouse as warehouseid, a.vendid as vendorid, a.itemgroupid as itemgroupid,
        b.hir1 department, b.hir2 subdepartment, b.hir3 class, b.hir4  subclass, 
                b.ltbrand brand, a.itemid productid,
                sum(a.qtystkend) netqty, sum(a.ancpstkend) netcost,
                sum(a.ancpstkend * c.exchangeratenew) netcost_usd,
                'factscr_curated' as tablesource
    from [Lakehouse_Curated].[dbo].[ltscrlinesmtd] a
    left join [AzadeaWarehouse].[dbo].[dimproduct] b
        on upper(a.dataareaid)=upper(b.companyid)
        and a.itemid=b.productid
    left join [AzadeaWarehouse].[dbo].[dimexchangeratedwh] c
        on upper(a.dataareaid)=upper(c.companyid)
    where 1=1
        and a.dataareaid is NOT NULL
    group by a.dataareaid, a.warehouse, a.vendid , a.itemgroupid ,
        b.hir1 , b.hir2 , b.hir3 , b.hir4  ,
        b.ltbrand , a.itemid
),

base_agg as (
    select * from factinventory_agg
    UNION ALL
    select * from factscr_agg
    )

select top 10 * from base_agg




































































































