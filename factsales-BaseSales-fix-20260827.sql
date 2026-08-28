


use Lakehouse_Curated
use Lakehouse_Presentation

select top 10 * from inventdim




select * from dimproduct where productkey = '33822173' -- productid = '112475'

select top 10 * from factsales where companyid = 'uae'

select top 10 * from factinventory


inventlocationid -- store
dataareaid -- country

configid, inventcolorid, 

select * from sys.tables order by name


-- custinvoicetrans
select year(invoicedate) year, month(invoicedate) month, count(*) rowc
from custinvoicetrans 
where ltbasesalesprice is null or ltbasesalesprice = 0
group by year(invoicedate) , month(invoicedate) 
order by 1, 2

-- retailtransactionsalestrans
select year(businessdate) year, month(businessdate) month, count(*) rowc
from retailtransactionsalestrans
where ltbasesalesprice is null or ltbasesalesprice = 0
group by year(businessdate) , month(businessdate) 
order by 1, 2

----------


-- custinvoicetrans
select *
from custinvoicetrans 
where ltbasesalesprice is null or ltbasesalesprice = 0
and year(invoicedate) = '2026' 
and month(invoicedate) = '8'
and dataareaid = 'qat'


-- retailtransactionsalestrans
select *
from retailtransactionsalestrans
where ltbasesalesprice is null or ltbasesalesprice = 0
and year(businessdate) = '2026' 
and month(businessdate) = '8'
and dataareaid = 'qat'

select top 10 * from factinventory