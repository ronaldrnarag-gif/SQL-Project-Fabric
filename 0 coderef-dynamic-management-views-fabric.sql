
/*
	Fabric Dynamic Management Views (DMV's)
--	monitor connection, session and request status
--	gives no of active queries and which queries are running for extended time.
*/

select * from sys.dm_exec_connections

select * from sys.dm_exec_sessions where nt_user_name = 'ronald.narag'

select * from sys.dm_exec_requests

-- Other Fabric Scripts

select * from sys.tables order by name

select * from sys.objects order by type_desc

select * from INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME

USE AzadeaWarehouse

