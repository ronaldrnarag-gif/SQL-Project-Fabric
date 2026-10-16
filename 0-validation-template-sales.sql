

declare @finyear VARCHAR(10) = '2024-25'
-- declare @monthperiod VARCHAR(10) = 'Aug'
 
; with factsalesnew_agg as (
    select a.finyear, a.month, a.company companyid, a.warehouseid, a.storetype, a.supplier vendorid, a.itemgroupname itemgroupid, b.itemmodelgroup, b.producttype, 
        b.hir1 department, b.hir2 subdepartment, b.hir3 class, b.hir4 subclass, b.ltbrand brand, a.productkey, a.productid, 
        sum(a.qty) qty,sum(a.sales_usd) netsales, sum(a.cost_usd) cost, sum(a.cost_it_usd) cost_tr,
        'factsalesnew' tablesource
    from factsalesnew a
    left join dimproduct b
        on UPPER(a.company)=UPPER(b.companyid)
        and a.productkey=b.productkey
    left join dimexchangeratedwh d
        on UPPER(a.company)=UPPER(d.companyid)
    where 1=1
        and a.warehouseid <> '496'
        and a.finyear = @finyear 
        -- and a.month = @monthperiod
    group by a.finyear, a.month, a.company , a.warehouseid, a.storetype, a.supplier , a.itemgroupname , b.itemmodelgroup, b.producttype, 
        b.hir1 , b.hir2 , b.hir3 , b.hir4 , b.ltbrand , a.productkey, a.productid
),

factscrdwh_agg as (
    select a.finyear, a.month, a.dataareaid companyid, a.warehouse warehouseid, c.storetype,a.vendid vendorid, a.itemgroupid itemgroupid, b.itemmodelgroup, b.producttype,
        b.hir1 department, b.hir2 subdepartment, b.hir3 class, b.hir4 subclass, b.ltbrand brand, a.productkey, a.itemid productid, 
        sum(-a.qtysales) qty, sum(-a.vspsales_usd) netsales, sum(a.ancpsales_usd) cost, sum(a.ancpsalestr_usd) cost_tr,
        'factscrdwh' tablesource
    from factscrdwh a
    left join dimproduct b
        on upper(a.dataareaid)=upper(b.companyid)
        and a.productkey=b.productkey
    left join dimstore c
        on upper(a.dataareaid)=upper(c.companyid)
        and a.warehouse=c.warehouseid
    where 1=1 
        AND a.finyear = @finyear 
        -- and a.[month] = @monthperiod
    group by a.finyear, a.month, a.dataareaid , a.warehouse , c.storetype,a.vendid , a.itemgroupid , b.itemmodelgroup, b.producttype,
         b.hir1 , b.hir2 , b.hir3 , b.hir4 , b.ltbrand , a.productkey, a.itemid 
),

base_agg as (
    select * from factsalesnew_agg
    UNION ALL
    select * from factscrdwh_agg
)

---- High level validation ----------------------------

select *, (qty_FS-qty_SCR) qty_var, (salesusd_FS-salesusd_SCR) sales_var, (costusd_FS-costusd_SCR) cost_var, (costTRusd_FS-costTRusd_SCR) costtr_var
from (

    select finyear, month, companyid, warehouseid, storetype,vendorid, itemgroupid, itemmodelgroup, producttype,
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
    group by finyear, month, companyid, warehouseid, storetype,vendorid, itemgroupid, itemmodelgroup, producttype,
        department, subdepartment, class, subclass
    ) t



----------

-- Granular level validation ----------------------------

-- select *, (qty_FS-qty_SCR) qty_var, (salesusd_FS-salesusd_SCR) sales_var, (costusd_FS-costusd_SCR) cost_var, (costTRusd_FS-costTRusd_SCR) costtr_var
-- FROM (
--     select finyear, month, companyid, warehouseid, storetype, itemgroupid,  itemmodelgroup, producttype, productkey, productid, 
--             sum(case when tablesource = 'factsalesnew' then qty else 0 end)         qty_FS,
--             sum(case when tablesource = 'factsalesnew' then netsales else 0 end)    salesusd_FS,
--             sum(case when tablesource = 'factsalesnew' then cost else 0 end)        costusd_FS,
--             sum(case when tablesource = 'factsalesnew' then cost_tr else 0 end)     costTRusd_FS,
--             sum(case when tablesource = 'factscrdwh' then qty else 0 end)           qty_SCR,
--             sum(case when tablesource = 'factscrdwh' then netsales else 0 end)      salesusd_SCR,
--             sum(case when tablesource = 'factscrdwh' then cost else 0 end)          costusd_SCR,
--             sum(case when tablesource = 'factscrdwh' then cost_tr else 0 end)       costTRusd_SCR
--     from base_agg
--     group by finyear, month, companyid, warehouseid, storetype, itemgroupid,  itemmodelgroup, producttype, productkey, productid
--     ) t
-- WHERE 1=1
--     -- AND ABS(qty_FS - qty_SCR - salesusd_FS - salesusd_SCR - costusd_FS - costusd_SCR - costTRusd_FS - costTRusd_SCR) > 0.99
--     AND warehouseid = '444'
--     -- AND itemgroupid in ('C')
-- ORDER BY (qty_FS-qty_SCR) ASC


-----------------------------------------------------------------------------------------------------------------

-- run individual cte
    -- select finyear, month, companyid, warehouseid, storetype, vendorid, itemgroupid, itemmodelgroup, producttype, 
    --      department,  subdepartment,  class, subclass,tablesource,
    --     sum(qty) qty,sum(netsales) netsales, sum(cost) cost, sum(cost_tr) cost_tr
    -- FROM factscrdwh_agg
    -- group by finyear, month, companyid, warehouseid, storetype, vendorid, itemgroupid, itemmodelgroup, producttype, 
    --      department,  subdepartment,  class, subclass,tablesource


