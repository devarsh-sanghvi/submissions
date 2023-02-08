-- DATABASE DEVELOPMENT PART 1
-- Quering Data
Select actor_id , 
first_name||' '||last_name as full_name,
last_update last_updated_at 
from actor;

-- Filtering Data
select * from actor 
where actor_id > 5 and first_name like '%tt%' 
LIMIT 5 OFFSET 2; 

select * from actor 
where actor_id in (3,4,5,6,7) 
and (last_update between '2013-05-26 12:00:00.00' and '2013-05-26 15:00:00.00' )
OFFSET 0 FETCH FIRST 3 ROW ONLY;

select * from items 
where discount is NULL;

-- JOINS
select * 
from film as f 
inner join inventory as i 
on f.film_id = i.film_id;
-- list films which are not listed in our inventory.
select * 
from film as f left 
join inventory as i 
on f.film_id = i.film_id 
where i.inventory_id is null;
-- list of customers who have not rented any dvd yet.
select * 
from rental as r 
right join customer as c 
using(customer_id) 
where r.rental_id is null ;
-- first 10 dvds which are available for rental (not reserved) via 
select * 
from reservation 
full outer join inventory 
using(inventory_id) 
where customer_id is null 
order by inventory_id 
limit 10;
-- list all movie title with actors
select title , first_name || ' '||last_name as actor_name 
from actor 
inner join film_actor 
using(actor_id) 
inner join film 
using(film_id);
-- generating false data using self_join
select 
c1.customer_id,c2.store_id,c2.first_name,c2.last_name,c1.email,c2.address_id,c1.activebool,c2.create_date,c1.last_update,c2.active 
from customer c1 
inner join customer c2 
on c1.customer_id = c2.address_id;
-- all possible combinations of 1,2,3
select * 
from generate_series(1,3) as s1 
cross join generate_series(1,3);

-- Grouping
Select customer_id , count(*) 
from payment 
group by customer_id ;

Select customer_id , sum(amount) as total_payment 
from payment 
group by customer_id 
having count(*) > 25;

-- SET operations
-- customer_ids frequently buying premium dvds.
select distinct customer_id 
from payment 
where amount > 10
INTERSECT 
select customer_id 
from payment 
group by customer_id 
having count(*) > 30;

-- customer buying premium dvd less frequently  
select distinct customer_id 
from payment 
where amount > 10
EXCEPT
select customer_id 
from payment 
group by customer_id 
having count(*) > 20;

Select customer_id,'purchases less frequent' status,count(*) 
from payment 
group by customer_id 
having count(*) < 15
UNION
Select customer_id,'purchases more frequent' status,count(*) 
from payment 
group by customer_id 
having count(*) > 35;

-- Groping Sets
-- Category wise customer spending
select payment.customer_id,category.name, sum(amount) from payment inner join rental using(rental_id) inner join inventory using(inventory_id) inner join film_category using(film_id) inner join category using(category_id)
group by 
grouping sets ((payment.customer_id,category.name)) 
order by customer_id
-- Spending based on: (customer_id) , (category_name) and (customer_id,category_name) and all_spendings
select payment.customer_id,category.name, sum(amount) from payment inner join rental using(rental_id) inner join inventory using(inventory_id) inner join film_category using(film_id) inner join category using(category_id)
group by 
cube (payment.customer_id,category.name)
order by customer_id nulls first,name nulls first;
-- Spending based on: (customer_id) , (customer_id,category_name) and all_spendings
select payment.customer_id,category.name, sum(amount) from payment inner join rental using(rental_id) inner join inventory using(inventory_id) inner join film_category using(film_id) inner join category using(category_id)
group by 
rollup(payment.customer_id,category.name)
order by customer_id nulls first,name nulls first;

-- Subquery
-- film whose length greater than avg(length) of all films
select * 
from film 
where length > (select avg(length) 
				from film);
-- first 50 film with odd film_id
select * 
from film 
where film_id = ANY(select * 
					from generate_series(1,100,2)				   ) 
