

/*					
Purpose     :   FIFO Stock Bucketing and Provisioning.
                This file is needed to fulfill Weekly FIFO Report Requested by Karima and Team.
Logic       :   Creates list of all sku's in vw_stockageing 
                plus added column for the Categorization needed to run the provision calculations correctly.
Created     :   ronaldn/20261101			
*/					
					
	
-- Data Extraction				
drop table if exists #DataExtract					
select a.companyid, a.productid, a.hir1 department,	a.hir2 subdepartment,	a.hir3 class,	a.hir4 subclass, a.ltbrand brand, a.productlifecyclestateid popgradeid, 						
    case					
        when a.hir1 not in ('SERVICES','ELECTRONICS','GAMING','MUSIC','BOOKS') then '1 - LIFESTYLE Categories'					
        when a.hir1 = 'MUSIC' and a.hir2 in ('VINYL','CDS','CASSETTES','DVD/BLU-RAY') 					
            then '2 A- MUSIC (Main Categories)'					
        when a.hir1 in ('MUSIC','BOOKS') and a.hir2 not in ('VINYL','CDS','CASSETTES','DVD/BLU-RAY') 					
            then '2 B- MUSIC (Other Music+Books)'					
        when a.hir1 in ('ELECTRONICS','GAMING')
            and b.Column1 is not null
            then '3 - TECH (HARDWARE Categories)'
        when a.hir1 in ('ELECTRONICS','GAMING')
            and b.Column1 is null
            then '4 - TECH (Other Categories)'		
        else a.hir1
        end as 'Category'					
INTO #DataExtract					
FROM dimproduct a					
LEFT JOIN temp_tbl_tech_hardware_exclusions b
    ON a.hir4  = b.Column1				
where a.vendorgroup in ('I','N')					
	and a.hir1 <> 'services'	
    and a.companyid not in ('jor','egp','kwt')			
group by a.companyid, a.productid, a.hir1 ,	a.hir2 ,	a.hir3 ,	a.hir4 , a.ltbrand , a.productlifecyclestateid , 						
    case					
        when a.hir1 not in ('SERVICES','ELECTRONICS','GAMING','MUSIC','BOOKS') then '1 - LIFESTYLE Categories'					
        when a.hir1 = 'MUSIC' and a.hir2 in ('VINYL','CDS','CASSETTES','DVD/BLU-RAY') 					
            then '2 A- MUSIC (Main Categories)'					
        when a.hir1 in ('MUSIC','BOOKS') and a.hir2 not in ('VINYL','CDS','CASSETTES','DVD/BLU-RAY') 					
            then '2 B- MUSIC (Other Music+Books)'					
        when a.hir1 in ('ELECTRONICS','GAMING')
            and b.Column1 is not null
            then '3 - TECH (HARDWARE Categories)'
        when a.hir1 in ('ELECTRONICS','GAMING')
            and b.Column1 is null
            then '4 - TECH (Other Categories)'		
        else a.hir1
        end 
				
;

Select * from #DataExtract					
					
go	


