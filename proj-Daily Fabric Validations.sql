


use AzadeaWarehouse
-- use Lakehouse_Presentation
-- use Lakehouse_Curated

-- This gives latest date to check the other dates against
declare @latestdate as date = cast(getdate()-1 as date)
select @latestdate as [Day-1]

-- check if all fact tables are updated with the latest date
select sourcemovement, cast(max(date) as date) latestupdate
from factinventory
group by sourcemovement

-- sales validation
select cast(date as date) [date of sales], format(count(*),'#,###') totalrecords
from factsalesnew
where date >= DATEADD(day,1,eomonth(DATEADD(MONTH,-1,getdate()-1)))
group by cast(date as date) order by 1

-- inventory validation 
select finyear [finyear-factinventory], month, 
    format(sum(total_stk_usd), '#,###') total_stk_usd, 
    format(sum(total_prov_usd), '#,###') total_prov_usd
from fact_inventory_historical
where finyear = '2026-27'
and itemgroupname in ('NORMAL PURCHASE','PURCHASE FOREIGN')
and department <> 'SERVICES'
Group by finyear, month
order by 1,2

-- check whether SCR got updated for MTD 
select finyear [finyear-scrdwh], month, 
    FORMAT(sum(case when upper(dataareaid) = 'UAE' then ancpstkend_usd else 0 end), '#,###') UAE,
    FORMAT(sum(case when upper(dataareaid) = 'QAT' then ancpstkend_usd else 0 end), '#,###') QAT,
    FORMAT(sum(case when upper(dataareaid) = 'BAH' then ancpstkend_usd else 0 end), '#,###') BAH,
    FORMAT(sum(case when upper(dataareaid) = 'OMN' then ancpstkend_usd else 0 end), '#,###') OMN,
    FORMAT(sum(case when upper(dataareaid) = 'KAT' then ancpstkend_usd else 0 end), '#,###') KAT,
    FORMAT(sum(ancpstkend_usd), '#,###') TOTALREGION,
    format(count(*), '#,###') count_totalrecords
from factscrdwh
where finyear = '2026-27'
        and itemgroupid in ('I','N')
        and deptname <> 'SERVICES'
group by finyear, [month]
order by 1, 2

------ NON CRITICAL CHECKS -----------------

-- itemgroup mismatch between inventtrans and inventtrans_origin
-- if the statuses has a gap this will result to also a gap between factinventory and factscr

; with mismatch_agg as (
        select * from (
        select a.datephysical, a.inventtransorigin, a.dataareaid, a.itemid, 
                a.ltitemgroupid ltitemgroupid_inventtrans, b.ltitemgroupid ltitemgroupid_inventtransorigin,
                sum(qty) transqty
        from inventtrans a
        left join inventtransorigin b
                on a.itemid=b.itemid
                and a.dataareaid=b.dataareaid
                and a.inventtransorigin = b.recid
        where upper(a.dataareaid) not in ('EGP','KWT','JOR')
        group by a.datephysical, a.inventtransorigin, a.dataareaid, a.itemid, 
                a.ltitemgroupid , b.ltitemgroupid 
                        ) t
        where ltitemgroupid_inventtrans <> ltitemgroupid_inventtransorigin
        )
select *
from mismatch_agg a
order by datephysical desc


use Lakehouse_Curated

select count(*) from inventtrans --67,818,815
select count(*) from inventtransorigin -- 64,700,640

