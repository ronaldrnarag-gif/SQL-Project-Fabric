
declare @finyear VARCHAR(10) = '2026-27'
declare @monthperiod VARCHAR(10) = 'Aug'
 
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
    where a.finyear = @finyear and a.month = @monthperiod
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



select top 10 * from factscrdwh


    select b.itemmodelgroup, b.producttype, a.*
    from factsalesnew a
    left join dimproduct b
        on UPPER(a.company)=UPPER(b.companyid)
        and a.productkey=b.productkey
    left join dimexchangeratedwh d
        on UPPER(a.company)=UPPER(d.companyid)
    where 1=1
        and finyear = '2026-27' 
            and [month] = 'Sep'
        and b.itemmodelgroup = 'FIFO'
        and a.itemgroupname is NULL


select distinct itemgroupname from factsalesnew
select top 10 * from factsalesnew where itemname like 'MTS V%'
select top 10 * from dimproduct where UPPER(hir2) = 'TICKETING'



select a.finyear, b.fiscalmonthno monthno --, a.month
    ,format(
            sum(a.sales_usd)
            , '#,###') sales_usd
    ,format(
            sum(SUM(a.sales_usd)) over (PARTITION BY a.finyear ORDER BY a.finyear, b.fiscalmonthno desc) -- rows BETWEEN unbounded preceding and current row)
            , '#,###')
from factsalesnew a
left join vw_dimmonthcalendar b
    on a.finyear=b.fiscalperiod
    and upper(a.month)=upper(b.[month])
where 1=1
    and a.finyear in ('2026-27','2025-26')
    and [level] = 'L-1'
group by a.finyear, b.fiscalmonthno  --, a.month
order by 1, 2


