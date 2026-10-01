

select sum(sales_usd) sales_usd, sum(cost_usd) cost_usd, sum(claimamount_usd) claimamount_usd, sum(margin_usd) margin_usd
from factsalesnew
where date between '2026-09-01' and '2026-09-10'
    and warehouseid = '405'


select *
from factsalesnew
where date between '2026-09-01' and '2026-09-10'
    and warehouseid = '405'

-- no issues
select finyear, month, company, level, subclass, itemgroupname, supplier, suppliername, 
    sum(sales_usd) sales_usd, sum(cost_usd) cost_usd, sum(claimamount_usd) claimamount_usd, sum(margin_usd) margin_usd
from factsalesnew
where finyear = '2026-27' and month = 'Aug' 
group by finyear, month, company, level, subclass, itemgroupname, supplier, suppliername


select level, 
    sum(sales_usd) sales_usd, sum(cost_usd) cost_usd, sum(claimamount_usd) claimamount_usd, sum(margin_usd) margin_usd
from factsalesnew
where finyear = '2026-27' 
group by level