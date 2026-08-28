

/*

-- LFL SCRIPT FOR FABRIC FACTSALES TABLE

select top 10 * from factsales
select top 10 * from dimproduct

select top 10 * from factsalesnew
select * from dimlfltotaldiv

select * from sys.tables order by name
_____________________

*/

UPDATE a
SET islfl = 
	CASE -- flags all 'Non LFL' scenarios else 'LFL'

		-- OPENINGS
		WHEN	b.type = 'new' 
				and b.typeperiod = 'TY'
				THEN 'Non LFL'

		WHEN	b.type = 'new' 
				and b.typeperiod = 'LY'
				and a.date between '2026-02-01' 
					and DATEFROMPARTS(year(dateadd(YEAR,1,b.startdate)),month(b.startdate),DAY(b.startdate))
				THEN 'Non LFL'

		WHEN	b.type = 'new' 
				and b.typeperiod = 'LY'
				and a.date between '2025-02-01' and b.startdate		
				THEN 'Non LFL'

		-- RENOVATION

		WHEN	b.type = 'Reno' 
				and b.typeperiod = 'TY'
				and a.date between b.startdate and b.enddate		
				THEN 'Non LFL'

		WHEN	b.type = 'Reno' 
				and b.typeperiod = 'TY'
				and a.date between 
					DATEFROMPARTS(year(dateadd(YEAR,-1,b.startdate)),month(b.startdate),DAY(b.startdate))
					AND DATEFROMPARTS(year(dateadd(YEAR,-1,b.enddate)),month(b.enddate),DAY(b.enddate)) 
				THEN 'Non LFL'

		WHEN	b.type = 'Reno' 
				and b.typeperiod = 'LY'
				and a.date between 
					DATEFROMPARTS(year(dateadd(YEAR,1,b.startdate)),month(b.startdate),DAY(b.startdate))
					AND DATEFROMPARTS(year(dateadd(YEAR,1,b.enddate)),month(b.enddate),DAY(b.enddate)) 
				THEN 'Non LFL'

		WHEN	b.type = 'Reno' 
				and b.typeperiod = 'LY'
				and a.date between b.startdate and b.enddate
				THEN 'Non LFL'

		-- CLOSURES
		WHEN	b.type = 'Closure' 
				and b.typeperiod = 'LY'
				THEN 'Non LFL'

		WHEN	b.type = 'Closure' 
				and b.typeperiod = 'TY'
				and a.date between b.startdate and '2027-01-31'	
				THEN 'Non LFL'

		WHEN	b.type = 'Closure' 
				and b.typeperiod = 'TY'
				and a.date between DATEFROMPARTS(year(dateadd(YEAR,-1,b.startdate)),month(b.startdate),DAY(b.startdate))
					and '2026-01-31' -- last year
				THEN 'Non LFL'

		-- TEMPORARY STORE (POP UP) DUE TO RENOVATION OF MAIN STORE
		WHEN	b.type = 'tempstore' 
				THEN 'Non LFL'
	ELSE 'LFL'
	END 
FROM factsalesnew a
left join dimlfltotaldiv b
ON a.warehouseid = b.storecode
WHERE a.finyear in ('2026-27','2025-26')


