
declare @finyear VARCHAR(10) = '2026-27'
declare @year int = 2026
declare @monthno int = 9
declare @monthperiod VARCHAR(10) = 'Sep'
 
; with factsalesnew_agg as (
    select (case when month(a.date) = 8 then 'Aug' when month(a.date) = 9 then 'Sep' else '' end) month, 
        a.company companyid, a.warehouseid, a.supplier vendorid, a.itemgroupname itemgroupid,   
        sum(a.qty) qty,sum(a.sales) netsales, sum(a.cost) cost, sum(a.cost_it) cost_tr,
        'factsales' sourcetable
    from factsalesnew a
    left join dimproduct b
        on UPPER(a.company)=UPPER(b.companyid)
        and a.productkey=b.productkey
    left join dimexchangeratedwh d
        on UPPER(a.company)=UPPER(d.companyid)
    where year(a.[date]) = @year
        and month(a.date) = @monthno
    group by (case when month(a.date) = 8 then 'Aug' when month(a.date) = 9 then 'Sep' else '' end) , 
        a.company, a.warehouseid, a.supplier , a.itemgroupname 
), 

factscrdwh_agg as (
    select month, dataareaid companyid, warehouse warehouseid, vendid vendorid, itemgroupid itemgroupid,
        sum(-qtysales) qty, sum(-vspsales) netsales, sum(ancpsales) cost, sum(ancpsalestr) cost_tr,
        'factscrdwh' sourcetable
    from factscrdwh
    where finyear = @finyear and [month] = @monthperiod
    group by [month], dataareaid , warehouse , vendid , itemgroupid 
),

base_agg as (
    select * from factsalesnew_agg
    UNION ALL
    select * from factscrdwh_agg
)


select * from base_agg

-------------------------

