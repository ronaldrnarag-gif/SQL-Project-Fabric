

CREATE VIEW vw_fnl_sop_base_data (

/*

Purpose             :   Source Data for S&OP Teams forecast exercise
Stakeholder         :   Abdelrahman Oraby
Calculation logic : 
    combines full item master product listing
    +
    stock for last 3 months
    +
    sales for last 24 months

Created     : ronaldn/20261109

*/


; WITH itemmaster_agg as (
    SELECT upper(a.companyid) company, a.productkey, a.productid, a.productname, a.itembarcode, a.vendorgroup,
        a.hir1 department, a.hir2 subdepartment, a.hir3 class, a.hir4 subclass, a.ltbrand brand, a.abcflag, a.pgdescription, 
        cast(b.frdentity as date) frdentity, cast(c.lrdentity as date) lrdentity,
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
        cast(b.frdentity as date) , cast(c.lrdentity as date) ,
        (a.productprice * d.exchangeratenew) 
    ),

inventoryhistory_agg as (
    select a.company, a.productkey,
        sum(case when cast(b.fiscalmonthposition as int) = -6 then a.total_stk_qty else 0 end) qtyoh_6m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -5 then a.total_stk_qty else 0 end) qtyoh_5m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -4 then a.total_stk_qty else 0 end) qtyoh_4m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -3 then a.total_stk_qty else 0 end) qtyoh_3m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -2 then a.total_stk_qty else 0 end) qtyoh_2m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -1 then a.total_stk_qty else 0 end) qtyoh_1m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = 0 then a.total_stk_qty else 0 end) qtyoh_0m_ago
    from fact_inventory_historical a
    left join vw_dimmonthcalendar b
        on a.fiscalyearmonthkey=b.fiscalyearmonthkey
    where 1=1
    and b.fiscalmonthposition in ('0','-1','-2')
    group by a.company, a.productkey
    ),

saleshistory_agg as (
    select a.company, a.productkey,
        sum(case when cast(b.fiscalmonthposition as int) = -12 then a.qty else 0 end) qtysold_12m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -11 then a.qty else 0 end) qtysold_11m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -10 then a.qty else 0 end) qtysold_10m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -9 then a.qty else 0 end) qtysold_9m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -8 then a.qty else 0 end) qtysold_8m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -7 then a.qty else 0 end) qtysold_7m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -6 then a.qty else 0 end) qtysold_6m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -5 then a.qty else 0 end) qtysold_5m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -4 then a.qty else 0 end) qtysold_4m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -3 then a.qty else 0 end) qtysold_3m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -2 then a.qty else 0 end) qtysold_2m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -1 then a.qty else 0 end) qtysold_1m_ago,
        sum(case when cast(b.fiscalmonthposition as int) = -0 then a.qty else 0 end) qtysold_0m_ago
    from factsalesnew a
    left join vw_dimmonthcalendar b
        on a.finyear=b.fiscalperiod
        and upper(a.[month])=UPPER(b.[month])
    where 1=1
    and cast(b.fiscalmonthposition as int) between -23 and 0
    group by a.company, a.productkey
)


select *
from (
select a.*,
    sum(b.qtyoh_6m_ago) qtyoh_6m_ago, sum(b.qtyoh_5m_ago) qtyoh_5m_ago, sum(b.qtyoh_4m_ago) qtyoh_4m_ago, sum(b.qtyoh_3m_ago) qtyoh_3m_ago, sum(b.qtyoh_2m_ago) qtyoh_2m_ago, sum(b.qtyoh_1m_ago) qtyoh_1m_ago, sum(b.qtyoh_0m_ago) qtyoh_0m_ago,
    sum(c.qtysold_12m_ago) qtysold_12m_ago, sum(c.qtysold_11m_ago) qtysold_11m_ago, sum(c.qtysold_10m_ago) qtysold_10m_ago, sum(c.qtysold_9m_ago) qtysold_9m_ago, sum(c.qtysold_8m_ago) qtysold_8m_ago, 
        sum(c.qtysold_7m_ago) qtysold_7m_ago, sum(c.qtysold_6m_ago) qtysold_6m_ago, sum(c.qtysold_5m_ago) qtysold_5m_ago, sum(c.qtysold_4m_ago) qtysold_4m_ago, sum(c.qtysold_3m_ago) qtysold_3m_ago, 
        sum(c.qtysold_2m_ago) qtysold_2m_ago, sum(c.qtysold_1m_ago) qtysold_1m_ago,  sum(c.qtysold_0m_ago) qtysold_0m_ago
from itemmaster_agg a
left join inventoryhistory_agg b
    on upper(a.company)=UPPER(b.company)
    and a.productkey=b.productkey
left join saleshistory_agg c
    on upper(a.company)=UPPER(c.company)
    and a.productkey=c.productkey
where 1=1
    and a.company not in ('JOR','EGP','KWT')
group by a.company, a.productkey, a.productid, a.productname, a.itembarcode, a.vendorgroup, a.department, 
    a.subdepartment, a.class, a.subclass, a.brand, a.abcflag, a.pgdescription, a.frdentity, a.lrdentity, a.price_usd
) t


;