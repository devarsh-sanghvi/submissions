SELECT
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    LEN(first_name) DESC;


SELECT
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    1,
    2;

SELECT TOP 1
    product_name, 
    list_price
FROM
    production.products
ORDER BY 
    list_price DESC;


SELECT TOP 3 WITH TIES
    product_name, 
    list_price
FROM
    production.products
ORDER BY 
    list_price DESC;

SELECT TOP 1 PERCENT
    product_name, 
    list_price
FROM
    production.products
ORDER BY 
    list_price DESC;



SELECT
    distinct first_name,
    last_name
FROM
    sales.customers;

-- For distinct on like feature use CTE (single column)
with cte as (
select * , row_number() over (partition by last_name order by last_name) rn from sales.customers
)
select * from cte where rn = 1;
-- For distinct on based on multiple columns
with cte as (
	select * , 
	row_number() over (
		partition by first_name ,
		last_name order by first_name) rn 
	from sales.customers
)
select * from cte where rn = 1;

-- like with escape clause
CREATE TABLE sales.feedbacks (
   feedback_id INT IDENTITY(1, 1) PRIMARY KEY, 
    comment     VARCHAR(255) NOT NULL
);
INSERT INTO sales.feedbacks(comment)
VALUES('Can you give me 30% discount?'),
      ('May I get me 30USD off?'),
      ('Is this having 20% discount today?');

SELECT 
   feedback_id,
   comment
FROM 
   sales.feedbacks
WHERE 
   comment LIKE '%30$%%' ESCAPE '$';

-- complex aggregation function
SELECT
    order_id,
    SUM (
        quantity * list_price * (1 - discount)
    ) net_value
FROM
    sales.order_items
GROUP BY
    order_id;

-- example of subquery as a column
SELECT
    order_id,
    order_date,
    (
        SELECT
            MAX (list_price)
        FROM
            sales.order_items i
        WHERE
            i.order_id = o.order_id
    ) AS max_list_price
FROM
    sales.orders o
order by order_date desc;

--union
 select 1 union select 1 union select 1;

 select 1 union all select 1 union all select 1;

 -- explicit insertion on identity is not allowed by default
 SET IDENTITY_INSERT sales.feedbacks ON;

INSERT INTO sales.feedbacks(feedback_id,comment)
VALUES(4,'Can you give me 30% discount?');

SET IDENTITY_INSERT sales.feedbacks OFF;
