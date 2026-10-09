
declare @finyear VARCHAR(10) = '2026-27'
declare @monthno int = 9
declare @monthperiod VARCHAR(10) = 'Sep'

; with factsales_agg as (
    select (case when month(a.date) = 8 then 'Aug' when month(a.date) = 9 then 'Sep' else '' end) month, 
        a.companyid, c.warehouseid, a.apntprimaryvendorid_it vendorid, a.ltitemgroupid_it itemgroupid,   
        sum(a.qty) qty,sum(a.netsales) netsales, sum(a.cost) cost, sum(a.cost_it) cost_tr
    from factsales a
    left join dimproduct b
        on UPPER(a.companyid)=UPPER(a.companyid)
        and a.productkey=b.productkey
    left join dimstore c
        on a.locationkey=c.locationkey
    left join dimexchangeratedwh d
        on UPPER(a.companyid)=UPPER(d.companyid)
    where month(a.date) = @monthno
    group by (case when month(a.date) = 8 then 'Aug' when month(a.date) = 9 then 'Sep' else '' end) , 
        a.companyid, c.warehouseid, a.apntprimaryvendorid_it , a.ltitemgroupid_it 
), 

factscrdwh_agg as (
    select month, dataareaid companyid, warehouse warehouseid, vendid vendorid, itemgroupid itemgroupid,
        sum(qtysales) qty, sum(vspsales) netsales, sum(ancpsales) cost, sum(ancpsalestr) cost_tr
    from factscrdwh
    where finyear = @finyear and [month] = @monthperiod
    group by [month], dataareaid , warehouse , vendid , itemgroupid 
),

base_agg as (
    select * from factsales_agg
    UNION ALL
    select * from factscrdwh_agg
)


select count(*) from base_agg
