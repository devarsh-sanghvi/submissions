-- Working with json data
-- DECLARE @param <data type>
-- SET @param = <value>
--
-- IF (ISJSON(@param) > 0)  
-- BEGIN  
--     -- Do something with the valid JSON value of @param.  
-- END

-- ISJSON
SELECT ISJSON('true', VALUE)
SELECT ISJSON('test string', VALUE)
SELECT ISJSON('"test string"', VALUE)
SELECT ISJSON('"test string"', SCALAR)

-- JSON_OBJECT
SELECT JSON_OBJECT();
SELECT JSON_OBJECT('name':'value', 'type':1)
SELECT JSON_OBJECT('name':'value', 'type':NULL )
SELECT JSON_OBJECT('name':'value', 'type':NULL ABSENT ON NULL)
SELECT JSON_OBJECT('name':'value', 'type':JSON_ARRAY(1, 2))
SELECT JSON_OBJECT('name':'value', 'type':JSON_OBJECT('type_id':1, 'name':'a'))
go
DECLARE @id_key nvarchar(10) = 'id',@id_value nvarchar(64) = NEWID();
SELECT JSON_OBJECT('user_name':USER_NAME(), @id_key:@id_value, 'sid':(SELECT @@SPID))
go
SELECT s.session_id, JSON_OBJECT('security_id':s.security_id, 'login':s.login_name, 'status':s.status) as info
FROM sys.dm_exec_sessions AS s
WHERE s.is_user_process = 1;

-- JSON ARRAY
SELECT JSON_ARRAY();
SELECT JSON_ARRAY('a', 1, 'b', 2)
SELECT JSON_ARRAY('a', 1, 'b', NULL)
SELECT JSON_ARRAY('a', 1, NULL, 2 NULL ON NULL)
SELECT JSON_ARRAY('a', JSON_OBJECT('name':'value', 'type':1))
SELECT JSON_ARRAY('a', JSON_OBJECT('name':'value', 'type':1), JSON_ARRAY(1, null, 2 NULL ON NULL))
DECLARE @id_value nvarchar(64) = NEWID();
SELECT JSON_ARRAY(1, @id_value, (SELECT @@SPID));
go
SELECT s.session_id, JSON_ARRAY(s.host_name, s.program_name, s.client_interface_name)
FROM sys.dm_exec_sessions AS s
WHERE s.is_user_process = 1;


-- JSON_VALUE
DECLARE @jsonInfo NVARCHAR(MAX);

SET @jsonInfo=N'{  
     "info":{    
       "type":1,  
       "address":{    
         "town":"Bristol",  
         "county":"Avon",  
         "country":"England"  
       },  
       "tags":["Sport", "Water polo"]  
    },  
    "type":"Basic"  
 }';

SELECT
 JSON_VALUE(@jsonInfo,'$.info.address.town');
 go

 DECLARE @jsonInfo NVARCHAR(MAX)
DECLARE @town NVARCHAR(32)

SET @jsonInfo=N'{"info":{"address":[{"town":"Paris"},{"town":"London"}]}}';

SET @town=JSON_VALUE(@jsonInfo,'$.info.address[0].town'); -- Paris
SET @town=JSON_VALUE(@jsonInfo,'$.info.address[1].town'); -- London
go

-- for json clause output result as json
select top 3
	* 
from 
	test_sales 
for json path;


select top 3
	* 
from 
	test_sales 
for json path , root('sales');

select top 3
	* 
from 
	test_sales 
for json path,WITHOUT_ARRAY_WRAPPER;

go


select JSON_QUERY('"info"');
go

DECLARE @data NVARCHAR(4000)
SET @data=N'{  
    "Suspect": {    
       "Name": "Homer Simpson",
       "Hobbies": ["Eating", "Sleeping", "Base Jumping"]  
    }
 }'
 SELECT 
   JSON_VALUE(@data,'$.Suspect.Name') AS 'Name',
   JSON_QUERY(@data,'$.Suspect.Hobbies') AS 'Hobbies',
   JSON_VALUE(@data,'$.Suspect.Hobbies[2]') AS 'Last Hobby';
