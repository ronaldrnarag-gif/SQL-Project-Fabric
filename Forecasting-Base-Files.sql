

use AzadeaWarehouse
use Lakehouse_Presentation

/*

-- factfifoinventory
-- compare against the following for inventory validation
    1- factinventory
    2- fasctscr
-- compare against this dynamics report for fifo rules validation
    1- inventory aging

*/

select * from sys.tables order by name


select top 10 * from factfifoinventory

-- high level check of FIFO table
-- select count(*)
select *
from (
    select a.companyid, a.producttype, a.itemmodelgroup, a.vendorgroup, a.hir1, a.ishardware, a.ltbrand, 
            a.stockbracket,	a.stockbracketdescription, a.groupdescription, a.reportdate,
        sum(a.qtyoh) qtyoh, sum(a.costoh) costoh, sum(a.costprovision) costprovision, sum(a.costoh * b.exchangeratenew) costoh_usd, sum(a.costprovision * b.exchangeratenew) costprovision_usd
    from factfifoinventory a
    left join [AzadeaWarehouse].[dbo].[dimexchangeratedwh] b
        on UPPER(a.companyid) = upper(b.companyid)
    group by a.companyid, a.producttype, a.itemmodelgroup, a.vendorgroup, a.hir1, a.ishardware, a.ltbrand, 
            a.stockbracket,	a.stockbracketdescription, a.groupdescription, a.reportdate
) t



-- scr to be used for validation
select finyear, month, dataareaid, itemgroup, producttype, 
    sum(qtystkend) qtystkend, sum(ancpstkend) ancpstkend, sum(ancpstkend_usd) ancpstkend_usd
from factscrdwh 
where finyear = '2026-27' and [month] = 'Oct'
group by finyear, month, dataareaid, itemgroup, producttype

