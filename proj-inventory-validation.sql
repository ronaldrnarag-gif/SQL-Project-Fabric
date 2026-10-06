
-- FACTINVENTORY
with factinventory_agg as (
    select upper(a.companyid) companyid, c.warehouseid warehouseid, a.apntprimaryvendorid_it vendorid, a.ltitemgroupid_it itemgroupid, 
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
    where a.date <= '2026-07-31'    -- update with preferred month period
    and upper(a.companyid) not in ('KWT','JOR','EGP')       
    and b.itemmodelgroup <> 'FIFO'
    and b.producttype = '0'
    -- and b.vendorgroup not in ('F','M')
    group by upper(a.companyid) , c.warehouseid , a.apntprimaryvendorid_it , a.ltitemgroupid_it 
),

-- FACTSCRDWH
factscr_agg as (
    select upper(dataareaid) companyid, warehouse warehouseid, vendid vendorid, itemgroupid,  
        sum(qtystkend) netqty, sum(ancpstkend) netcost, sum(ancpstkend_usd) netcost_usd, 
         'factscr' as tablesource
    from factscrdwh
    where finyear = '2026-27'
    and [month] = 'Jul' -- update month here to match the first 
    and producttype = 1
    group by dataareaid, warehouse, vendid, itemgroupid
),

base_agg as (
    select * from factinventory_agg
    UNION ALL
    select * from factscr_agg
)

select *
from base_agg

;
---------------------------

