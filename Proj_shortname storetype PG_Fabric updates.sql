
USE AzadeaWarehouse
USE Lakehouse_Curated

shortname					= dimstore
storetype					= dimstore
productlifecyclestateid		= dimproduct

---------------------


-- 1- fact_inventory_with_provision_aging

	select top 10 * from fact_inventory_with_provision_aging

	
	alter table fact_inventory_with_provision_aging
	drop column popgradeno

	alter table fact_inventory_with_provision_aging
	add popgradeno varchar(50)

	update a
	set 
		a.storeshortname	= b.shortname,
		a.storetype			= b.storetype,
		a.popgradeno		= c.productlifecyclestateid
	from fact_inventory_with_provision_aging a
	left join dimstore b
		on a.warehouseid=b.warehouseid
	left join dimproduct c
		on upper(a.company)=upper(c.companyid)
		and a.productkey=c.productkey


-- 2- factsalesnew
	
	select top 10 * from factsalesnew

	
	alter table factsalesnew
	drop column storeshortname

	alter table factsalesnew
	add storeshortname varchar(20)

	update a
	set 
		a.storeshortname	= b.shortname,
		a.storetype			= b.storetype
	from factsalesnew a
	left join dimstore b
		on a.warehouseid=b.warehouseid
	left join dimproduct c
		on upper(a.company)=upper(c.companyid)
		and a.productkey=c.productkey


-- 3- factsalestransactioncountnew

	select top 10 * from factsalestransactioncountnew


	update a
	set 
		a.ltshortname		= b.shortname,
		a.storetype			= b.storetype
	from factsalestransactioncountnew a
	left join dimstore b
		on a.warehouseid=b.warehouseid
	left join dimproduct c
		on upper(a.companyid)=upper(c.companyid)
		and a.productkey=c.productkey




-- 3- factsalesotherls
-- add storename and storetype



		select top 10 * 
		from factsalesotherls a
	
	alter table factsalesotherls
	drop column storetype

	alter table factsalesotherls
	add storetype varchar(20)

	alter table factsalesotherls
	drop column storename

	alter table factsalesotherls
	add storename varchar(50)

		update a
		set a.storename=b.storename,
			a.storetype=b.storetype
		from factsalesotherls a
		left join dimstoretotaldiv b
			on LTRIM(a.warehouseid)=LTRIM(b.bu)



