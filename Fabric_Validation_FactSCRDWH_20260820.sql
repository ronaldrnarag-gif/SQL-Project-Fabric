

USE Lakehouse_Curated
USE AzadeaWarehouse

select * from sys.tables

----CUREATED--------------------------------------------------------------------------

select top 10 * from ltscrheadermtd order by recid 
select top 10 * from ltscrlinesmtd order by recid

select distinct recid from ltscrheadermtd


-- Curated MTD SCR
select  itemgroup, dataareaid, refrecid, warehouse, 
	sum(ancpstkstart) ancpstkstart, sum(ancpstkend) ancpstkend
from ltscrlinesmtd a
where exists (
	select 1
	from ltscrheadermtd b
	where a.refrecid=b.recid
	and fromdate is not null 
)
group by itemgroup, dataareaid, refrecid, warehouse


----WAREHOUSE--------------------------------------------------------------------------


select dataareaid, refrecid, warehouse, itemgroup,
	sum(ancpstkstart_usd) ancpstkstart_usd, sum(ancpstkend_usd) ancpstkend_usd
from factscrdwh
where finyear = '2026-27'
and month = 'Aug'
group by dataareaid, refrecid, warehouse, itemgroup