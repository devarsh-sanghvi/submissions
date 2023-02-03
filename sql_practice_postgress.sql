-- Q1
-- create database syntax;
-- 
-- Q2
-- create schema syntax;
-- 

set search_path to syntax, public; -- now freely use select without schema name making defualt schema as first search path is syntax
show search_path;
select current_schema();

drop table if exists all_tmp_refs cascade;
create table all_tmp_refs(id serial PRIMARY KEY, locality varchar NOT NULL);

-- Q3
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

-- Q4
drop table if exists film_data;
create table film_cast as select film_id,title,first_name,last_name from film_data;
select * from film_cast;
-- 

-- Q5
drop table if exists test1;
-- 

-- Q6
-- Temp tables are sesion specific tables which are not required to be stored but are used as intermediatory tables.
-- while Common table expression are deleted on execution of statement, temp tables can exists for whole session.
drop table if exists actor_fullname;
Create temp table actor_fullname as select first_name || ' ' || last_name fullname from film_cast;
select * from actor_fullname;
-- 

-- Q7
-- Delete is DML while Truncate is DDL
-- Delete is used to remove rows on which where condition is met. If condition not provided then delete all rows
-- Truncate will simply remove all rows
-- 

-- Q8
alter table if exists test rename to student;
-- 

alter table if exists student rename to test;

-- Q9
alter table test add column city varchar Not NULL;
-- 

-- Q10
alter table test alter column city set DATA TYPE text;
-- 

-- Q11
alter table test drop column pin;
select * from test; 
-- 

-- Q12
alter table test rename column city to location;
-- 

-- Q13
create role read_only;
grant select on all tables in schema syntax to read_only;
-- 

-- Q14
create role all_writes;
grant insert, update, delete on all tables in schema syntax to all_writes;
-- 

-- Q15
create role read_only_user login password 'reader123';
grant select on all tables in schema syntax to read_only_user;
-- 

-- Q16
create role read_write_user login password 'read_write123';
grant all on all tables in schema syntax to read_write_user;
-- 

-- Q17
CREATE role admin with createdb createrole;
-- 

-- Q18
create role expiry_june login password 'will expire soon' valid until '1 June 2023';
-- 

-- Q19
select distinct film_name from film_data;
-- 

-- Q20
select * from customer order by customer_id limit 100;
-- 

-- Q21
select * from inventory order by inventory_id limit 10 offset 50;
--

-- Q22
select distinct first_name || ' '|| last_name as name  from customer left join payment using (customer_id) where amount between 1.99 and 5.99;  
-- 

-- Q23
select title from film where title like 'A%';
-- 

-- Q24
select title from film where title like '%a';
-- 

-- Q25
select title from film where title like 'M%a';
-- 

-- Q26
select * from customer where exists (select 1 from payment where payment.customer_id = customer.customer_id and payment.amount >40);
-- 

-- Q27
select * from staff order by first_name;
-- 

create view customer_payment as select * from customer left join payment using(customer_id);

-- Q28
select customer_id,payment_id,first_name,last_name,payment_date from customer_payment; -- using customer_payment (view)
-- 

-- Q29
select film.title , actor.first_name || ' '|| actor.last_name as actor from film join film_actor using (film_id) join actor using(actor_id)
-- 

-- Q30
select actor.first_name || ' '|| actor.last_name as actor , film_actor.film_id  from  film_actor join actor using(actor_id)
-- 

-- Q31
select customer.first_name || ' ' || customer.last_name as customer_name,address.address, address.phone from customer join address using(address_id) ;
-- 

-- Q32
select customer_id,payment_id,first_name,last_name,payment_date from  customer full join payment using(customer_id);
-- 

-- Q33
select distinct address_id from customer;
-- 

-- Q34
select address_id from customer;
--

-- Q35
select first_name || ' ' || last_name as customer_name , sum(amount) as total_payment from  customer join payment using(customer_id) group by first_name || ' ' || last_name;
--

-- Q36
select distinct first_name || ' ' || last_name as customer_name  from  customer join payment using(customer_id) where amount > 80;
-- 

-- Q37
-- create temp table tmp_rent as table rental;
update rental set return_date = return_date+ interval '5 days'  where rental_date < '15 June 2005';
-- select * from rental where rental_date < '15 June 2005';
-- 

-- Q38
alter table customer drop constraint customer_address_id_fkey;
alter table customer add FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE CASCADE;
alter table payment drop constraint payment_customer_id_fkey;
alter table payment add FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE;
alter table rental drop constraint rental_customer_id_fkey;
alter table rental add FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE;
delete from customer where active = 0;
-- 

-- Q39
select special_features,count(special_features) from (select unnest(special_features) as special_features from film) as arr_data group by special_features;
-- 

