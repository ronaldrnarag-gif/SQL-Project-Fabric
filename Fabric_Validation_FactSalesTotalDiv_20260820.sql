
USE AzadeaWarehouse

select * from sys.tables order by name

select * from dimlfltotaldiv

select top 10 * from factsalestotaldiv

------

select branddesc, finyear, month, date, company, warehouseid, level, islfl, day(date) dayno,
        sum(salesusd) salesusd, sum(costusd) costusd, sum(claimamountusd) claimamountusd, sum(marginusd) marginusd
from factsalestotaldiv
where finyear in ('2026-27','2025-26')
and month in ('Feb','Mar','Apr','May','Jun','Jul','Aug')
group by branddesc, finyear, month, date, company, warehouseid, level, islfl, day(date)


select * from dimlfltotaldiv order by brandname, countrycode desc, storecode

select distinct branddesc from factsalestotaldiv

02BOSE10
02BOWB2B

Select top 10 * from dimstoretotaldiv where bu in ('02BOSE10','02BOWB2B')

