

/*

Purpose : functional logic related to the original  MLSS
Logic   : CTE Sales (Union All) CTE latest stock
Created : ronaldn/20260918

*/

-- ==============================================================
-- SALES DB - from factsalesnew
-- ==============================================================

WITH sales_agg AS
(
    SELECT 
        dd.fiscalperiod finyear, f.date, dd.monthshortname month, dd.fiscalweek week,
        f.company, f.warehouseid,  ds.warehousename, ds.storetype,
        f.productkey, f.productid, dp.productname, dp.hir1 department, dp.hir2 subdepartment, dp.hir3 class, dp.hir4 subclass, dp.vendorgroup,
        f.supplier, dp.vendorname, f.brand, f.level,
        SUM(f.qty) AS qtysold,
        SUM(f.sales) AS sales,
        SUM(f.cost) AS cost,
        SUM(f.claimamount) AS claimamount,
        SUM(f.margin) AS margin,
        SUM(f.vat) AS vat,
        SUM(f.sales_usd) AS sales_usd,
        SUM(f.cost_usd) AS cost_usd,
        SUM(f.margin_usd) AS margin_usd,
        SUM(f.claimamount_usd) AS claimamount_usd,
        0 as latestohqty,
        0 as latestoh,
        0 as latestoh_usd,
        0 as latestohprov,
        0 as latestohprov_usd

    FROM factsalesnew f

    LEFT JOIN dimdate dd
        on f.[date] = dd.[date]

    LEFT JOIN dimproduct dp
        ON f.productkey = dp.productkey
        and upper(f.company)=upper(dp.companyid)

    LEFT JOIN dimstore ds
        ON f.warehouseid= ds.warehouseid

    WHERE f.date >= '2024-02-01'
        -- and f.[level] <> 'L-3'

    GROUP BY
        dd.fiscalperiod , f.date, dd.monthshortname , dd.fiscalweek , f.company, f.warehouseid, ds.warehousename, ds.storetype, f.productkey, f.productid, dp.productname, dp.hir1, dp.hir2, dp.hir3, dp.hir4, dp.vendorgroup,
        f.supplier, dp.vendorname, f.brand, f.level
),

-- ==============================================================
-- STOCK DB -- from fact_inventory_with_provision_aging
-- ==============================================================

stock_agg AS (

--        f.productkey, f.productid, dp.productname, dp.hir1, dp.hir2, dp.hir3, dp.hir4, dp.vendorgroup,
--        f.supplier, dp.vendorname, f.brand, f.level,

    SELECT
        (select DISTINCT fiscalperiod
        from dimdate 
        where date = cast(GETDATE()-1 as date)) as finyear,   -- year
        cast(GETDATE()-1 as date) date,         -- date
        (select DISTINCT monthshortname
        from dimdate 
        where date = cast(GETDATE()-1 as date)) as month,     -- month
        (select DISTINCT fiscalweek
        from dimdate 
        where date = cast(GETDATE()-1 as date)) as week,      -- week

        fv.company, fv.warehouseid, ds.warehousename, ds.storetype,
        fv.productkey, fv.productid, dp.productname, dp.hir1 department, dp.hir2 subdepartment, dp.hir3 class, dp.hir4 subclass, dp.vendorgroup,
        fv.supplier,  dp.vendorname, fv.brand, 
        CASE 
            when fv.storetype = 'InterCompany' then 'L-3'
            when fv.itemgroupname in ('NORMAL PURCHASE','PURCHASE FOREIGN','CONSIGNMENT','DROP-SHIPPING') then 'L-1'
            else 'L-2'
        END as level,
        0 as qtysold,
        0 as sales,	
        0 as cost,	
        0 as claimamount,	
        0 as margin,	
        0 as vat,	
        0 as sales_usd,	
        0 as cost_usd,	
        0 as margin_usd,	
        0 as claimamount_usd,
        SUM(fv.total_stk_qty) AS latestohqty,
        SUM(fv.total_stk) AS latestoh,
        SUM(fv.[total_stk$]) AS latestoh_usd,
        SUM(fv.[total_prov]) AS latestohprov,
        SUM(fv.[total_prov$]) AS latestohprov_usd

    FROM fact_inventory_with_provision_aging fv      

    LEFT JOIN dimproduct dp  
        ON upper(fv.company)=UPPER(dp.companyid)
            and fv.productkey = dp.productkey
    LEFT JOIN dimstore ds
        ON fv.warehouseid=ds.warehouseid
   
    GROUP BY 

        fv.company, fv.warehouseid, ds.warehousename, ds.storetype, fv.productkey, fv.productid, dp.productname, dp.hir1, dp.hir2, dp.hir3, dp.hir4, dp.vendorgroup,
        fv.supplier,  dp.vendorname, fv.brand, 
        CASE 
            when fv.storetype = 'InterCompany' then 'L-3'
            when fv.itemgroupname in ('NORMAL PURCHASE','PURCHASE FOREIGN','CONSIGNMENT','DROP-SHIPPING') then 'L-1'
            else 'L-2'
        END 
    )

---------- FINAL OUTPUT -----------



select finyear, company, level, vendorgroup, 
   sum(sales_usd) sales_usd, sum(cost_usd) cost_usd, sum(claimamount_usd) claimamount_usd, sum(margin_usd) margin_usd
from sales_agg
group by finyear, company, level, vendorgroup

SELECT *
from (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM stock_agg
    ) t



--count(*) -- 9,371,809 



select finyear, company, level, itemgroupname, 
   sum(sales_usd) sales_usd, sum(cost_usd) cost_usd, sum(claimamount_usd) claimamount_usd, sum(margin_usd) margin_usd
from factsalesnew
where date >= '2024-02-01'
group by finyear, company, level, itemgroupname


select finyear, company, level, vendorgroup,
   sum(sales_usd) sales_usd, sum(cost_usd) cost_usd, sum(claimamount_usd) claimamount_usd, sum(margin_usd) margin_usd, sum(latestoh_usd) latestoh_usd, sum(latestohprov_usd) latestohprov_usd
from vw_mlssorig
group by finyear, company, level, vendorgroup
