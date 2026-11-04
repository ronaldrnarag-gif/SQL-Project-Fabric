

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


select *
from (
    select a.companyid, a.productgroup, a.itemmodelgroup, a.vendorgroup, a.hir1, a.ishardware, a.ltbrand, 
        sum(a.qtyoh) qtyoh, sum(a.costoh) costoh, sum(a.costprovision) costprovision, sum(a.costoh * b.exchangeratenew) costoh_usd, sum(a.costprovision * b.exchangeratenew) costprovision_usd
    from factfifoinventory a
    left join [AzadeaWarehouse].[dbo].[dimexchangeratedwh] b
        on UPPER(a.companyid) = upper(b.companyid)
    group by a.companyid, a.productgroup, a.itemmodelgroup, a.vendorgroup, a.hir1, a.ishardware, a.ltbrand
) t