order by film_id;
-- highest film_id
select * 
from film 
where film_id >=ALL(select film_id 
					from film) 
order by film_id;
-- films whose id > 10 times length (film duration)
select * 
from film f1 
where exists (select 1 
			  from film f2 
			  where f2.film_id > length*10 
			  and f1.film_id = f2.film_id) 
order by film_id;

-- Common Table Expressions
with ranked_table as (
	select customer_id , sum(amount),row_number() over () 
	from payment 
	group by customer_id 
	order by row_number
)
select * 
from ranked_table 
where row_number < sum;
-- [Example from postgres tutorials for Recursive cte]
WITH RECURSIVE subordinates AS (
	SELECT
		employee_id,
		manager_id,
		full_name
	FROM
		employees
	WHERE
		employee_id = 2
	UNION
		SELECT
			e.employee_id,
			e.manager_id,
			e.full_name
		FROM
			employees e
		INNER JOIN subordinates s ON s.employee_id = e.manager_id
) SELECT
	*
FROM
	subordinates;
-- 

-- Modifying data
select * from category;
insert into category (name,last_update) 
values ('Anime',now());

insert into category (name,last_update) 
values 
('Anime',now()),
('Documentory',now()),
('Tutorials',now());

update category 
set name = 'Wild-life' 
where category_id = 18;

-- -- update join
update items i1
set price = i1.price*(100+coalesce(i2.discount,0))
from items i2
where i1.price = i2.price;

delete from category where category_id = 20;

-- Upsert
insert into category values (18,'test',now())
on conflict on constraint category_pkey do nothing;

insert into category(category_id,name,last_update) 
values (20,'test2',now())
on conflict (category_id) 
do update 
set name = excluded.name, last_update = now();


-- Transactions

create table accounts(
	id serial PRIMARY KEY,
	fname varchar(25) not null,
	lname varchar(25) not null,
	bal int not null);
	
insert into accounts(fname,lname,bal) values
('a','b',100),('c','b',100);

insert into accounts 
(select * from accounts) 
on conflict (id) do nothing;

select * from accounts;
-- successful commit
begin ;
update accounts 
set bal = bal + 10 where id=1;

update accounts 
set bal = bal - 10 where id=2;

commit;
select * from accounts;
-- successful rollback
begin ;
update accounts 
set bal = bal + 10 where id=1;

update accounts 
set bal = bal - 10 where id=2;
rollback;
select * from accounts;

-- IMPORT / EXPORT DATA [example from postgres tutorial]
-- import 
COPY persons(first_name, last_name, dob, email)
FROM 'C:\sampledb\persons.csv'
DELIMITER ','
CSV HEADER;
-- export
COPY persons 
TO 'C:\tmp\persons_db.csv' 
DELIMITER ',' 
CSV HEADER;

-- Managing Tables
-- CREATE EXTENSION hstore;
-- cyclic sequence
create sequence  if not exists division_id_seq as int 
increment by 1 
minvalue 0 
maxvalue 9 
cycle;
-- reference table
drop table if exists all_tmp_refs cascade;

create table all_tmp_refs(id serial PRIMARY KEY, locality varchar NOT NULL);
-- table covering major datatypes
drop table if exists test;