go

-- 17 Feb 2023
DECLARE @info NVARCHAR(100)='{"name":"John","skills":["C#","SQL"]}'

PRINT @info

-- Update name  

SET @info=JSON_MODIFY(@info,'$.name','Mike')

PRINT @info

-- Insert surname  

SET @info=JSON_MODIFY(@info,'$.surname','Smith')

PRINT @info

-- Set name NULL 

SET @info=JSON_MODIFY(@info,'strict $.name',NULL)

PRINT @info

-- Delete name  

SET @info=JSON_MODIFY(@info,'$.name',NULL)

PRINT @info

-- Add skill  

SET @info=JSON_MODIFY(@info,'append $.skills','Azure')

PRINT @info
go

DECLARE @info NVARCHAR(100)='{"name":"John","skills":["C#","SQL"]}'

PRINT @info

-- Multiple updates  

SET @info=JSON_MODIFY(
			JSON_MODIFY(
				JSON_MODIFY(@info,'$.name','Mike')
								,'$.surname','Smith')
									,'append $.skills','Azure')
PRINT @info
go

-- to rename a property, add same property value with new property name and remove old property
DECLARE @product NVARCHAR(100)='{"price":49.99}'

PRINT @product;

-- Rename property  

SET @product=
 JSON_MODIFY(
  JSON_MODIFY(@product,'$.Price',CAST(JSON_VALUE(@product,'$.price') AS NUMERIC(4,2))),
  '$.price',
  NULL
 );

PRINT @product;

-- increment
DECLARE @stats NVARCHAR(100)='{"click_count": 173}'

PRINT @stats

-- Increment value  

SET @stats=JSON_MODIFY(@stats,'$.click_count',
 CAST(JSON_VALUE(@stats,'$.click_count') AS INT)+1)

PRINT @stats

-- use json_query to prevent (") to escape by json_modify if working with updating json objects
DECLARE @info NVARCHAR(100)='{"name":"John","skills":["C#","SQL"]}'

PRINT @info

-- Update skills array  

SET @info=JSON_MODIFY(@info,'$.skills',JSON_QUERY('["C#","T-SQL","Azure"]'))

PRINT @info

-- UPDATE Employee
-- SET jsonCol=JSON_MODIFY(jsonCol,'$.info.address.town','London')
-- WHERE EmployeeID=17

-- Json to table
DECLARE @json NVARCHAR(MAX);
SET @json = N'[
  {"id": 2, "info": {"name": "John", "surname": "Smith"}, "age": 25},
  {"id": 5, "info": {"name": "Jane", "surname": "Smith"}, "dob": "2005-11-04T12:00:00"}
]';

SELECT *
FROM OPENJSON(@json)
  WITH (
    id INT 'strict $.id',
    firstName NVARCHAR(50) '$.info.name',
    lastName NVARCHAR(50) '$.info.surname',
    age INT,
    dateOfBirth DATETIME2 '$.dob'
  );

  go

DECLARE @json NVARCHAR(4000) = N'{  
      "path": {  
            "to":{  
                 "sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]  
                 }  
              }  
 }';

SELECT *
FROM OPENJSON(@json,'$.path.to."sub-object"');

go

-- error: unable to get sql:identity
DECLARE @array VARCHAR(MAX);
SET @array = '[{"month":"Jan", "temp":10},{"month":"Feb", "temp":12},{"month":"Mar", "temp":15},
               {"month":"Apr", "temp":17},{"month":"May", "temp":23},{"month":"Jun", "temp":27}
              ]';

SELECT * FROM OPENJSON(@array)
        WITH (  month VARCHAR(3),
                temp int,
                month_id tinyint '$.sql:identity()') as months

go

DECLARE @json NVARCHAR(MAX);
SET @json = N'[  
  {"id": 2, "info": {"name": "John", "surname": "Smith"}, "age": 25},
  {"id": 5, "info": {"name": "Jane", "surname": "Smith", "skills": ["SQL", "C#", "Azure"]}, "dob": "2005-11-04T12:00:00"}  
]';

