-- iphone analysis requested by Amol

select *
from (
	select e.fiscalperiod, year(a.date) year, month(a.date) month, a.date, upper(a.companyid) companyid, a.locationkey, a.productkey, c.warehouseid, b.productid,b.productname,a.apntprimaryvendorid_it, b.vendorname, ltitemgroupid_it ,b.vendorgroup vendorgroupdimprod, 
		sum(a.qtypurchased) qtypurchased, sum(a.costpurchased * d.exchangeratenew) cost_usd
	from factpurchase a
	left join dimproduct b
		on upper(a.companyid)=upper(b.companyid)
		and a.productkey=b.productkey
	left join dimstore c
		on a.locationkey=c.locationkey
	left join dimexchangeratedwh d
		on upper(a.companyid)=upper(d.companyid)
	left join dimdate e
		on a.date=e.date
	where month(a.date) in ('9','10','11','12')
		and a.date >= '2021-02-01'
		and a.purchasetype = 'Purchase Order' 
		and a.ltsubclass = 'IPHONE'
	group by  e.fiscalperiod, year(a.date) , month(a.date) , a.date, upper(a.companyid) ,  a.locationkey, a.productkey, c.warehouseid, b.productid,b.productname,a.apntprimaryvendorid_it, b.vendorname, ltitemgroupid_it ,b.vendorgroup 
	) t
