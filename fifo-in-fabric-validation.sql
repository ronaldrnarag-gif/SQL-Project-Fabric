
use Lakehouse_Presentation

select * from sys.tables order by name

select top 10 * from factfifoinventory


select count(*) from factfifoinventory

use AzadeaWarehouse





select * from fact_inventory_with_provision_aging

select distinct finyear, [month] from fact_inventory_historical
order by 1,2




use AzadeaWarehouse

select top 10 * from [shared].[vw_openpo]


select * from dimexchangeratedwh


use Lakehouse_Presentation

select * from sys.tables order by name

select top 10 * from 
vVirginMegatoreHeadCount

use Lakehouse_ml

select * from sys.tables order by name

select a.date, b.companyid,
    sum(a.forecastsales_usd) forecastsales_usd, sum(a.forecastmargin_usd) forecastmargin_usd
from factsales_brand_forecast a
left join [AzadeaWarehouse].[dbo].[dimstore] b
    on a.warehouseid=b.warehouseid
group by a.date,  b.companyid