create table if not exists test (
	id serial PRIMARY KEY,
	_id1 int generated always as identity (increment by 2 start 2), -- even number sequence
	_id2 int generated by default as identity, -- default identity
	_uuid uuid default uuid_generate_v1(), -- uuid
	first_name varchar NOT NULL,
	last_name varchar,
	division char,
	div_id int not null default nextval('division_id_seq') , --custom sequence
	school varchar NOT NULL,
	percentage float NOT NULL,
	status varchar CONSTRAINT pass_or_fail check (status = 'pass' or status = 'fail') NOT NULL ,
	pin int references all_tmp_refs(id) ON Delete SET NULL,
	created_date date default CURRENT_DATE,
	updated_date date NOT NULL,
	int_arr int [] default null,
	str_arr varchar [] default null,
	_json json default null,
	_hstore hstore default null,
	created_at timestamp default now()
);
-- new column with fk
alter table test add column col_new int 
references all_tmp_refs(id) 
on delete cascade;
-- drop col
alter table test
drop column col_new;
-- rename col
alter table test 
rename div_id 
to division_id;
-- atler table to add check
alter table test 
add check(length(division) > 0);
-- change datatype of col
alter table test 
alter column division_id 
type char 
using division_id::char;
-- truncate
truncate table test 
restart identity cascade;
-- temp table
select * 
into temp table tmp_test 
from test ;
-- create table as query
create table t2 as (select * from test);

-- copy tables
create table t3 as table t2;

create table t3 as table t2 
with no data;
-- skipping user defined data types

-- [Delete duplicates from postgres tutorial]
DELETE  FROM
    basket a
        USING basket b
WHERE
    a.id > b.id
    AND a.fruit = b.fruit;
-- 
-- Operators
-- CASE
select * , case 
when s%2=0 
	then 'EVEN' 
else 
	'ODD' 
end case
from generate_series(1,10) as s; 

-- COALESCE
select coalesce(discount,0) from items;

-- NULLIF
with factors_of_2_and_3 as (
	select generate_series(1,5) as one ,generate_series(1,5) two
)
select * from factors_of_2_and_3 where nullif(one,two) is null ;

-- CAST
select cast(now() as date),Extract (month from now()::date) as month;

-- DATABASE DEVELOPMENT PART 2

-- Variables & constants

-- nested block with variables
do 
$string_label$
<<first_block>>
declare
var_1 int = 1;
var_2 varchar;
var_3 actor.actor_id%type;
pi constant float := 3.14;
begin 
	raise notice 'Constant defined pi = %',pi;
	select actor_id into var_3 from actor limit 1;
	raise notice 'first actor id: %',var_3;
	
	<<second_block>> 
	declare
	var_3 actor%rowtype;
	begin
		select * into var_3 from actor offset 5 limit 1;
		raise notice 'first actor id: % first_name: % (scope second_block)',var_3.actor_id,var_3.first_name;
		raise notice 'first actor id: % (scope first_block)',first_block.var_3;
	end;
	<<loop_block>>
	declare
	var_2 record;
	begin
		for var_2 in select actor_id ,first_name , last_name
						from actor 
						limit 10
		loop
			raise notice 'Actor no: % full_name: %', var_2.actor_id , var_2.first_name||' '||var_2.last_name;
		end loop;
	end;
end first_block;
$string_label$
-- 

-- Reporting messages and errors
do $$ 
begin 
  raise info 'information message %', now() ;
  raise log 'log message %', now();
  raise debug 'debug message %', now();
  raise warning 'warning message %', now();
  raise notice 'notice message %', now();
end $$;
-- exception handling with multiple raise options
do $$
declare
search_actor_id int = 10000;
rec record ;
begin
select 1  into rec from actor where actor_id = search_actor_id;
if not found
	then
		raise exception 
			using message= 'searching for Actor_id: ' || search_actor_id,
			hint = 'Try inserting record before trying again';
end if;
end;
$$;

-- assert
do $$
declare
search_actor_id int = 10000;
rec record ;
begin
select 1 into rec from actor where actor_id = search_actor_id;
-- if not found
-- 	then
-- 		raise exception 
-- 			using message= 'searching for Actor_id: ' || search_actor_id,
-- 			hint = 'Try inserting record before trying again';
-- end if;		
select count(*)  into rec from actor where actor_id = search_actor_id;
if not found
	then
		raise exception 
			using message= 'searching for Actor_id: ' || search_actor_id,
			hint = 'Try inserting record before trying again';
else
	assert rec.count  > 0, '"if not found" unable to detect but I checked, and found that there are no records in table';
end if;
end;
$$;

