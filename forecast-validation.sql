
-- validation tool to validate the historical forecast for months of sep and oct 2026 where we can draw statistics for future reporting.

use Lakehouse_ml

; with forecast_agg as (
    select year(date) year, month(date) month, day(date) day, date, warehouseid, left(warehouseid,1) company,
        cast(sum(forecastsales_usd) as int) sales_usd, cast(sum(forecastmargin_usd) as int) margin_usd,
        'Forecast' Source
    from factsales_brand_forecast_v3_backtest 
    where 1=1
        and date between '2026-09-01' and '2026-10-31'
    group by year(date) , month(date) , day(date) , date, warehouseid, left(warehouseid,1) 
),
   
actual_agg as (
    select year(date) year, month(date) month, day(date) day, date, warehouseid, left(warehouseid,1) company,
        sum(sales_usd) sales_usd, sum(margin_usd) margin_usd,
        'Actual' Source
    from factsalesnew
    where 1=1
        and [level] = 'L-1'
        and finyear = '2026-27' and [month] in ('Sep','Oct')
    group by year(date) , month(date) , day(date) , date, warehouseid, left(warehouseid,1)
),

base_agg as (
    select * from forecast_agg
    union all
    select * from actual_agg
)

select t.*, (Forecastedsales_usd-Actualsales_usd) forecastvariance
from (
select year, month, day, date, company, warehouseid,
    sum(case when Source='Forecast' then sales_usd else 0 end) Forecastedsales_usd, 
    sum(case when Source='Actual' then sales_usd else 0 end) Actualsales_usd
from base_agg
group by year, month, day, date, company, warehouseid
) t

