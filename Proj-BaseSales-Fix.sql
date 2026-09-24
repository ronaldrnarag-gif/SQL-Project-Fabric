

use Lakehouse_Curated
use Lakehouse_Presentation
use AzadeaWarehouse

select * from INFORMATION_SCHEMA.TABLES order by 4,3

inventtable -- doesnt include variants

-- these 2 has a lot of nulls in them
custinvtrans.ltbasesalesprice
rtst.ltbasesalesprice

Table: InventTableModule
Field: ModuleType = Sales order
Field: Price

Table: inventtablemodule 
Field: ModuleType = Sales order 
Field: Price

------------------------------------------------------------------

-- check on price duplicates
select itemid, sum(counter)
from (
    select *, 1 as counter
    from inventtablemodule 
    where dataareaid = 'uae'
    and moduletype = 2
    -- order by 4 desc
    ) t
group by itemid
having sum(counter) > 1

-- easiest way to take out tax from price?

dataareaid, itemid, price, taxitemgroupid, 

select top 10 * from taxtrans 


----- SIM SCRIPT --------------------------------------------

; with price_agg as (
    select dataareaid company, itemid, price, taxitemgroupid
    from [Lakehouse_Curated].[dbo].[inventtablemodule] 
    where dataareaid = 'uae'
    and moduletype = 2
    )

-- select top 10 * from price_agg 

SELECT top 100 a.productid, b.price, a.basesalesprice, 
    a.vat/a.sales taxrate,
    a.*
FROM factsalesnew a
LEFT JOIN price_agg b
    ON upper(a.company) = upper(b.company)
    AND a.productid=b.itemid
WHERE a.company = 'QAT'
    AND a.itemgroupname in ('I','N','C')
    AND a.department = 'MUSIC'
    AND a.basesalesprice is NOT NULL
    AND a.qty <> 0