SELECT id, firstName, lastName, age, dateOfBirth, skill  
FROM OPENJSON(@json)  
  WITH (
    id INT 'strict $.id',
    firstName NVARCHAR(50) '$.info.name',
    lastName NVARCHAR(50) '$.info.surname',  
    age INT,
    dateOfBirth DATETIME2 '$.dob',
    skills NVARCHAR(MAX) '$.info.skills' AS JSON
  )
OUTER APPLY OPENJSON(skills)
  WITH (skill NVARCHAR(8) '$');
go

-- Import JSON data into SQL Server tables
DECLARE @jsonVariable NVARCHAR(MAX);

SET @jsonVariable = N'[
  {
    "Order": {  
      "Number":"SO43659",  
      "Date":"2011-05-31T00:00:00"  
    },  
    "AccountNumber":"AW29825",  
    "Item": {  
      "Price":2024.9940,  
      "Quantity":1  
    }  
  },  
  {  
    "Order": {  
      "Number":"SO43661",  
      "Date":"2011-06-01T00:00:00"  
    },  
    "AccountNumber":"AW73565",  
    "Item": {  
      "Price":2024.9940,  
      "Quantity":3  
    }  
  }
]';

-- INSERT INTO <sampleTable>  
SELECT SalesOrderJsonData.*
FROM OPENJSON (@jsonVariable, N'$')
  WITH (
    Number VARCHAR(200) N'$.Order.Number',
    Date DATETIME N'$.Order.Date',
    Customer VARCHAR(200) N'$.AccountNumber',
    Quantity INT N'$.Item.Quantity'
  ) AS SalesOrderJsonData;

go

-- selecting table specific fields
select ois.*, ord.* from sales.order_items ois inner join sales.orders ord on ois.order_id = ord.order_id;

go
-- examples 
select json_query('{"name":"Lavanya","sub-names":["amar","akbar","anthony"]}','$."sub-names"');
select json_value('{"name":"Lavanya","sub-names":["amar","akbar","anthony"]}','$."sub-names"[0]');
select * from openjson('{"name":"Lavanya","sub-names":["amar","akbar","anthony"]}','$') 
	with (name varchar(10), "sub-names" nvarchar(max) as json);
go

-- table as array
with array_table as (
select ROW_NUMBER() over ( order by value) as id , value from string_split('a,b,c,d,e',',')
)
select * from array_table;
go
-- Dynamic SQL

DECLARE @statement VARCHAR(2000);
SET @statement = 'SELECT id, customer_name
FROM customer
WHERE status = 1';
EXECUTE (@statement);

EXEC sp_executesql
N'SELECT *
    FROM 
        production.products 
    WHERE 
        list_price> @listPrice AND
        category_id = @categoryId
    ORDER BY
        list_price DESC', 
N'@listPrice DECIMAL(10,2),
@categoryId INT'
,@listPrice = 100
,@categoryId = 1;

go

CREATE OR ALTER PROCEDURE usp_query (
    @table NVARCHAR(128)
)
AS
BEGIN

    DECLARE @sql NVARCHAR(MAX);
    -- construct SQL
    SET @sql = N'SELECT * FROM ' + @table;
    -- execute the SQL
    EXEC sp_executesql @sql;
    
END;
go
EXEC usp_query 'production.brands';
go

-- recursive cte
with  fib(f1,f2,i) as 
(
select 0,1,1
UNION ALL
select f2,(f1+f2),i+1 from fib
where i <10
)
select f1 from fib;

-- Performance Tunning
set statistics time on;
with  fib(f1,f2,i) as 
(
select 0,1,1
UNION ALL
select f2,(f1+f2),i+1 from fib
where i <25
)
select f1 from fib;
set statistics time off;

set statistics IO on;
with  fib(f1,f2,i) as 
(
select 0,1,1
UNION ALL
select f2,(f1+f2),i+1 from fib
where i <25
)
select f1 from fib;
set statistics IO off;

