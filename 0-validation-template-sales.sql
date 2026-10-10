
declare @finyear VARCHAR(10) = '2026-27'
declare @monthperiod VARCHAR(10) = 'Sep'
 
; with factsalesnew_agg as (
    select a.month, a.company companyid, a.warehouseid, a.supplier vendorid, a.itemgroupname itemgroupid, b.itemmodelgroup, b.producttype, 
        sum(a.qty) qty,sum(a.sales) netsales, sum(a.cost) cost, sum(a.cost_it) cost_tr,
        'factsalesnew' sourcetable
    from factsalesnew a
    left join dimproduct b
        on UPPER(a.company)=UPPER(b.companyid)
        and a.productkey=b.productkey
    left join dimexchangeratedwh d
        on UPPER(a.company)=UPPER(d.companyid)
    where finyear = @finyear and [month] = @monthperiod
    group by a.month, a.company, a.warehouseid, a.supplier , a.itemgroupname, b.itemmodelgroup, b.producttype
), 

factscrdwh_agg as (
    select a.month, a.dataareaid companyid, a.warehouse warehouseid, a.vendid vendorid, a.itemgroupid itemgroupid,b.itemmodelgroup, b.producttype,
        sum(-a.qtysales) qty, sum(-a.vspsales) netsales, sum(a.ancpsales) cost, sum(a.ancpsalestr) cost_tr,
        'factscrdwh' sourcetable
    from factscrdwh a
    left join dimproduct b
        on upper(a.dataareaid)=upper(b.companyid)
        and a.itemid=b.productid
    where a.finyear = @finyear and [month] = @monthperiod
    group by a.month, a.dataareaid , a.warehouse , a.vendid , a.itemgroupid ,b.itemmodelgroup, b.producttype
),

base_agg as (
    select * from factsalesnew_agg
    UNION ALL
    select * from factscrdwh_agg
)


select * from base_agg

-------------------------

