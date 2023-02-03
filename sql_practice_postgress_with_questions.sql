-- Q1 CREATE DATABASE SYNTAX
-- create database syntax;
-- 
-- Q2 CREATE SCHEMA SYNTAX
-- create schema syntax;
-- 

set search_path to syntax, public; -- now freely use select without schema name making defualt schema as first search path is syntax
show search_path;
select current_schema();

drop table if exists all_tmp_refs cascade;
create table all_tmp_refs(id serial PRIMARY KEY, locality varchar NOT NULL);

-- Q3 create table name test and test1 (with column id,  first_name, last_name, school, percentage, status (pass or fail),pin, created_date, updated_date)
define constraints in it such as Primary Key, Foreign Key, Noit Null...
apart from this take default value for some column such as cretaed_date
drop table if exists test;
create table test (
	id serial PRIMARY KEY,
	first_name varchar NOT NULL,
	last_name varchar,
	school varchar NOT NULL,
	percentage float NOT NULL,
	status varchar CONSTRAINT pass_or_fail check (status = 'pass' or status = 'fail') NOT NULL ,
	pin int references all_tmp_refs(id) ON Delete SET NULL,
	created_date date default CURRENT_DATE,
	updated_date date NOT NULL
);
	
drop table if exists test1;
create table test1 (
	id serial PRIMARY KEY,
	first_name varchar NOT NULL,
	last_name varchar,
	school varchar NOT NULL,
	percentage float NOT NULL,
	status varchar ,
	pin varchar,
	created_date date default CURRENT_DATE,
	updated_date date
);
--

drop table if exists film_data;
create table film_data (
	film_id serial Primary Key,
	film_name varchar Not NULL,
	title varchar NOT NULL,
	first_name varchar not null,
	last_name varchar not null,
	stars int not NULL default 0,
	release_year int NOT NULL
);

-- Q4 Create film_cast table with film_id,title,first_name and last_name of the actor.. (create table from other table)
drop table if exists film_data;
create table film_cast as select film_id,title,first_name,last_name from film_data;
select * from film_cast;
-- 

-- Q5 drop table test1
drop table if exists test1;
-- 

-- Q6 what is temproray table ? what is the purpose of temp table ? create one temp table
-- Temp tables are sesion specific tables which are not required to be stored but are used as intermediatory tables.
-- while Common table expression are deleted on execution of statement, temp tables can exists for whole session.
drop table if exists actor_fullname;
Create temp table actor_fullname as select first_name || ' ' || last_name fullname from film_cast;
select * from actor_fullname;
-- 

-- Q7 difference between delete and truncate ?
-- Delete is DML while Truncate is DDL
-- Delete is used to remove rows on which where condition is met. If condition not provided then delete all rows
-- Truncate will simply remove all rows
-- 

-- Q8 rename test table to student table
alter table if exists test rename to student;
-- 

alter table if exists student rename to test;

-- Q9 add column in test table named city
alter table test add column city varchar Not NULL;
-- 

-- Q10 change data type of one of the column of test table
alter table test alter column city set DATA TYPE text;
-- 

-- Q11 drop column pin from test table
alter table test drop column pin;
select * from test; 
-- 

-- Q12 rename column city to location in test table
alter table test rename column city to location;
-- 

-- Q13 Create a Role with read only rights on the database.
create role read_only;
grant select on all tables in schema syntax to read_only;
-- 

-- Q14 Create a role with all the write permission on the database.
create role all_writes;
grant insert, update, delete on all tables in schema syntax to all_writes;
-- 

-- Q15 Create a database user who can only read the data from the database.
create role read_only_user login password 'reader123';
grant select on all tables in schema syntax to read_only_user;
-- 

-- Q16 Create a database user who can read as well as write data into database.
create role read_write_user login password 'read_write123';
grant all on all tables in schema syntax to read_write_user;
-- 

-- Q17 Create an admin role who is not superuser but can create database and  manage roles.
CREATE role admin with createdb createrole;
-- 

