
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

-----------------

use Lakehouse_Presentation

select top 10 * from fifoaging_latest



-- high level check of FIFO table

select *
from (
    select a.companyid, a.producttype, a.itemmodelgroup, a.vendorid vendorid_dp, a.productgroup itemgroupid_dp, a.apntprimaryvendorid_it vendorid_it, a.ltitemgroupid_it itemgroupid_it,a.hir1, a.ishardware, a.ltbrand, 
            a.stockbracket, a.stockbracketdescription, a.groupdescription, cast(a.reportdate as date) reportdate, 
        sum(a.qtyoh) qtyoh, sum(a.costoh) costoh, sum(a.costprovision) costprovision, sum(a.costoh * b.exchangeratenew) costoh_usd, sum(a.costprovision * b.exchangeratenew) costprovision_usd
    from fifoaging_latest a
    left join [AzadeaWarehouse].[dbo].[dimexchangeratedwh] b
        on UPPER(a.companyid) = upper(b.companyid)
    group by a.companyid, a.producttype, a.itemmodelgroup, a.vendorid , a.productgroup , a.apntprimaryvendorid_it , a.ltitemgroupid_it ,a.hir1, a.ishardware, a.ltbrand, 
            a.stockbracket, a.stockbracketdescription, a.groupdescription, cast(a.reportdate as date) 
) t



use azadeawarehouse

-- FACTINVENTORY
; with factinventory_agg as (
    select upper(a.companyid) companyid, b.producttype, b.itemmodelgroup, a.apntprimaryvendorid_it vendorid, a.ltitemgroupid_it itemgroupid,
            b.hir1 department,  b.ltbrand brand, 
            sum(a.netqty) netqty, sum(a.netcost) netcost,
            SUM(a.netcost * d.exchangeratenew) netcost_usd,  'factinventory' as tablesource
    from factinventory a    
    left join dimproduct b  
            on upper(a.companyid) = upper(b.companyid) 
            and a.productkey=b.productkey
    left join dimstore c    
            on a.locationkey = c.locationkey
    left join dimexchangeratedwh d
        on upper(a.companyid)=upper(d.companyid)
    where a.date <= '2026-10-31'    -- update with preferred month period
    and upper(a.companyid) not in ('KWT','JOR','EGP')       
    and b.itemmodelgroup <> 'FIFO'
    and b.producttype = '0'
    -- and b.vendorgroup not in ('F','M')
    group by upper(a.companyid) , b.producttype, b.itemmodelgroup, a.apntprimaryvendorid_it , a.ltitemgroupid_it ,
            b.hir1 ,  b.ltbrand
)

select * from factinventory_agg

select top 10 * from factscrdwh

select a.finyear , a.month, a.dataareaid company, a.vendid, a.itemgroupid, a.deptname, a.brand, 
	sum(qtystkend) stkendqty,
    FORMAT(sum(ancpstkend_usd), '#,###') stockend$
from factscrdwh a
where a.finyear = '2026-27'
		and a.month = 'Oct'
        and a.itemgroupid in ('I','N')
        and a.deptname <> 'SERVICES'
group by a.finyear , a.month, a.dataareaid , a.vendid, a.itemgroupid, a.deptname, a.brand
order by 3




select * from dimvendor