

select distinct dayname, isweekend, isweekend2 from dimdate order by 1

--------

ALTER TABLE dimdate
ADD isweekend2 int

update a
set isweekend2 = 
	case when dayname in ('Friday','Saturday','Sunday')
	then 1 else 0
	end 
from dimdate a







