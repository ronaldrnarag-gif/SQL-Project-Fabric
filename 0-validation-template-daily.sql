

use AzadeaWarehouse

-- This gives latest date to check the other dates against
declare @latestdate as date = cast(getdate()-1 as date)
select @latestdate as [Day-1]

-- check if all fact tables are updated with the latest date
select sourcemovement, cast(max(date) as date) latestupdate
from factinventory
group by sourcemovement

-- sales validation
select cast(date as date) [date of sales], DATEPART(WEEKDAY,date) weekday,
        format(count(*),'#,###') count_records,
        format(AVG(count(*)) over(), '#,###') count_totalavg
from factsalesnew
where date >= DATEADD(day,1,eomonth(DATEADD(MONTH,-1,getdate()-1)))
group by cast(date as date) ,  DATEPART(WEEKDAY,date)
order by 1

-- inventory validation 
select a.finyear [finyear-factinventory], b.fiscalmonthno monthno, a.[month], 
    format(sum(a.total_stk_usd), '#,###') total_stk_usd, 
    format(sum(a.total_prov_usd), '#,###') total_prov_usd,
    format(sum(a.total_stk_usd)-lag(sum(a.total_stk_usd)) over (order by b.fiscalmonthno),'#,###') [stk_incdec],
    format(sum(a.total_prov_usd)-lag(sum(a.total_prov_usd)) over (order by b.fiscalmonthno),'#,###') [prov_gainorloss]
from fact_inventory_historical a
left join vw_dimmonthcalendar b
        on a.fiscalyearmonthkey=b.fiscalyearmonthkey
where a.finyear = '2026-27'
and a.itemgroupname in ('NORMAL PURCHASE','PURCHASE FOREIGN')
and a.department <> 'SERVICES'
Group by a.finyear, b.fiscalmonthno , a.[month]
order by 1,2

-- check whether SCR got updated for MTD 
select a.finyear [finyear-scrdwh], b.fiscalmonthno monthno, a.month, 
    FORMAT(sum(case when upper(a.dataareaid) = 'UAE' then ancpstkend_usd else 0 end), '#,###') UAE,
    FORMAT(sum(case when upper(a.dataareaid) = 'QAT' then ancpstkend_usd else 0 end), '#,###') QAT,
    FORMAT(sum(case when upper(a.dataareaid) = 'BAH' then ancpstkend_usd else 0 end), '#,###') BAH,
    FORMAT(sum(case when upper(a.dataareaid) = 'OMN' then ancpstkend_usd else 0 end), '#,###') OMN,
    FORMAT(sum(case when upper(a.dataareaid) = 'KAT' then ancpstkend_usd else 0 end), '#,###') KAT,
    FORMAT(sum(ancpstkend_usd), '#,###') TOTALREGION,
    format(count(*), '#,###') count_totalrecords
from factscrdwh a
left join vw_dimmonthcalendar b
        on a.finyear=b.fiscalperiod
        and upper(a.[month])=UPPER(b.[month])
where a.finyear = '2026-27'
        and a.itemgroupid in ('I','N')
        and a.deptname <> 'SERVICES'
group by a.finyear, b.fiscalmonthno , a.[month]
order by 1, 2



/*
------ NON CRITICAL CHECKS -----------------

use Lakehouse_Curated

-- itemgroup mismatch between inventtrans and inventtrans_origin
; with mismatch_agg as (
        select * from (
        select cast(a.datephysical as date) datephysical, a.inventtransorigin, a.dataareaid, a.itemid, 
                a.ltitemgroupid ltitemgroupid_inventtrans, b.ltitemgroupid ltitemgroupid_inventtransorigin, a.apntprimaryvendorid,
                sum(qty) transqty
        from inventtrans a
        left join inventtransorigin b
                on a.itemid=b.itemid
                and a.dataareaid=b.dataareaid
                and a.inventtransorigin = b.recid
        where upper(a.dataareaid) not in ('EGP','KWT','JOR')
        group by a.datephysical, a.inventtransorigin, a.dataareaid, a.itemid, 
                a.ltitemgroupid , b.ltitemgroupid , a.apntprimaryvendorid
                        ) t
        where ltitemgroupid_inventtrans <> ltitemgroupid_inventtransorigin
        )
select a.*, b.vendorid [vendorid-dimproduct], b.vendorgroup [vendorgroup-dimproduct]
from mismatch_agg a
left join [AzadeaWarehouse].[dbo].[dimproduct] b
        on UPPER(a.dataareaid)=UPPER(b.companyid)
        and a.itemid = b.productid
order by a.datephysical desc
*/



