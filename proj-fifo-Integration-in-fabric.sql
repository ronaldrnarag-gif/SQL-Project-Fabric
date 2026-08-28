
USE Lakehouse_Curated
USE Lakehouse_Presentation
USE AzadeaWarehouse

select * from INFORMATION_SCHEMA.TABLES order by TABLE_TYPE, TABLE_NAME
select * from sys.tables order by name

select top 10 * from cfz_inventagingreportheadertable
select top 10 * from cfz_inventagingreportlinestablereceipt

---------------


select distinct sysdatastatecode from cfz_inventagingreportheadertable

select top 50 *
from (
	select b.reportexecution,b.lastexecutiondate,a.* 
	from cfz_inventagingreportlinestablereceipt a
	left join cfz_inventagingreportheadertable b
		on a.reportname=b.reportname 
		and a.headerrefrecid=b.recid
		and a.isincremental = 1
	where a.[delete] = 0) t



select top 10 * from cfz_inventagingreportlinestablereceipt


select dataareaid, itemgroupid, 
	sum(qtytotal) qtytotal, sum(valuetotal) valuetotal
from (
	select b.reportexecution,b.lastexecutiondate,a.* 
	from cfz_inventagingreportlinestablereceipt a
	left join cfz_inventagingreportheadertable b
		on a.reportname=b.reportname 
		and a.headerrefrecid=b.recid
		and a.isincremental = 1
	where a.[delete] = 0) t

