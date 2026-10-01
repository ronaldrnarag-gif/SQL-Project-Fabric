
use AzadeaWarehouse
use Lakehouse_Presentation
use Lakehouse_Curated


-- check if all fact tables are updated with the latest date
select sourcemovement, max(date) maxdate
from factinventory
group by sourcemovement

-- sales validation
select cast(date as date) date, format(count(*),'#,###') totalrecords
from factsalesnew
where date >= '2026-09-01'
group by cast(date as date) order by 1

-- inventory validation 
select finyear, month, sum(total_stk_usd)total_stk_usd, sum(total_prov_usd)total_prov_usd
from fact_inventory_historical
where finyear in ('2026-27','2025-26') 
and itemgroupname in ('NORMAL PURCHASE','PURCHASE FOREIGN')
and department <> 'SERVICES'
Group by finyear, month
order by 1,2