-- Q40
select 'total_films' as metrices,count(*) from film;
-- 

-- Q41
select special_features, count(*) from film group by special_features;
-- 

-- Q42
select rating , sum(CASE when rating is NULL then 0 else 1 end) as film_count from film group by rating;
-- more restrictive and verbose 
select rating , sum(CASE when rating = 'NC-17' or rating ='G' or rating ='PG-13' or rating ='PG' or rating ='R' then 1 else 0 end) as film_count from film group by rating;
-- 

-- Q43
select id,product,price , case when discount is NULL then 1 else discount end as  discount from items;
-- 

-- Q44
select title , case when excerpt is null or excerpt = '' then RIGHT(body,6) else excerpt end from posts ;
-- 

-- Q45
select distinct category.name as genre, count(customer.customer_id) as customer_count from category join film_category using(category_id) join film using(film_id) join inventory using(film_id) join rental using(inventory_id) join customer using(customer_id) group by category.name order by customer_count;
-- highest genre reach 1147
-- lowest genre reach 811
-- 

-- Q46
select film_id , title , rental_date , case rental_rate when 0.99 then 3 when 2.99 then 4 when 4.99 then 5 else 6 end as rental_duration from  rental join inventory using(inventory_id) join film using(film_id);
-- 

-- Q47
select distinct customer.first_name || ' ' || customer.last_name as customer, email 
from customer join rental using(customer_id)
join inventory using(inventory_id)
join film using(film_id) where rental_rate = 9.99;
-- 

-- Q48
select distinct c1.first_name || ' ' || c1.last_name as customer 
from customer as c1 join payment as p1 using(customer_id)
where (c1.store_id = 1) and (p1.amount < 2.99) and (customer_id = ANY( select customer_id from payment group by customer_id having sum(amount) > 5));
-- 

-- Q49
select title ,replacement_cost from film where replacement_cost  = (select max(replacement_cost) from film);  
-- 

-- Q50
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

-- Q51
select dept_name , max(salary) from employee group by dept_name;
-- 

-- Q52
select * , max(salary) OVER (partition by dept_name) as max_salary from employee;
-- 

-- Q53
select * , row_number() over (partition by dept_name) from employee;
-- 

-- Q54
with cte as (
select * ,row_number() over (partition by dept_name order by emp_id) from employee
 )
select * from cte where row_number <3;
-- 

-- Q55
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

-- Q56
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

-- Q57
select * from film where Extract(month from last_update) = 5;
-- 

-- Q58
-- update payment set payment_date = payment_date + '5 month';
select * from payment where payment_date > current_date -((extract(isodow from current_date)::text||'days')::interval + '6 days'::interval);
-- 

-- Q59
select * from customer;
-- update customer set create_date = create_date + '3 months'::interval
select * from customer where extract(year from create_date) = extract(year from current_date)-1;
-- 

-- Q60
-- update rental set rental_date = rental_date - '17 days'::interval where extract(day from rental_date) <17;
with monthed_rental as (
	select * , extract (month from rental_date) as month from rental order by month
)
select store_id ,month,count(*) from monthed_rental join staff using(staff_id) group by grouping sets ((store_id,month)) order by store_id,month;
-- 

-- Q61
update
	film f
set
	title = case when title = 'Date speed' then 'Data speed' else title end
from 
	language l
where f.language_id = l.language_id ;
-- 

-- Q62
update film set description = substring(description,2) where description like 'A%';
-- select * from film;
-- 

-- Q63
update film set title = substring(title,1,length(title)-length('italian')+2) where title like '%italian';
-- update film set title = substring(title,1,length(title)-length('italian')+2) where title like '%speed';
-- 

-- Q64
select 
	first_name || ' ' || last_name as customer_name, email , sum(amount) as total_sales
from 
	customer join payment using (customer_id)
group by first_name || ' ' || last_name , email order by total_sales DESC limit 5;
-- 

-- Q65
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

-- Q66
select title from film where film_id !=ALL(select distinct film_id from inventory where store_id =2);
-- 

-- Q67
with actor_cnts as (
	select actor_id , count(film_id) as films_cnt
	from film_actor 
	group by actor_id)
select actor.first_name || ' '|| actor.last_name as actor_name, films_cnt from actor join actor_cnts using(actor_id) ;
-- 

-- Q68
select *
from customer
where customer_id in (
select customer_id from customer_payment where amount>9 group by customer_id having count(*) > 3) ; -- customer_payment_view
-- 

-- Q69
select distinct first_name,last_name , FIRST_VALUE(payment_date) over(partition by customer_id order by payment_date DESC) as latest_payment_date from customer_payment -- customer_payment_view
-- 

-- Q70
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

-- Q71
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

-- Q72
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

-- Q73
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

-- Q74
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

-- Q75

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