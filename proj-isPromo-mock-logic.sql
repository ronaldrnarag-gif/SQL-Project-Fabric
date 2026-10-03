
;
select ispromotion, sum(sales_usd) totalsales, sum(cost_usd) cost_usd,sum(claimamount_usd) claimamount_usd ,sum(margin_usd) totalmargin, sum(discvalue) totaldiscvalue, sum(qty) totalqty
from (
    select *,
        case 
            when discvalue > 2 and 
                ltpromotionid is not null or offerid is not null 
            then 'Y' else 'N' 
            end as ispromotion
        from (
            select *, (
                basesalesprice_invent/
                nullif(
                1+(vat/nullif(sales,0))
                    ,0) -
                sales/nullif(qty,0)) as discvalue
            from factsalesnew 
            where date between '2026-09-01' and '2026-09-30' 
            and company='UAE'
            and level = 'L-1' 
        ) t
) tt
group by ispromotion