-- Control structures
-- nested if
do $$
declare
rec record;
begin

	select count(*) into rec from actor where actor_id > 10000;
	raise notice 'count: %',rec;
	if not found then
		raise exception 'Rec not found in actor';
	else
		if not rec.count::int::bool
			then raise 'Rec is null';
		elsif rec.count > 5 
			then raise notice 'More than 5 records are found' ;
		end if;
	end if;
end;
$$
-- case
select rating , sum(
		CASE 
		when rating = 'NC-17' or rating ='G' or rating ='PG-13' or rating ='PG' or rating ='R' 
			then 1 
		else 0 
		end) as film_count 
from film 
group by rating;

select rating , sum(
		CASE rating
		when 'NC-17'
			then 1
		when 'G'
			then 1 
		when 'PG-13'
			then 1 
		when 'PG' 
			then 1
		when 'R' 
			then 1 
		else 0 
		end) as film_count 
from film 
group by rating;

-- loop
do $$

declare
var int = 1;
begin
raise notice 'squares of first 10 whole numbers';
<<loop_label>>
loop 
	raise notice 'square of % is %',var , var*var;
	exit when var = 10;
	var = var+1;
end loop;
end;
$$

-- while
do $$

declare
var int = 1;
begin
raise notice 'squares of first 10 whole numbers';
<<loop_label>>
while var <= 10 loop 
	raise notice 'square of % is %',var , var*var;
	var = var+1;
end loop;
end;
$$
-- for
do $$

begin
raise notice 'squares of first 10 whole numbers';
<<loop_label>>
for var in 1..10 loop 
	raise notice 'square of % is %',var , var*var;
end loop;
end;
$$

-- cotinue and exit
do
$$
declare
   counter int = 0;
begin
  
  loop
     counter = counter + 1;
	 exit when counter > 10;
	 continue when mod(counter,2) = 0;
	 raise notice '%', counter;
  end loop;
end;
$$

-- 
create or replace function concated_titles_of_year(arg_of_year int)
returns text
language 'plpgsql'
as $$
declare
movie_fetcher cursor(of_year int) for 
	select 
		title , release_year 
	from 
		film
	where release_year = of_year;
film_recd record;
titles text = '';
begin
	raise notice 'year %',arg_of_year;
	open movie_fetcher(arg_of_year);
	loop
		fetch movie_fetcher into film_recd;
		exit when not found;
		if film_recd.title like '%ful%' then 
         titles := titles || ',' || film_recd.title || ':' || film_recd.release_year;
      end if;
   end loop;
   close movie_fetcher;
   return titles;
end;
$$;

-- function with inout n out
create or replace function switch(inout a int  ,inout b int ,out sum int)
language 'plpgsql'
as $$

begin
sum = a+b;
raise notice 'before switch a:% b:%',a,b;
select b, a into a,b;
raise notice 'after switch a:% b:%',a,b;
end;
$$;

select * from switch(1,5);

-- return table 
create or replace function get_film (
  p_pattern varchar
) 
	returns table (
		film_title varchar,
		film_release_year int
	) 
	language plpgsql
as $$
begin
	return  query
		select 
			'From first query'::varchar ,
			2023;
			
	return query 
		select
			title,
			release_year::integer
		from
			film
		where
			title ilike p_pattern;
	
end;$$;

select * from get_film('%d%');

-- return next & func over loading
create or replace function get_film (
	p_pattern varchar,
	p_year int
) 
returns table (
	film_title varchar,
	film_release_year int
) 
language plpgsql
as $$
declare 
    var_r record;
begin
	for var_r in(
            select title, release_year 
            from film 
	     where title ilike p_pattern and 
		    release_year = p_year
        ) loop  film_title := upper(var_r.title) ; 
		film_release_year := var_r.release_year;
           return next;
	end loop;
end; $$

select distinct * from get_film('%z%',2006);
--  exception
do 
$$
declare
var int;
begin
select actor_id into strict var from actor where actor_id = 10000;
exception
	when no_data_found then
		raise exception 'No data found';
	when others then
		raise;
