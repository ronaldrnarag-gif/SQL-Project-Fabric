
/*
Create Static table in Data Warehouse named : factsalestransactioncountnew
utilizes factsalestransactioncount table ingested from Gold layer
rn 20260720
*/

select * from sys.tables order by name
select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'factsalestransactioncountnew'
select top 10 * from factsalestransactioncountnew
select top 10 * from factsalestransactioncount
select top 10 * from dimproduct b
select top 10 * from dimstore c
select top 10 * from dimdate d
select top 10 * from dimexchangeratedwh e
select top 10 * from dimlfltotaldiv f


drop table factsalestransactioncountnew
truncate table factsalestransactioncountnew


---- 1- create static table
create table factsalestransactioncountnew (
		finyear				varchar(10),	
		month				varchar(10),
		date				date,
		finyear_wk			varchar(10),
		week				int,
		country				varchar(10),
		company				varchar(10),
		locationkey			int,
		warehouseid			varchar(10),
		storename			varchar(50),
		storeshortname		varchar(20),
		dept2PH				varchar(10),
		department			varchar(50),
		subdepartment		varchar(max),
		class				varchar(max),
		subclass			varchar(max),
		brand				varchar(max),
		customeraccount		varchar(50),
		transactionid		varchar(max),
		productkey			int,
		productid			varchar(max),
		description			varchar(max),
		qty					decimal(38,6),
		sales				decimal(38,6),
		cost				decimal(38,6),
		vat					decimal(38,6),
		discount			decimal(38,6),
		claimamount			decimal(38,6),
		margin_approx		decimal(38,6),
		sales_usd			decimal(38,6),
		cost_usd			decimal(38,6),
		vat_usd				decimal(38,6),
		discount_usd		decimal(38,6),
		claimamount_usd		decimal(38,6),
		marginapprox_usd	decimal(38,6),
		vendorkey			int,
		supplier			varchar(50),
		suppliername		varchar(max),
		itemgroupname		varchar(50),
		level				varchar(10),
		isltm				varchar(10),
		isdropshipping		varchar(10),
		islfl				varchar(10),
		activesellingprice	decimal(38,6),
		basesalesprice		decimal(38,6),
		ltpromotionid		varchar(50),
		storetype			varchar(10),
		salestype			varchar(50),
		currency			varchar(10),
		intercompanyid		varchar(50),
		isintercoorder		varchar(50),
		countryoforigin		varchar(50),
		hscodeid			varchar(50),
		claimsref			varchar(50),
		discamount			decimal(38,6),
		custdiscamount		decimal(38,6),
		discgroupid			varchar(10),
		discofferid			varchar(10),
		periodicdiscgroup	varchar(10),
		periodicdiscamount	decimal(38,6),
		employeekey			int,
		staffid				varchar(50),
		staff				varchar(50),
		integraionlogid		varchar(50),
		offerid				varchar(50),
		ispricedisctable	varchar(50),
		transferredtomof	varchar(50),
		ltuserid			varchar(50),
		ltexceptiontype		varchar(50),
		ltamountclaimed		decimal(38,6)
	)


---- 2- fill in the table

