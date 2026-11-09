

/*

dimproduct


*/




; WITH itemmaster_agg as (
    SELECT upper(a.companyid) companyid, a.productkey, a.productid, a.productname, a.itembarcode, a.vendorgroup,
        a.hir1 department, a.hir2 subdepartment, a.hir3 class, a.hir4 subclass, a.ltbrand brand, a.abcflag, a.pgdescription, 
        b.frdentity, c.lrdentity,
        (a.productprice * d.exchangeratenew) price_usd
    FROM dimproduct a
    LEFT JOIN vw_fnl_frdentity b
        on upper(a.companyid)=upper(b.companyid)
        and a.productkey = b.productkey
    LEFT JOIN vw_fnl_lrdentity c
        on upper(a.companyid)=upper(c.companyid)
        and a.productkey = c.productkey
    LEFT JOIN dimexchangeratedwh d
        on upper(a.companyid)=upper(c.companyid) 
    WHERE 1=1
        and pgdescription <> 'DELISTED'
    group by upper(a.companyid) , a.productkey, a.productid, a.productname, a.itembarcode, a.vendorgroup,
        a.hir1 , a.hir2 , a.hir3 , a.hir4 , a.ltbrand , a.abcflag, a.pgdescription, 
        b.frdentity, c.lrdentity,
        (a.productprice * d.exchangeratenew)
    ),

inventoryhistory_agg as (
    select a.fiscalyearmonthkey,
        sum(case when b.fiscalmonthposition = '-2' then a.total_stk_qty else 0 end) qtyoh_2m_ago,
        sum(case when b.fiscalmonthposition = '-1' then a.total_stk_qty else 0 end) qtyoh_1m_ago,
        sum(case when b.fiscalmonthposition = '0' then a.total_stk_qty else 0 end) qtyoh_currentmo
    from fact_inventory_historical a
    left join vw_dimmonthcalendar b
        on a.fiscalyearmonthkey=b.fiscalyearmonthkey
    where 1=1
    and b.fiscalmonthposition in ('0','-1','-2')
    group by a.fiscalyearmonthkey
    ),

saleshistory_agg as (
    select distinct b.fiscalyearmonthkey,a.finyear, a.[month]
    from factsalesnew a
    left join vw_dimmonthcalendar b
        on a.finyear=b.fiscalperiod
        and upper(a.[month])=UPPER(b.[month])
    where 1=1
    -- and b.fiscalmonthposition in ('0','-1','-2')
    and cast(b.fiscalmonthposition as int) between -23 and 0
)

select top 10 * from saleshistory_agg

select top 10 * from vw_dimmonthcalendar where fiscalperiod = '2026-27'