end;
$$;

-- procedures use case of jackpot allocation
drop table if exists accounts;

create table accounts (
    id int generated by default as identity,
    name varchar(100) not null,
    balance dec(15,2) not null,
    primary key(id)
);

insert into accounts(name,balance)
values('Bob',10000);

insert into accounts(name,balance)
values('Alice',10000);
select * from accounts;
drop procedure if exists allocate_jackpot;
create or replace procedure allocate_jackpot(base_amt int)
language plpgsql
as 
$$
declare
	no_participants int;
	lucky_id int := ceil(random()*10);
	lottery_price int;
	lucky_id_old_bal int;
	lucky_id_new_bal int;
	rec record;
begin
	select count(id) into no_participants from accounts where balance >= base_amt; 
	raise notice 'no of participants %',no_participants;
	raise notice 'Lottery Price %', no_participants * base_amt;
	lottery_price = no_participants * base_amt;
-- 	raise notice 'Lotery price %',no_participants * base_amt * 0.8; (if comission taken by broker)
	select balance into strict lucky_id_old_bal from accounts where id = lucky_id and balance >= base_amt;
-- 	start transaction;
	for rec in select * from accounts
	loop
	case rec.id
	when lucky_id then update accounts set balance = balance - base_amt + lottery_price where id = lucky_id and balance >= base_amt;
	else
		update accounts set balance = balance - base_amt where id = rec.id and balance >= base_amt;
	end case;
	end loop;
-- 	commit;
	select balance into strict lucky_id_new_bal from accounts where id = lucky_id;
	raise notice 'Lucky id %, old balance %, new balance % ,must be %',lucky_id,lucky_id_old_bal,lucky_id_new_bal,lucky_id_old_bal - base_amt + lottery_price;
	exception
	when no_data_found then raise exception 'lucky id % not in accounts table, or balance of lucky_id is less than %, aborting jackpot allocation',lucky_id,base_amt;
	when others then raise;
end
$$;
select * from accounts;
call allocate_jackpot(2000);

-- cursors
create or replace function concated_titles_of_year(arg_of_year int)
returns text
language 'plpgsql'
as $$
declare
movie_fetcher cursor(of_year int) for 
	select 
		title , release_year 
	from 
		film
	where release_year = of_year;
film_recd record;
titles text = '';
begin
	raise notice 'year %',arg_of_year;
	open movie_fetcher(arg_of_year);
	loop
		fetch movie_fetcher into film_recd;
		exit when not found;
		if film_recd.title like '%ful%' then 
         titles := titles || ',' || film_recd.title || ':' || film_recd.release_year;
      end if;
   end loop;
   close movie_fetcher;
   return titles;
end;
$$;
select  concated_titles_of_year(2006);

-- triggers 
create or replace function audit_reservations()
returns trigger as
$$
declare
row1 record;
Begin
 select count(*) into row1 from inserted;
 raise notice 'No of rows inserted %', row1.id
end
$$
language PLPGSQL;

create trigger trigger_audit_reservations 
after insert 
on rental 
referencing new table as inserted 
for each statement 
execute procedure audit_reservations();
-- 
CREATE OR REPLACE FUNCTION audit_reservation_table()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $$
begin
raise notice 'Trigger';
	insert into reservation_audit values(left(TG_OP,1),now(),coalesce(new.customer_id,old.customer_id),coalesce(new.inventory_id,old.inventory_id),coalesce(new.reserve_date,old.reserve_date));
	return Null;
end;
$$;
CREATE TRIGGER audit_reservation_table
    AFTER INSERT OR DELETE OR UPDATE 
    ON reservation
    FOR EACH ROW
    EXECUTE FUNCTION audit_reservation_table();