set showplan_all on;
go
with  fib(f1,f2,i) as 
(
select 0,1,1
UNION ALL
select f2,(f1+f2),i+1 from fib
where i <25
)
select f1 from fib;
go
set showplan_all off;
go

set statistics profile on;
with  fib(f1,f2,i) as 
(
select 0,1,1
UNION ALL
select f2,(f1+f2),i+1 from fib
where i <25
)
select f1 from fib;
set statistics profile off;

set showplan_xml on;
go
with  fib(f1,f2,i) as 
(
select 0,1,1
UNION ALL
select f2,(f1+f2),i+1 from fib
where i <25
)
select f1 from fib;
go
set showplan_xml off;
go

set STATISTICS XML on;
go
with  fib(f1,f2,i) as 
(
select 0,1,1
UNION ALL
select f2,(f1+f2),i+1 from fib
where i <25
)
select f1 from fib;
go
set STATISTICS XML off;
go
-- date series
select dateadd(month,1,'2001/10/02')

-- indexes
CREATE TABLE production.parts(
    part_id   INT NOT NULL, 
    part_name VARCHAR(100)
);

INSERT INTO 
    production.parts(part_id, part_name)
VALUES
    (1,'Frame'),
    (2,'Head Tube'),
    (3,'Handlebar Grip'),
    (4,'Shock Absorber'),
    (5,'Fork');
go

SELECT 
    part_id, 
    part_name
FROM 
    production.parts
WHERE 
    part_id = 5;
go

CREATE CLUSTERED INDEX ix_parts_id
ON production.parts (part_id);  
go

SELECT 
    part_id, 
    part_name
FROM 
    production.parts
WHERE 
    part_id = 5;
go

-- nonclustered index on one column
CREATE INDEX ix_customers_city
ON sales.customers(city);
go
SELECT 
    customer_id, 
    city
FROM 
    sales.customers
WHERE 
    city = 'Atwater';

-- non clustered index on multiple columns
CREATE INDEX ix_customers_name 
ON sales.customers(last_name, first_name);

SELECT 
    customer_id, 
    first_name, 
    last_name
FROM 
    sales.customers
WHERE 
    last_name = 'Berg' AND 
    first_name = 'Monika';

-- index seek is performed as column last_name is set at high priority 
SELECT 
    customer_id, 
    first_name, 
    last_name
FROM 
    sales.customers
WHERE 
    last_name = 'Albert';


-- index scan is performed as column first_name is set at low priority 
SELECT 
    customer_id, 
    first_name, 
    last_name
FROM 
    sales.customers
WHERE 
	first_name = 'Adam';

-- rename index
EXEC sp_rename 
        @objname = N'sales.customers.ix_customers_city',
        @newname = N'ix_cust_city' ,
        @objtype = N'INDEX';

-- start with 0 example
select SUBSTRING('abcsdff',0,4) , SUBSTRING('abcsdff',1,4);

-- index on computed columns
-- Similar to index on expression but a computed column must be defined which holds the result of expression and then
-- create index on computed column. has some rules as requriements.

-- Script for unused index
SELECT
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates
FROM
    sys.dm_db_index_usage_stats
    INNER JOIN sys.objects ON dm_db_index_usage_stats.OBJECT_ID = objects.OBJECT_ID
    INNER JOIN sys.indexes ON indexes.index_id = dm_db_index_usage_stats.index_id AND dm_db_index_usage_stats.OBJECT_ID = indexes.OBJECT_ID
WHERE
    indexes.is_primary_key = 0 --This line excludes primary key constarint
    AND
    indexes. is_unique = 0 --This line excludes unique key constarint
    AND 
    dm_db_index_usage_stats.user_updates <> 0 -- This line excludes indexes SQL Server hasn’t done any work with
    AND
    dm_db_index_usage_stats. user_lookups = 0
    AND
    dm_db_index_usage_stats.user_seeks = 0
    AND
    dm_db_index_usage_stats.user_scans = 0
ORDER BY
    dm_db_index_usage_stats.user_updates DESC