-- Q18 Create user whoes login credentials can last until 1st June 2023
create role expiry_june login password 'will expire soon' valid until '1 June 2023';
-- 

-- Q19 List all unique film’s name.
select distinct film_name from film_data;
-- 

-- Q20 List top 100 customers details.
select * from customer order by customer_id limit 100;
-- 

-- Q21 List top 10 inventory details starting from the 5th one.
select * from inventory order by inventory_id limit 10 offset 50;
--

-- Q22 find the customer's name who paid an amount between 1.99 and 5.99.
select distinct first_name || ' '|| last_name as name  from customer left join payment using (customer_id) where amount between 1.99 and 5.99;  
-- 

-- Q23 List film's name which is staring from the A.
select title from film where title like 'A%';
-- 

-- Q24 List film's name which is end with "a"
select title from film where title like '%a';
-- 

-- Q25 List film's name which is start with "M" and ends with "a"
select title from film where title like 'M%a';
-- 

-- Q26 List all customer details which payment amount is greater than 40. (USING EXISTs)
select * from customer where exists (select 1 from payment where payment.customer_id = customer.customer_id and payment.amount >40);
-- 

-- Q27 List Staff details order by first_name.
select * from staff order by first_name;
-- 

create view customer_payment as select * from customer left join payment using(customer_id);

-- Q28 List customer's payment details (customer_id,payment_id,first_name,last_name,payment_date)
select customer_id,payment_id,first_name,last_name,payment_date from customer_payment; -- using customer_payment (view)
-- 

-- Q29 Display title and it's actor name.
select film.title , actor.first_name || ' '|| actor.last_name as actor from film join film_actor using (film_id) join actor using(actor_id)
-- 

-- Q30 List all actor name and find corresponding film id
select actor.first_name || ' '|| actor.last_name as actor , film_actor.film_id  from  film_actor join actor using(actor_id)
-- 

-- Q31 List all addresses and find corresponding customer's name and phone.
select customer.first_name || ' ' || customer.last_name as customer_name,address.address, address.phone from customer join address using(address_id) ;
-- 

-- Q32 Find Customer's payment (include null values if not matched from both tables)(customer_id,payment_id,first_name,last_name,payment_date)
select customer_id,payment_id,first_name,last_name,payment_date from  customer full join payment using(customer_id);
-- 

-- Q33 List customer's address_id. (Not include duplicate id )
select distinct address_id from customer;
-- 

-- Q34 List customer's address_id. (Include duplicate id )
select address_id from customer;
--

-- Q35 List Individual Customers' Payment total.
select first_name || ' ' || last_name as customer_name , sum(amount) as total_payment from  customer join payment using(customer_id) group by first_name || ' ' || last_name;
--

-- Q36 List Customer whose payment is greater than 80.
select distinct first_name || ' ' || last_name as customer_name  from  customer join payment using(customer_id) where amount > 80;
-- 

-- Q37 Shop owners decided to give  5 extra days to keep  their dvds to all the rentees who rent the movie before June 15th 2005 make according changes in db
-- create temp table tmp_rent as table rental;
update rental set return_date = return_date+ interval '5 days'  where rental_date < '15 June 2005';
-- select * from rental where rental_date < '15 June 2005';
-- 

-- Q38 Remove the records of all the inactive customers from the Database
alter table customer drop constraint customer_address_id_fkey;
alter table customer add FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE CASCADE;
alter table payment drop constraint payment_customer_id_fkey;
alter table payment add FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE;
alter table rental drop constraint rental_customer_id_fkey;
alter table rental add FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE;
delete from customer where active = 0;
-- 

-- Q39 count the number of special_features category wise.... total no.of deleted scenes, Trailers etc....
select special_features,count(special_features) from (select unnest(special_features) as special_features from film) as arr_data group by special_features;
-- 

-- Q40 count the numbers of records in film table
select 'total_films' as metrices,count(*) from film;
-- 