-- Aggregate functions
-- top slaes based on amount
select * from payment where amount = (select max(amount) from payment);
-- above average sales
select * from payment where amount > (select avg(amount) from payment);
-- total sales
select count(*) as total_sales , sum(amount) as total_revenue from payment;
-- no of lowest amount sales
select count(*) from payment where amount = (select min(amount) from payment);

-- window functions
-- max
select * , max(salary) OVER (partition by dept_name) as max_salary from employee;
-- row_number
select * , row_number() over (partition by dept_name) from employee;
-- first_value , last_value
select 
	* ,
	First_VALUE(salary) over w1,
	last_VALUE(salary) over w1
from employee
Window w1 as (partition by dept_name)
;
--  lead , lag
with cte as 
	(select 
	 	* , 
	 	lag(salary,1) over w ,
	 	lead(salary,1) over w 
	 from employee
	 Window w as (partition by dept_name))
select * from cte;

-- Date functions
select current_timestamp;
-- difference from start of the day and current_timestamp
select age(current_timestamp);
-- explicit converion is required while passing one argument in age
select age('2001-10-02'::date);
-- subtract interval
select age(current_date,current_date - '1 day'::interval);
--  time
select current_time(2);
-- date
select current_date;

select 
	DATE_PART('day',now()) as day,
	DATE_PART('dow',now()) dow,
	DATE_PART('decade',now()) decade,
	DATE_PART('isodow',now()) isodow,
	DATE_PART('minute',now()) as minute,
	DATE_PART('timezone',now()) timezone;

select localtime , current_time;

-- Extract
select extract(MILLISECONDS from current_timestamp);
-- similar to date_part but also works for interval

SELECT
    date_trunc('month', rental_date)::date m,
    COUNT (rental_id)
FROM
    rental
GROUP BY
    m
ORDER BY
    m;

-- to_date
select to_date('20th Jan 2001','DDth Mon YYYY');
select to_date('20/1/2001','DD/MM/YY');

-- to_timestamp
SELECT 
    TO_TIMESTAMP('2017-02-31 30:8:00', 'YYYY-MM-DD HH24:MI:SS');
	
SELECT 
    TO_TIMESTAMP('2017     Aug','YYYY MON');

SELECT 
    TO_TIMESTAMP('2017     Aug','FXYYYY MON'); --error as FX will count each space as individual 

-- Important string functions
select ASCII('A');

select CHR(ASCII('B')) , CHR(67);

SELECT FORMAT('|%10s|', 'one');
SELECT FORMAT('|%-10s|', 'one');
SELECT 
    FORMAT('%1$s apple, %2$s orange, %1$s banana', 'small', 'big');

select left('ABC DEF',4);
select right('ABC DEF',4);

select Lpad('ABC',6,'0');
select TRIM('00123300','0') , trim('  ABCD  ');
select replace('I me us','I','U');
select split_part('02-10-2001','-',2) as  month;

-- Important Math Functions
select CEIL(2.56) , FLOOR(2.56) , 
MOD(10,3), DIV(10,3) ,POWER(2,10),
ROUND(3.245354,2),SQRT(9),RANDOM() ;

-- DATABASE DEVELOPMENT PART 3
create database demo_db 
with 
allow_connections False
owner test_user;

ALTER database demo_db 
with 
ALLOW_CONNECTIONS True
Connection LIMIT 10
IS_TEMPLATE True;

--  rename
ALTER database demo_db 
rename to test_db
--  use template db
CREATE DATABASE demo_db_v1 WITH TEMPLATE demo_db;
-- check existing connections
SELECT *
FROM pg_stat_activity
WHERE datname = 'demo_db';
-- terminate existing connections 
SELECT pg_terminate_backend (pid) FROM pg_stat_activity WHERE datname = 'demo_db';
-- DROP DATABASE
DROP DATABASE demo_db;
-- database size
SELECT pd.datname  , pg_size_pretty(pg_database_size(pd.datname)) from pg_database as pd;	

-- managin schema
-- create schema
create schema IF NOT EXISTS demo;

