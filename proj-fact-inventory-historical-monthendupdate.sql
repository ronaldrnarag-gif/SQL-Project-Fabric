
/*

Rationale : avoid having last month data being blank in our reporting due to BD file from SIPBIAE03 server not being available during first few days of each month.

Run the following steps during month end closing :

Step 1: On 1st Day of Each month run the below script to create back up of last months inventory file: 

    drop table if exists fact_inventory_with_provision_aging-Clone;
    SELECT * 
    INTO fact_inventory_with_provision_aging-Clone
    FROM fact_inventory_with_provision_aging
    ;
    
    fact_inventory_with_provision_aging -- vw_stockageing
    fact_inventory_historical -- fact_stockprogressionsku

Step 2: Run the below query starting 2nd of month onwards until latest BD file is inserted into our fact_inventory_historical table

Step 3: Run the below query to validate : 
    
    -- inventory validation 
    select finyear, month, sum(total_stk_usd)total_stk_usd, sum(total_prov_usd)total_prov_usd
    from fact_inventory_historical
    where finyear = '2026-27'
    and itemgroupname in ('NORMAL PURCHASE','PURCHASE FOREIGN')
    and department <> 'SERVICES'
    Group by finyear, month
    order by 1,2

Step 4 : DELETE the data inserted via step 2 once the latest BD file is inserted into our fact_inventory_historical table

    truncate table fact_inventory_historical
    where finyear = '2026-27'
    and month = 'SEP'


*/

-- Step 2 Query 

WITH DIMDATE_MONTH AS
(
    SELECT DISTINCT
        fiscalperiod,
        UPPER(monthshortname) AS monthshortname,
        CASE UPPER(monthshortname)
            WHEN 'FEB' THEN 1  WHEN 'MAR' THEN 2  WHEN 'APR' THEN 3
            WHEN 'MAY' THEN 4  WHEN 'JUN' THEN 5  WHEN 'JUL' THEN 6
            WHEN 'AUG' THEN 7  WHEN 'SEP' THEN 8  WHEN 'OCT' THEN 9
            WHEN 'NOV' THEN 10 WHEN 'DEC' THEN 11 WHEN 'JAN' THEN 12
        END AS fiscalmonthno
    FROM dbo.dimdate
),

DIMPRODUCT_DEDUP AS
(
    SELECT *
    FROM (
        SELECT dp.*,
               ROW_NUMBER() OVER (PARTITION BY dp.productid, UPPER(dp.companyid)
                                  ORDER BY dp.creationdate DESC) AS rn
        FROM dbo.dimproduct dp
    ) x

    WHERE rn = 1
)

INSERT INTO dbo.fact_inventory_historical
(
    fiscalyearmonthkey, finyear, month, country, company,
    warehouseid, storename, storeshortname,
    productkey, productid, description,
    dept2, department, subdepartment, class, subclass,
    brand, artist,
    wac, total_stk_qty, total_stk, total_stk_usd, total_prov, total_prov_usd,
    frdentity, lrdstore, lrdentity,
    supplier, suppliername, itemgroupname,
    stockbracket, stockbracketdescription, popgradeno,
    isreturnable, storetype, isdropshipping,
    promoyn, abcflag, isdemostock, ishardware, subclasscode,
    source, rtvrecommendation,
    apntprimaryvendorid_it, ltitemgroupid_it, inventstatusid_it
)

SELECT 
    CAST(REPLACE(f.finyear, '-', '') +
         RIGHT('00' + CAST(dd.fiscalmonthno AS VARCHAR(2)), 2) AS INT) AS fiscalyearmonthkey,
    f.finyear,
    UPPER(f.month),
    f.country,
    f.company,

    CAST(f.warehouseid AS VARCHAR(50)),
    CASE WHEN ds.storename IS NULL OR LTRIM(RTRIM(ds.storename)) = ''
         THEN ds.warehousename ELSE ds.storename END,
    ds.ltshortname,

    CAST(f.productkey AS VARCHAR(50)),
    CAST(f.productid  AS VARCHAR(50)),
    dp.productname,

    CASE WHEN dp.hir1 IN ('ELECTRONICS','GAMING','MUSIC') THEN 'TECH'
         ELSE 'LIFESTYLE' END,
    dp.hir1,
    dp.hir2,
    dp.hir3,
    dp.hir4,

    f.brand,
    dp.ltartist,

    CAST(f.wac            AS DECIMAL(18,4)),
    CAST(f.total_stk_qty  AS DECIMAL(18,4)),
    CAST(f.total_stk      AS DECIMAL(18,4)),
    CAST(f.[total_stk$]   AS DECIMAL(18,4)),
    CAST(f.total_prov     AS DECIMAL(18,4)),
    CAST(f.[total_prov$]  AS DECIMAL(18,4)),

    CAST(f.frdentity AS VARCHAR(50)),
    CAST(f.lrdstore  AS VARCHAR(50)),
    CAST(f.lrdentity AS VARCHAR(50)),

    CAST(f.supplier AS VARCHAR(50)),
    dp.vendorname,

    CASE
        WHEN UPPER(f.itemgroupname) = 'N'       THEN 'NORMAL PURCHASE'
        WHEN UPPER(f.itemgroupname) = 'S'       THEN 'SERVICE'
        WHEN UPPER(f.itemgroupname) = 'SERVICE' THEN 'SERVICE'
        WHEN UPPER(f.itemgroupname) = 'C'       THEN 'CONSIGNMENT'
        WHEN UPPER(f.itemgroupname) = 'D'       THEN 'CONCESSION'
        WHEN UPPER(f.itemgroupname) = 'H'       THEN 'DROP-SHIPPING'
        WHEN UPPER(f.itemgroupname) = 'I'       THEN 'PURCHASE FOREIGN'
        ELSE UPPER(f.itemgroupname)
    END,

    CAST(f.stockbracket AS VARCHAR(50)),
    CAST(f.stockbracketdescription AS VARCHAR(100)),
    CAST(f.popgradeno AS VARCHAR(50)),

    CAST(f.isreturnable   AS VARCHAR(10)),
    CAST(ds.storetype     AS VARCHAR(50)),
    CAST(f.isdropshipping AS VARCHAR(10)),

    CAST(f.promoyn AS VARCHAR(10)),
    CAST(f.abcflag AS VARCHAR(10)),
    NULL,
    dp.ishardware,
    NULL,

    eomonth(dateadd(month,-1,cast(getdate()-1 as date))), -- This is the last day of the previous month, RN
    CAST(f.rtvrecommendation AS VARCHAR(50)),
    f.apntprimaryvendorid_it,
    f.ltitemgroupid_it,
    f.inventstatusid_it

FROM [dbo].[fact_inventory_with_provision_aging-Clone] f
LEFT JOIN dbo.dimstore ds
       ON f.warehouseid = ds.warehouseid
      AND UPPER(f.company) = UPPER(ds.companyid)
LEFT JOIN DIMPRODUCT_DEDUP dp
       ON f.productid = dp.productid
      AND UPPER(f.company) = UPPER(dp.companyid)
LEFT JOIN DIMDATE_MONTH dd
       ON dd.fiscalperiod = f.finyear
      AND dd.monthshortname = UPPER(f.month)
;