-- Missing Indexes
SELECT db.[name] AS [DatabaseName]
    ,id.[object_id] AS [ObjectID]
	,OBJECT_NAME(id.[object_id], db.[database_id]) AS [ObjectName]
    ,id.[statement] AS [FullyQualifiedObjectName]
    ,id.[equality_columns] AS [EqualityColumns]
    ,id.[inequality_columns] AS [InEqualityColumns]
    ,id.[included_columns] AS [IncludedColumns]
    ,gs.[unique_compiles] AS [UniqueCompiles]
    ,gs.[user_seeks] AS [UserSeeks]
    ,gs.[user_scans] AS [UserScans]
    ,gs.[last_user_seek] AS [LastUserSeekTime]
    ,gs.[last_user_scan] AS [LastUserScanTime]
    ,gs.[avg_total_user_cost] AS [AvgTotalUserCost]  -- Average cost of the user queries that could be reduced by the index in the group.
    ,gs.[avg_user_impact] AS [AvgUserImpact]  -- The value means that the query cost would on average drop by this percentage if this missing index group was implemented.
    ,gs.[system_seeks] AS [SystemSeeks]
    ,gs.[system_scans] AS [SystemScans]
    ,gs.[last_system_seek] AS [LastSystemSeekTime]
    ,gs.[last_system_scan] AS [LastSystemScanTime]
    ,gs.[avg_total_system_cost] AS [AvgTotalSystemCost]
    ,gs.[avg_system_impact] AS [AvgSystemImpact]  -- Average percentage benefit that system queries could experience if this missing index group was implemented.
    ,gs.[user_seeks] * gs.[avg_total_user_cost] * (gs.[avg_user_impact] * 0.01) AS [IndexAdvantage]
    ,'CREATE INDEX [IX_' + OBJECT_NAME(id.[object_id], db.[database_id]) + '_' + REPLACE(REPLACE(REPLACE(ISNULL(id.[equality_columns], ''), ', ', '_'), '[', ''), ']', '') + CASE
        WHEN id.[equality_columns] IS NOT NULL
            AND id.[inequality_columns] IS NOT NULL
            THEN '_'
        ELSE ''
        END + REPLACE(REPLACE(REPLACE(ISNULL(id.[inequality_columns], ''), ', ', '_'), '[', ''), ']', '') + '_' + LEFT(CAST(NEWID() AS [nvarchar](64)), 5) + ']' + ' ON ' + id.[statement] + ' (' + ISNULL(id.[equality_columns], '') + CASE
        WHEN id.[equality_columns] IS NOT NULL
            AND id.[inequality_columns] IS NOT NULL
            THEN ','
        ELSE ''
        END + ISNULL(id.[inequality_columns], '') + ')' + ISNULL(' INCLUDE (' + id.[included_columns] + ')', '') AS [ProposedIndex]
    ,CAST(CURRENT_TIMESTAMP AS [smalldatetime]) AS [CollectionDate]
FROM [sys].[dm_db_missing_index_group_stats] gs WITH (NOLOCK)
INNER JOIN [sys].[dm_db_missing_index_groups] ig WITH (NOLOCK) ON gs.[group_handle] = ig.[index_group_handle]
INNER JOIN [sys].[dm_db_missing_index_details] id WITH (NOLOCK) ON ig.[index_handle] = id.[index_handle]
INNER JOIN [sys].[databases] db WITH (NOLOCK) ON db.[database_id] = id.[database_id]
WHERE  db.[database_id] = DB_ID()
--AND OBJECT_NAME(id.[object_id], db.[database_id]) = 'YourTableName'
ORDER BY ObjectName, [IndexAdvantage] DESC
OPTION (RECOMPILE);



-- Performance Tunning
Set statistics io on;
select * from [sales].[customers] 
where state = 'NY';

select customer_id , first_name , last_name from [sales].[customers] 
where state = 'NY';

drop index ix_customer_state on [sales].[customers]
create nonclustered index ix_customer_state on sales.[customers](state) include (first_name , last_name);