SELECT current_schema();
SHOW search_path;
-- set search_path with schema names in priority
SET search_path TO demo, public;
SET search_path TO public;
-- reset search_path
SET search_path TO default;

-- create role 
CREATE ROLE test 
LOGIN 
PASSWORD 'test123' 
connection limit 100;

-- grant usage to role
GRANT USAGE 
ON SCHEMA demo 
TO test;

GRANT CREATE 
ON SCHEMA demo 
TO test;

-- with authorization
CREATE SCHEMA IF NOT EXISTS demo2 
AUTHORIZATION test;

-- list schemas in namespaces
SELECT * 
FROM pg_catalog.pg_namespace
ORDER BY nspname;

-- schema with objects
CREATE SCHEMA test 
    CREATE TABLE deliveries(
        id SERIAL NOT NULL, 
        customer_id INT NOT NULL, 
        ship_date DATE NOT NULL
    )
    CREATE VIEW delivery_due_list AS 
        SELECT ID, ship_date 
        FROM deliveries 
        WHERE ship_date <= CURRENT_DATE;

-- Alter schema
ALTER SCHEMA demo 
RENAME TO scema_demo_db;

ALTER SCHEMA syntax 
OWNER TO test;

-- drop schema 
drop schema test;
drop schema test cascade;

create tablespace test location '/tmp/tablespace' -- permission denied
-- pg_dump  -U devarsh -W -F t -f /home/devarsh/Documents/pssql tutorials/demo_dump.tar devarsh
-- pg_dump  -U devarsh -W -F p -f "/home/devarsh/Documents/pssql tutorials/schema-text.sql" devarsh --schema-only
-- psql -U devarsh -d devarsh -f "/home/devarsh/Documents/pssql tutorials/schema-text.sql"
-- pg_restore --dbname=devarsh --section=dtemplate1  "/home/devarsh/Documents/pssql tutorials/schema-text.sql" #(section allows to use db as template)

--  managin roles
SELECT rolname FROM pg_roles;

create role test2 
login 
password 'test123';

--  grant privilages
Grant 
Select, Update 
on actor 
to test;

--  grant all
grant all 
on actor 
to test;

--  grant all privilages on all tables in a specific schema
GRANT ALL
ON ALL TABLES
IN SCHEMA "syntax"
TO test;

-- revoke
revoke all 
on
all tables 
in schema "syntax" 
from test;

-- role membership
grant test 
to test2;

revoke test 
from test2;

-- create role to inherit privilages
create role flexible_user 
login 
password 'will inherit all'
inherit;

--  Alter role
alter role flexible_user 
noinherit
nologin
connection limit -1
valid until '20 Jan 2025';

-- rename
alter role flexible_user 
rename to rigid_user;

-- transfer ownership of all objects to test , drop any remaining objects depending on test2 and drop test2
reassign owned by test2 
to test;

drop owned by test2;

drop role test2;

-- list user
select * from pg_catalog.pg_user;
SELECT version();

-- change password
alter role test password 'test';
alter user test password 'test123';

-- dump db/ dump_all
-- pg_dump -U postgres -W -F t dvdrental > c:\pgbackup\dvdrental.tar (optional --<specific-objects>) 
-- pg_dumpall -U postgres -W -F t dvdrental > c:\pgbackup\dvdrental.tar (optional --<specific-objects>)
-- -U : user/role
-- -W : to promt password
-- -F : output format (here t i.e. ".tar")
-- db_name : (here dvdrental)  
-- > output_path : (here write to c:\pgbackup\dvdrental.tar)  
-- specific-objects can be any of schema-only/roles-only/tablespaces-only

--restore using psql
-- psql -U username -d database_name -f objects.sql --set ON_ERROR_STOP=on

-- restore using pg_restore
-- pg_restore --dbname=dvdrental2 --create --verbose c:\pgbackup\dvdrental.tar
-- pg_restore --dbname=dvdrental_tmpl --section=pre-data  c:\pgbackup\dvdrental.tar (as a template only)