insert into factsalestransactioncountnew
select top 10
	d.fiscalperiod, 
	d.monthshortname, 
	a.date,
	d.fiscalweekboundfiscalyear,
	d.fiscalweek,
	case when upper(a.companyid) = 'KAT' 
		then 'OMN' 
		else upper(a.companyid) 
		end,
	upper(a.companyid),
	a.locationkey,
	c.warehouseid,
	upper(c.warehousename),
	c.ltshortname,
	case when b.hir1 in ('MUSIC','ELECTRONICS','GAMING') 
		then 'TECH' 
		else 'LIFESTYLE' 
		end, 
	b.hir1,
	b.hir2,
	b.hir3,
	b.hir4,
	b.ltbrand,
	a.custaccount,
	a.transactionid,
	a.productkey,
	b.productid,
	trim(b.productname),
	a.qty,
	a.netsales, 
	a.cost,
	a.tax,
	a.discount,
	a.ltclaimamount,
	a.netsales-a.cost+a.ltclaimamount, --marginapprox
	a.netsales * e.exchangeratenew, -- salesusd
	a.cost * e.exchangeratenew, -- costusd
	a.tax * e.exchangeratenew, -- vatusd
	a.discount * e.exchangeratenew, --discountusd
	a.ltclaimamount * e.exchangeratenew, --claimamountusd
	(a.netsales-a.cost+a.ltclaimamount) * e.exchangeratenew, --marginapproxusd
	a.vendorkey,
	a.primaryvendorid,
	trim(b.vendorname),
	b.vendorgroup,
	-- level
	CASE 
		WHEN c.warehouseid LIKE '%90'
			  OR c.warehouseid LIKE '%99'
			  OR c.warehouseid LIKE '491%'
			  OR b.vendorgroup IN ('M', 'F', 'INTERCO')
			THEN 'L-3'
		WHEN UPPER(b.hir1) <> 'SERVICES'
			 AND b.vendorgroup IN ('C', 'N', 'I', 'H')  
			THEN 'L-1'
		WHEN UPPER(b.hir1) = 'SERVICES'
			 AND b.hir4 IN ('NAJM CARD', 'MAGAZINES')
			THEN 'L-1'
		WHEN UPPER(b.hir1) <> 'SERVICES'
			 AND b.vendorgroup IN ('D', 'S')       
			THEN 'L-2'
		WHEN b.vendorgroup = 'T'                  
			THEN 'L-2'
		WHEN UPPER(b.hir1) = 'SERVICES'
			 AND b.hir4 NOT IN ('NAJM CARD', 'MAGAZINES')
		THEN 'L-2'
		ELSE 'L-1'
		END AS level,
	-- isltm
	CASE WHEN a.date >= DATEADD(YEAR,-1,getdate()-1) 
		THEN 'Y' 
		ELSE '' 
		END AS isltm, 
	b.apntdropshipping,

	-- islfl
	CASE when d.fiscalperiod not in ('2026-27','2025-26')
		then ''
			-- OPENINGS
			when f.type = 'new' 
				 and f.typeperiod = 'TY'
			then 'Non LFL'

			when f.type = 'new' 
				 and f.typeperiod = 'LY'
				 and a.date between '2026-02-01' 
					 and datefromparts(
							year(dateadd(year,1,f.startdate)),
							month(f.startdate),
							day(f.startdate)
					 )
			then 'Non LFL'

			when f.type = 'new' 
				 and f.typeperiod = 'LY'
				 and a.date between '2025-02-01' and f.startdate
			then 'Non LFL'

		-- RENOVATION
		when f.type = 'Reno' 
			 and f.typeperiod = 'TY'
			 and a.date between f.startdate and f.enddate
		then 'Non LFL'

		when f.type = 'Reno' 
			 and f.typeperiod = 'TY'
			 and a.date between 
				 datefromparts(year(dateadd(year,-1,f.startdate)),month(f.startdate),day(f.startdate))
				 and datefromparts(year(dateadd(year,-1,f.enddate)),month(f.enddate),day(f.enddate))
		then 'Non LFL'

		when f.type = 'Reno' 
			 and f.typeperiod = 'LY'
			 and a.date between 
				 datefromparts(year(dateadd(year,1,f.startdate)),month(f.startdate),day(f.startdate))
				 and datefromparts(year(dateadd(year,1,f.enddate)),month(f.enddate),day(f.enddate))
		then 'Non LFL'

		when f.type = 'Reno' 
			 and f.typeperiod = 'LY'
			 and a.date between f.startdate and f.enddate
		then 'Non LFL'

		-- CLOSURES
		when f.type = 'Closure' 
			 and f.typeperiod = 'LY'
		then 'Non LFL'

		when f.type = 'Closure' 
			 and f.typeperiod = 'TY'
			 and a.date between f.startdate and '2027-01-31'
		then 'Non LFL'

		when f.type = 'Closure' 
			 and f.typeperiod = 'TY'
			 and a.date between 
				 datefromparts(year(dateadd(year,-1,f.startdate)),month(f.startdate),day(f.startdate))
				 and '2026-01-31'
		then 'Non LFL'

		-- TEMP STORE
		when f.type = 'tempstore'
		then 'Non LFL'

		-- DEFAULT
		else 'LFL'

    end as islfl,    
	a.ltsellingprice,
	a.ltbasesalesprice,
	a.ltpromotionid,
	c.storetype,
	a.salestype,
	a.currency,
	a.intercompanyid,
	a.intercompanyorder,
	a.apntcountryoforigin,
	a.apnthscodeid,
	a.ltclaimsref,
	a.ltdiscountamount,
	a.custdiscamount,
	a.discgroupid,
	a.discofferid,
	a.periodicdiscgroup,
	a.periodicdiscamount,
	a.employeekey,
	a.staffid,
	a.staff,
	a.ltmofintegraionlogid,
	a.ltofferid,
	a.ltpricedisctable,
	a.lttransferredtomof,
	a.ltuserid,
	a.ltexceptiontype,
	a.ltamountclaimed
from factsalestransactioncount a
left join dimproduct b
	on upper(a.companyid)=upper(b.companyid) and a.productkey = b.productkey 
left join dimstore c
	on a.locationkey=c.locationkey
left join dimdate d
	on a.date=d.date
left join dimexchangeratedwh e
	on upper(a.companyid)=e.companyid
left join dimlfltotaldiv f
	on c.warehouseid = trim(f.storecode)
where a.date = '2026-02-01'

select top 10 * from factsalestransactioncountnew
