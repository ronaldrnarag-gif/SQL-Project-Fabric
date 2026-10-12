

declare @finyear VARCHAR(10) = '2026-27'
declare @monthperiod VARCHAR(10) = 'May'
 
; with factsalesnew_agg as (
    select a.month, a.company companyid, a.warehouseid, a.storetype, a.supplier vendorid, a.itemgroupname itemgroupid, b.itemmodelgroup, b.producttype, 
        a.department, a.subdepartment, a.class, a.subclass, a.brand, a.productid, 
        sum(a.qty) qty,sum(a.sales_usd) netsales, sum(a.cost_usd) cost, sum(a.cost_it_usd) cost_tr,
        'factsalesnew' tablesource
    from factsalesnew a
    left join dimproduct b
        on UPPER(a.company)=UPPER(b.companyid)
        and a.productkey=b.productkey
    left join dimexchangeratedwh d
        on UPPER(a.company)=UPPER(d.companyid)
    where a.finyear = @finyear and a.month = @monthperiod
    group by a.month, a.company , a.warehouseid, a.storetype, a.supplier , a.itemgroupname , b.itemmodelgroup, b.producttype, 
        a.department, a.subdepartment, a.class, a.subclass, a.brand, a.productid
),

factscrdwh_agg as (
    select a.month, a.dataareaid companyid, a.warehouse warehouseid, c.storetype,a.vendid vendorid, a.itemgroupid itemgroupid, b.itemmodelgroup, b.producttype,
        a.deptname department, a.subdeptname subdepartment, a.classname class, a.subclassname subclass, a.brand, a.itemid, 
        sum(-a.qtysales) qty, sum(-a.vspsales_usd) netsales, sum(a.ancpsales_usd) cost, sum(a.ancpsalestr_usd) cost_tr,
        'factscrdwh' tablesource
    from factscrdwh a
    left join dimproduct b
        on upper(a.dataareaid)=upper(b.companyid)
        and a.itemid=b.productid
    left join dimstore c
        on upper(a.dataareaid)=upper(c.companyid)
        and a.warehouse=c.warehouseid
    where a.finyear = @finyear and [month] = @monthperiod
    group by a.month, a.dataareaid , a.warehouse , c.storetype,a.vendid , a.itemgroupid , b.itemmodelgroup, b.producttype,
        a.deptname , a.subdeptname , a.classname , a.subclassname , a.brand, a.itemid
),

base_agg as (
    select * from factsalesnew_agg
    UNION ALL
    select * from factscrdwh_agg
)


---- High level validation ----------------------------

select *, (qty_FS-qty_SCR) qty_var, (salesusd_FS-salesusd_SCR) sales_var, (costusd_FS-costusd_SCR) cost_var, (costTRusd_FS-costTRusd_SCR) costtr_var
from (

    select month, companyid, warehouseid, storetype,vendorid, itemgroupid, itemmodelgroup, producttype,
        department, subdepartment, class, subclass, 
        sum(case when tablesource = 'factsalesnew' then qty else 0 end)         qty_FS,
        sum(case when tablesource = 'factsalesnew' then netsales else 0 end)    salesusd_FS,
        sum(case when tablesource = 'factsalesnew' then cost else 0 end)        costusd_FS,
        sum(case when tablesource = 'factsalesnew' then cost_tr else 0 end)     costTRusd_FS,
        sum(case when tablesource = 'factscrdwh' then qty else 0 end)           qty_SCR,
        sum(case when tablesource = 'factscrdwh' then netsales else 0 end)      salesusd_SCR,
        sum(case when tablesource = 'factscrdwh' then cost else 0 end)          costusd_SCR,
        sum(case when tablesource = 'factscrdwh' then cost_tr else 0 end)       costTRusd_SCR
    from base_agg
    group by month, companyid, warehouseid, storetype,vendorid, itemgroupid, itemmodelgroup, producttype,
        department, subdepartment, class, subclass
    ) t


/*
---- Granular level validation ----------------------------

select top 10 *, (qty_FS-qty_SCR) qty_var, (salesusd_FS-salesusd_SCR) sales_var, (costusd_FS-costusd_SCR) cost_var, (costTRusd_FS-costTRusd_SCR) costtr_var
FROM (
    select month, companyid, warehouseid, storetype,vendorid, itemgroupid, itemmodelgroup, producttype,
        department, subdepartment, class, subclass, brand, productid, 
        sum(case when tablesource = 'factsalesnew' then qty else 0 end)         qty_FS,
        sum(case when tablesource = 'factsalesnew' then netsales else 0 end)    salesusd_FS,
        sum(case when tablesource = 'factsalesnew' then cost else 0 end)        costusd_FS,
        sum(case when tablesource = 'factsalesnew' then cost_tr else 0 end)     costTRusd_FS,
        sum(case when tablesource = 'factscrdwh' then qty else 0 end)           qty_SCR,
        sum(case when tablesource = 'factscrdwh' then netsales else 0 end)      salesusd_SCR,
        sum(case when tablesource = 'factscrdwh' then cost else 0 end)          costusd_SCR,
        sum(case when tablesource = 'factscrdwh' then cost_tr else 0 end)       costTRusd_SCR
    from base_agg
    group by month, companyid, warehouseid, storetype,vendorid, itemgroupid, itemmodelgroup, producttype,
        department, subdepartment, class, subclass, brand, productid
    ) t
WHERE companyid = 'UAE'
AND ABS(qty_FS-qty_SCR - salesusd_FS - salesusd_SCR - costusd_FS - costusd_SCR - costTRusd_FS - costTRusd_SCR) > 0.99
*/