-- Q41 count the no.of special fetures which have Trailers alone, Trailers and Deleted Scened both etc....
select special_features, count(*) from film group by special_features;
-- 

-- Q42 use CASE expression with the SUM function to calculate the number of films in each rating:
select rating , sum(CASE when rating is NULL then 0 else 1 end) as film_count from film group by rating;
-- more restrictive and verbose 
select rating , sum(CASE when rating = 'NC-17' or rating ='G' or rating ='PG-13' or rating ='PG' or rating ='R' then 1 else 0 end) as film_count from film group by rating;
-- 

-- Q43 Display the discount on each product, if there is no discount on product Return 0
select id,product,price , case when discount is NULL then 1 else discount end as  discount from items;
-- 

-- Q44 Return title and it's excerpt, if excerpt is empty or null display last 6 letters of respective body from posts table
select title , case when excerpt is null or excerpt = '' then RIGHT(body,6) else excerpt end from posts ;
-- 

-- Q45 Can we know how many distinct users have rented each genre? if yes, name a category with highest and lowest rented number  ..
select distinct category.name as genre, count(customer.customer_id) as customer_count from category join film_category using(category_id) join film using(film_id) join inventory using(film_id) join rental using(inventory_id) join customer using(customer_id) group by category.name order by customer_count;
-- highest genre reach 1147
-- lowest genre reach 811
-- 

-- Q46 Return film_id,title,rental_date and rental_duration
according to rental_rate need to define rental_duration 
such as 
rental rate  = 0.99 --> rental_duration = 3
rental rate  = 2.99 --> rental_duration = 4
rental rate  = 4.99 --> rental_duration = 5
otherwise  6
select film_id , title , rental_date , case rental_rate when 0.99 then 3 when 2.99 then 4 when 4.99 then 5 else 6 end as rental_duration from  rental join inventory using(inventory_id) join film using(film_id);
-- 

-- Q47 Find customers and their email that have rented movies at priced $9.99.
select distinct customer.first_name || ' ' || customer.last_name as customer, email 
from customer join rental using(customer_id)
join inventory using(inventory_id)
join film using(film_id) where rental_rate = 9.99;
-- 

-- Q48 Find customers in store #1 that spent less than $2.99 on individual rentals, but have spent a total higher than $5.
select distinct c1.first_name || ' ' || c1.last_name as customer 
from customer as c1 join payment as p1 using(customer_id)
where (c1.store_id = 1) and (p1.amount < 2.99) and (customer_id = ANY( select customer_id from payment group by customer_id having sum(amount) > 5));
-- 

-- Q49 Select the titles of the movies that have the highest replacement cost.
select title ,replacement_cost from film where replacement_cost  = (select max(replacement_cost) from film);  
-- 

-- Q50 list the cutomer who have rented maximum time movie and also display the count of that... (we can add limit here too---> list top 5 customer who rented maximum time)
select max(length) from film;
select c1.first_name || ' ' || c1.last_name as customer , length
from customer c1 join rental using(customer_id)
join inventory using(inventory_id)
join film using(film_id)
where film.length = (select max(length) from film);

-- limit to 5
select c1.first_name || ' ' || c1.last_name as customer , length
from customer c1 join rental using(customer_id)
join inventory using(inventory_id)
join film using(film_id)
where film.length = (select max(length) from film) limit 5;
-- 

-- Q51 Display the max salary for each department
select dept_name , max(salary) from employee group by dept_name;
-- 

-- Q52 Display all the details of employee and add one extra column name max_salary (which shows max_salary dept wise) 

/*
emp_id	 emp_name   dept_name	salary   max_salary
120	     "Monica"	"Admin"		5000	 5000
101		 "Mohan"	"Admin"		4000	 5000
116		 "Satya"	"Finance"	6500	 6500
118		 "Tejaswi"	"Finance"	5500	 6500

--> like this way if emp is from admin dept then , max salary of admin dept is 5000, then in the max salary column 5000 will be shown for dept admin
*/
select * , max(salary) OVER (partition by dept_name) as max_salary from employee;
-- 

