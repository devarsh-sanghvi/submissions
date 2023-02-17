SELECT
    definition,
    uses_ansi_nulls,
    uses_quoted_identifier,
    is_schema_bound
FROM
    sys.sql_modules
WHERE
    object_id
    = object_id(
            'num_5'
        );

EXEC sp_helptext 'num_5';

SELECT 
    OBJECT_DEFINITION(
        OBJECT_ID(
            'num_5'
        )
    ) view_info;
GO

SET STATISTICS IO ON
GO

SELECT 
    * 
FROM
    production.products
ORDER BY
    product_name;
GO

SET STATISTICS IO Off
go
Create PROCEDURE uspFindProducts(
    @min_list_price AS DECIMAL = 0
    ,@max_list_price AS DECIMAL = 999999
    ,@name AS VARCHAR(max)
)
AS
BEGIN
    SELECT
        product_name,
        list_price
    FROM 
        production.products
    WHERE
        list_price >= @min_list_price AND
        list_price <= @max_list_price AND
        product_name LIKE '%' + @name + '%'
    ORDER BY
        list_price;
END;
GO

EXECUTE uspFindProducts 
    @min_list_price = 900, 
    @name = 'Trek';
go

select 'abc'+'bcs';
go

declare @count int = @@ROWCOUNT ;
select @@ROWCOUNT,@count;
select @count = @@ROWCOUNT


DECLARE 
    @ErrorMessage  NVARCHAR(4000), 
    @ErrorSeverity INT, 
    @ErrorState    INT;

BEGIN TRY
    RAISERROR('Error occurred in the TRY block.', 17, 1);
END TRY
BEGIN CATCH
    SELECT 
        @ErrorMessage = ERROR_MESSAGE(), 
        @ErrorSeverity = ERROR_SEVERITY(), 
        @ErrorState = ERROR_STATE();

    -- return the error inside the CATCH block
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
go

THROW 50005, 'An error occurred', 1;

-- custom error message 
EXEC sys.sp_addmessage 
    @msgnum = 50010, 
    @severity = 16, 
    @msgtext =
    N'The order number %s cannot be deleted because it does not exist.', 
    @lang = 'us_english';   
GO

DECLARE @MessageText NVARCHAR(2048);
SET @MessageText =  FORMATMESSAGE(50010, N'1001');
THROW 50010, @MessageText, 1;
go

CREATE OR ALTER PROC usp_query
(
    @schema NVARCHAR(128), 
    @table  NVARCHAR(128)
)
AS
    BEGIN
        DECLARE 
            @sql NVARCHAR(MAX);
        -- construct SQL
        SET @sql = N'SELECT * FROM ' 
            + QUOTENAME(@schema) 
            + '.' 
            + QUOTENAME(@table);
        -- execute the SQL
        EXEC sp_executesql @sql;
    END;
go

EXEC usp_query 'production','brands';


select * from production.brands;
go

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

-- insert table into variable
DECLARE @product_table TABLE (
    product_name VARCHAR(MAX) NOT NULL,
    brand_id INT NOT NULL,
    list_price DEC(11,2) NOT NULL
);
INSERT INTO @product_table
SELECT
    product_name,
    brand_id,
    list_price
FROM
    production.products
WHERE
    category_id = 1;

SELECT
    *
FROM
    @product_table;
go

CREATE OR ALTER FUNCTION udfSplit(
    @string VARCHAR(MAX), 
    @delimiter VARCHAR(50) = ' ')
RETURNS @parts TABLE
(    
idx INT IDENTITY PRIMARY KEY,
val VARCHAR(MAX)   
)
AS
BEGIN

DECLARE @index INT = -1;

WHILE (LEN(@string) > 0) 
BEGIN 
    SET @index = CHARINDEX(@delimiter , @string)  ;
    
    IF (@index = 0) AND (LEN(@string) > 0)  
    BEGIN  
        INSERT INTO @parts 
        VALUES (@string);
        BREAK  
    END 

    IF (@index > 1)  
    BEGIN  
        INSERT INTO @parts 
        VALUES (LEFT(@string, @index - 1));
        
        SET @string = RIGHT(@string, (LEN(@string) - @index));  
    END 
    ELSE
    SET @string = RIGHT(@string, (LEN(@string) - @index)); 
    END
RETURN
END
GO

DECLARE @document varchar(64);
SELECT @document = 'Reflectors are vital safety' +
' components of your bicycle.';
SELECT CHARINDEX('are', @document);
GO

create table udfContacts(first_name VARCHAR(50),
        last_name VARCHAR(50),
        email VARCHAR(255),
        phone VARCHAR(25));
go

CREATE FUNCTION udfContacts()
    RETURNS @contacts TABLE (
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        email VARCHAR(255),
        phone VARCHAR(25),
        contact_type VARCHAR(20)
    )
AS
BEGIN
    INSERT INTO @contacts
    SELECT 
        first_name, 
        last_name, 
        email, 
        phone,
        'Staff'
    FROM
        sales.staffs;

    INSERT INTO @contacts
    SELECT 
        first_name, 
        last_name, 
        email, 
        phone,
        'Customer'
    FROM
        sales.customers;
    RETURN;
END;
go
SELECT 
    * 
FROM
    udfContacts();
go