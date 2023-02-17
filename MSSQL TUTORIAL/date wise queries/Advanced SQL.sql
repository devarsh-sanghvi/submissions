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

DECLARE @json NVARCHAR(MAX);
SET @json = N'[
  {"id": 2, "info": {"name": "John", "surname": "Smith"}, "age": 25},
  {"id": 5, "info": {"name": "Jane", "surname": "Smith"}, "dob": "2005-11-04T12:00:00"}
]';
go

SELECT *
FROM OPENJSON(@json)
  WITH (
    id INT 'strict $.id',
    firstName NVARCHAR(50) '$.info.name',
    lastName NVARCHAR(50) '$.info.surname',
    age INT,
    dateOfBirth DATETIME2 '$.dob'
  );