-- Q53 Assign a number to the all the employee department wise  
such as if admin dept have 8 emp then no. goes from 1 to 8, then if finance have 3 then it goes to 1 to 3

emp_id   emp_name       dept_name   salary  no_of_emp_dept_wsie
120		"Monica"		"Admin"		5000	1
101		"Mohan"		    "Admin"		4000	2
113		"Gautham"		"Admin"		2000	3
108		"Maryam"		"Admin"		4000	4
113		"Gautham"		"Admin"		2000	5
120		"Monica"		"Admin"		5000	6
101		"Mohan"		    "Admin"		4000	7
108		"Maryam"	    "Admin"		4000	8
116		"Satya"	      	"Finance"	6500	1
118		"Tejaswi"		"Finance"	5500	2
104		"Dorvin"		"Finance"	6500	3
106		"Rajesh"		"Finance"	5000	4
104		"Dorvin"		"Finance"	6500	5
118		"Tejaswi"		"Finance"	5500	6
select * , row_number() over (partition by dept_name) from employee;
-- 

-- Q54 Fetch the first 2 employees from each department to join the company. (assume that emp_id assign in the order of joining)
with cte as (
select * ,row_number() over (partition by dept_name order by emp_id) from employee
 )
select * from cte where row_number <3;
-- 

-- Q55 Fetch the top 3 employees in each department earning the max salary.
with cte as (
select * ,
	row_number() over (partition by dept_name order by max_sal) 
from 
	(select * , 
	 	max(salary) over (partition by dept_name) as max_sal
	 from employee ) as MS 
where salary = max_sal )

select * from cte where row_number <4;
-- 

-- Q56 write a query to display if the salary of an employee is higher, lower or equal to the previous employee.
select emp_name , 
case 
when salary > prev_emp_sal 
	then 'Salary higher than prev emp' 
when salary = prev_emp_sal 
	then 'Salary is equal to prev emp' 
when salary < prev_emp_sal 
	then 'Salary is less than prev emp' 
else 'cannot compare'
end as salary_comparision from 
(select * , LAG(salary,1) over () as prev_emp_sal from employee) as ss;
-- 

-- Q57 Get all title names those are released on may DATE
select * from film where Extract(month from last_update) = 5;
-- 

-- Q58 get all Payments Related Details from Previous week
-- update payment set payment_date = payment_date + '5 month';
select * from payment where payment_date > current_date -((extract(isodow from current_date)::text||'days')::interval + '6 days'::interval);
-- 

-- Q59 Get all customer related Information from Previous Year
select * from customer;
-- update customer set create_date = create_date + '3 months'::interval
select * from customer where extract(year from create_date) = extract(year from current_date)-1;
-- 

-- Q60 What is the number of rentals per month for each store?
-- update rental set rental_date = rental_date - '17 days'::interval where extract(day from rental_date) <17;
with monthed_rental as (
	select * , extract (month from rental_date) as month from rental order by month
)
select store_id ,month,count(*) from monthed_rental join staff using(staff_id) group by grouping sets ((store_id,month)) order by store_id,month;
-- 

-- Q61 Replace Title 'Date speed' to 'Data speed' whose Language 'English'
update
	film f
set
	title = case when title = 'Date speed' then 'Data speed' else title end
from 
	language l
where f.language_id = l.language_id ;
-- 

-- Q62 Remove Starting Character "A" from Description Of film
update film set description = substring(description,2) where description like 'A%';
-- select * from film;
-- 

-- Q63 if end Of string is 'Italian'then Remove word from Description of Title
update film set title = substring(title,1,length(title)-length('italian')+2) where title like '%italian';
-- update film set title = substring(title,1,length(title)-length('italian')+2) where title like '%speed';
-- 

-- Q64 Who are the top 5 customers with email details per total sales
select 
	first_name || ' ' || last_name as customer_name, email , sum(amount) as total_sales
from 
	customer join payment using (customer_id)
group by first_name || ' ' || last_name , email order by total_sales DESC limit 5;
-- 

-- Q65 Display the movie titles of those movies offered in both stores at the same time.
with film_ids as (select 
	film_id
from
	(select 
		distinct film_id , store_id
	from
		inventory) as ss
group by film_id having count(store_id) = 2 order by film_id)

select title from film where film_id = ANY(select * from film_ids);
-- 

-- Q66 Display the movies offered for rent in store_id 1 and not offered in store_id 2.
select title from film where film_id !=ALL(select distinct film_id from inventory where store_id =2);
-- 

-- Q67 Show the number of movies each actor acted in
with actor_cnts as (
	select actor_id , count(film_id) as films_cnt
	from film_actor 
	group by actor_id)
select actor.first_name || ' '|| actor.last_name as actor_name, films_cnt from actor join actor_cnts using(actor_id) ;
-- 

-- Q68 Find all customers with at least three payments whose amount is greater than 9 dollars
select *
from customer
where customer_id in (
select customer_id from customer_payment where amount>9 group by customer_id having count(*) > 3) ; -- customer_payment_view
-- 

-- Q69 find out the lastest payment date of each customer
select distinct first_name,last_name , FIRST_VALUE(payment_date) over(partition by customer_id order by payment_date DESC) as latest_payment_date from customer_payment -- customer_payment_view
-- 

-- Q70 Create a trigger that will delete a customer’s reservation record once the customer’s rents the DVD
create or replace function audit_reservations()
returns trigger as
$$
declare
row1 record;
Begin
 select count(*) into row1 from inserted limit 1;
 raise notice row1.id
end
$$
language PLPGSQL;
create trigger trigger_audit_reservations after insert on rental referencing new table as inserted for each statement execute procedure audit_reservations();
insert into rental values (100000,'2023-05-25 05:09:04',2638,413,'2023-06-01 23:12:04',1,current_date) ;

-- Q71 Create a trigger that will help me keep track of all operations performed on the reservation table. I want to record whether an insert, delete or update occurred on the reservation table and store that log in reservation_audit table.
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
-- 

-- Q72 Create trigger to prevent a customer for reserving more than 3 DVD’s.
CREATE OR REPLACE FUNCTION check_reserve_limit()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $$
declare
owned_dvd int;
begin
 select 
 	count(*) into owned_dvd  
 from 
 	reservation 
 where
 	customer_id = new.customer_id;
 if found
 	then 
		if owned_dvd >= 3
			then raise Exception 'Cannot Rent dvds more than 3';
		end if;
 end if;
return new;
end;
$$;

CREATE TRIGGER tg_check_reserve_limit
    BEFORE INSERT
    ON reservation
    FOR EACH ROW
    EXECUTE FUNCTION check_reserve_limit();
-- 

-- Q73 create a function which takes year as a argument and return the concatenated result of title which contain 'ful' in it and release year like this (title:release_year) --> use cursor in function
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
-- 

-- Q74 Find top 10 shortest movies using for loop
do
 $$
declare
rec record;
begin
for rec in select title , row_number() over(order by length) from film limit 10
loop 
	raise notice 'Title: %, Rank: %',rec.title, rec.row_number;
end loop;
end;
$$;
-- 

-- Q75 Write a function using for loop to derive value of 6th field in fibonacci series (fibonacci starts like this --> 1,1,.....)

create or replace function get_nth_fibo(nth int)
returns int
language 'plpgsql'
as 
$$
declare
i int;
a int = 1;
b int = 1;
tmp int;
begin
if i = 1 or i =2
then return 1;
end if;

for i in 3 .. nth
loop
	tmp =b;
	b = a+b;
	a = tmp;
-- 	raise notice '%th value is %',i,b;
end loop;
return b;
end;
$$
select get_nth_fibo(6);
-- 