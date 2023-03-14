/* --------------------
   Case Study 2
   --------------------*/
-- Data Cleanup of cutomer_orders ,runner_orders
update 
	pizza_runner.customer_orders 
set 
	exclusions = null
where 
	exclusions = 'null' or exclusions = '';
	
update 
	pizza_runner.customer_orders 
set 
	extras = null
where 
	extras = 'null' or extras = '';

update 
	pizza_runner.runner_orders 
set 
	pickup_time = null
where 
	pickup_time = 'null';
	
update 
	pizza_runner.runner_orders 
set 
	distance = null
where 
	distance = 'null';
	
update 
	pizza_runner.runner_orders 
set 
	duration = null
where 
	duration = 'null';

update 
	pizza_runner.runner_orders 
set 
	cancellation = null
where 
	cancellation = 'null' or cancellation = '';

update 
	pizza_runner.runner_orders
set
	distance = replace(distance,'km','');

update 
	pizza_runner.runner_orders
set
	duration = REGEXP_REPLACE(duration,'([0-9]*)(.*)','\1')
where 
	duration is not null;

alter table pizza_runner.runners add primary key(runner_id);
	

-- A. Pizza Metrics

-- How many pizzas were ordered?
select 
	count(*) total_pizza_ordered
from 
	pizza_runner.customer_orders;
	
-- How many unique customer orders were made?
select 
	count(distinct order_id) unique_customer_orders
from 
	pizza_runner.customer_orders;
	
-- How many successful orders were delivered by each runner?
select 
	count(*) 
from 
	pizza_runner.runner_orders
where
	cancellation is null;
	
-- How many of each type of pizza was delivered?

select
	pn.pizza_name , count(*) pizzas_delivered
from
	pizza_runner.customer_orders co
left join
	pizza_runner.pizza_names pn
on
	co.pizza_id = pn.pizza_id
where
	not (co.order_id = ANY(select 
						   	order_id 
						   from 
						   	pizza_runner.runner_orders 
						   where 
						   	cancellation is not null)
		)
group by
	pn.pizza_name;

-- or

select
	pn.pizza_name , count(*) pizzas_delivered
from
	pizza_runner.customer_orders co
left join
	pizza_runner.pizza_names pn
on
	co.pizza_id = pn.pizza_id
where
	exists(select 1 from pizza_runner.runner_orders where cancellation is null and order_id = co.order_id)
group by
	pn.pizza_name;
	
-- How many Vegetarian and Meatlovers were ordered by each customer?
select
	pn.pizza_name , count(*) pizzas_ordered
from
	pizza_runner.customer_orders co
left join
	pizza_runner.pizza_names pn
on
	co.pizza_id = pn.pizza_id
group by
	pn.pizza_name;
	
	
-- What was the maximum number of pizzas delivered in a single order?
with counted_pizza_deliveres as (
	select
		order_id ,count(*)
	from
		pizza_runner.customer_orders 
	where
		not (order_id = ANY(select 
								order_id
							from 
								pizza_runner.runner_orders 
							where 
								cancellation is not null)
			)
	group by
		order_id
)
select 
	max(count) max_pizza_in_single_order
from
	counted_pizza_deliveres;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with with_changes as (
	select
		* ,
		case
			when 
				extras is not null or exclusions is not null
			then
				1
			else
				0
			end as has_change
	from
		pizza_runner.customer_orders
	where
		not (order_id = ANY(select 
								order_id
							from 
								pizza_runner.runner_orders 
							where 
								cancellation is not null)
			)
)
select 
	case 
		has_change
	when 
		1 
	then 
		'has_change'
	else 
		'has_no_change'
	end,
	count(*)
from 
	with_changes
group by
	has_change;
	

-- How many pizzas were delivered that had both exclusions and extras?
select 
	count(*)
from
	pizza_runner.customer_orders
where
	exclusions is not null 
	and 
	extras is not null
	and
	not (order_id = ANY(select 
							order_id 
						   from 
							pizza_runner.runner_orders 
						   where 
							cancellation is not null)
		);
		

-- What was the total volume of pizzas ordered for each hour of the day?
select 
	date_trunc('hour' , order_time) hour_wise , count(*) pizza_ordered
from
	pizza_runner.customer_orders
group by
	date_trunc('hour' , order_time)
order by
	hour_wise;
	
-- What was the volume of orders for each day of the week?
select 
	date_trunc('day' , order_time) hour_wise , count(*) pizza_ordered
from
	pizza_runner.customer_orders
group by
	date_trunc('day' , order_time)
order by
	hour_wise;
	


-- B. Runner and Customer Experience


-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select
	date_bin('1 week', registration_date, '2021-01-01'::date)::date week_start_dates , count(*) runner_signed_up
from
	pizza_runner.runners
group by 
	date_bin('1 week', registration_date, '2021-01-01'::date)::date
order by
	week_start_dates;
	

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- can use ceil or floor as well on avg
select
	ro.runner_id,
	extract(minute from avg(ro.pickup_time::timestamp-co.order_time))
	   avg_time_before_pickup_in_min
from
	pizza_runner.customer_orders co
left join
	pizza_runner.runner_orders ro
on
	co.order_id = ro.order_id
group by
	ro.runner_id
order by
	ro.runner_id;
	
-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- ANS: No

-- What was the average distance travelled for each customer?
select 
	customer_id , round(avg(distance::numeric),2)
from
	pizza_runner.customer_orders co
left join
	pizza_runner.runner_orders ro
on
 	co.order_id = ro.order_id
group by
	customer_id;
	
-- What was the difference between the longest and shortest delivery times for all orders?
with cte_with_delivery_times as (    
	select
		age(ro.pickup_time::timestamp,co.order_time ) + (duration || ' minutes')::interval as delivery_time
	from
		pizza_runner.customer_orders co
	left join
		pizza_runner.runner_orders ro
	on
		co.order_id = ro.order_id
	where
		cancellation is null
	order by
		delivery_time
)
select 
	max(delivery_time) longest_delivery_time , min(delivery_time) shortest_delivery_time
from 
	cte_with_delivery_times;
	
-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select
	ro.order_id,ro.runner_id , co.customer_id ,pickup_time,distance,duration, round((distance::float/duration::int)::numeric,2) avg_speed
from
	pizza_runner.runner_orders ro
left join
	pizza_runner.customer_orders co
on
	co.order_id = ro.order_id
order by
	runner_id,ro.order_id,pickup_time
	
-- Trend Observed: I have observed that as a rider delivers more pizza his avg_speed of delivery increases. Also it could be that time taken to delivery
-- pizza to previously delivered client is comparatively shorter

-- What is the successful delivery percentage for each runner?
with runner_delivery_metrices as (
	select 
		runner_id ,
		count(*)::numeric total_orders,
		sum(
		case 
			when cancellation is null
			then 1
			else 0
		end
		   )::numeric order_fulfilled,
		sum(
			case 
				when cancellation is not null
				then 1
				else 0
			end
			   )::numeric order_cancelled
	from
		pizza_runner.runner_orders
	group by
		runner_id	
)
select 
	runner_id , order_fulfilled ,total_orders, round(order_fulfilled/total_orders*100,2) delivery_percentage_of_runner 
from 
	runner_delivery_metrices



-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?
CREATE EXTENSION IF NOT EXISTS tablefunc;

with topping_id as (
select
	pizza_id
	,
	unnest(string_to_array(toppings,','))::int topping_id
from
	pizza_runner.pizza_recipes pr
),
topping_names as (
select 
	* 
from
	topping_id ti
left join
	pizza_runner.pizza_toppings pt
on
	ti.topping_id = pt.topping_id
)
select 
	pizza_id , string_agg(topping_name,', ') standard_ingredients
from 
	topping_names
group by
	pizza_id
order by
	pizza_id
	

-- What was the most commonly added extra?
with extras_topping_id as (
	select
		  unnest(string_to_array(extras,','))::int topping_id , count(*)
	from
		pizza_runner.customer_orders
	group by
		unnest(string_to_array(extras,','))::int
)
select 
	topping_name most_common_extras
from
	pizza_runner.pizza_toppings
where
	topping_id = (
			select 
				topping_id 
			from 
				extras_topping_id 
			order by 
				count DESC 
			limit 1)

-- What was the most common exclusion?
with exclusion_topping_id as (
	select
		  unnest(string_to_array(exclusions,','))::int topping_id , count(*)
	from
		pizza_runner.customer_orders
	group by
		unnest(string_to_array(exclusions,','))::int
)
select 
	topping_name most_common_exclusion
from
	pizza_runner.pizza_toppings
where
	topping_id = (
			select 
				topping_id 
			from 
				exclusion_topping_id 
			order by 
				count DESC 
			limit 1)


/* Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
 	Meat Lovers - Exclude Beef
 	Meat Lovers - Extra Bacon
 	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/
	
with extras_topping_id as (
	select
		  distinct order_id ,co.pizza_id, unnest(string_to_array(extras,','))::int topping_id
	from
		pizza_runner.customer_orders co
	
)
,extras_topping_names as (
	select
		order_id , pizza_id , 'Extra '||string_agg(topping_name,', ') extras_text
	from
		extras_topping_id eti
	left join
		pizza_runner.pizza_toppings pt
	on
		eti.topping_id = pt.topping_id
	group by
		order_id , pizza_id
		
),
exclusions_topping_id as (
	select
		  distinct order_id ,co.pizza_id, unnest(string_to_array(exclusions,','))::int topping_id
	from
		pizza_runner.customer_orders co
	
)
,exclusions_topping_names as (
	select
		order_id , pizza_id , 'Exclude '||string_agg(topping_name,', ') exclusions_text
	from
		exclusions_topping_id eti
	left join
		pizza_runner.pizza_toppings pt
	on
		eti.topping_id = pt.topping_id
	group by
		order_id , pizza_id
		
)
select 
	co.* , pizza_name || coalesce(' - ' || exclusions_text,'') || coalesce(' - ' || extras_text,'') as  item
from 
	pizza_runner.customer_orders co
left join
	pizza_runner.pizza_names pn
on
	co.pizza_id = pn.pizza_id
left join
	exclusions_topping_names exclude_tn
on
	exclude_tn.order_id = co.order_id and exclude_tn.pizza_id = co.pizza_id
left join
	extras_topping_names extras_tn
on
	extras_tn.order_id = co.order_id and extras_tn.pizza_id = co.pizza_id
order by
	order_id;


/* Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
 	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/
with co_with_used_toppings as (
	select 
		row_number() over(order by order_id ) sr_no, co.* , unnest(string_to_array(toppings,','))::int topping_id , 0 is_extra
	from
		pizza_runner.customer_orders co
	left join
		pizza_runner.pizza_recipes pr
	on
		co.pizza_id = pr.pizza_id
	
	EXCEPT
	
	select 
		row_number() over(order by order_id ) sr_no,co.* , unnest(string_to_array(extras,','))::int topping_id , 0 is_extra
	from
		pizza_runner.customer_orders co
	
	EXCEPT
	
	select 
		row_number() over(order by order_id ) sr_no,co.* , unnest(string_to_array(exclusions,','))::int topping_id , 0 is_extra
	from
		pizza_runner.customer_orders co
	
	UNION
	
	select 
		row_number() over(order by order_id ) sr_no,co.* , unnest(string_to_array(extras,','))::int topping_id , 1 is_extra
	from
		pizza_runner.customer_orders co
),
sr_no_with_ingredients as (
select 
	sr_no ,order_id , customer_id , pizza_id, exclusions , extras,order_time ,
	string_agg(
	case is_extra
		when 0
		then
			topping_name 
		when 1
		then
			'2x'||topping_name
	end,', ' order by topping_name) ingredient_list
from 
	co_with_used_toppings cwut
left join
	pizza_runner.pizza_toppings pr
on 
	cwut.topping_id = pr.topping_id
group by
	sr_no ,order_id , customer_id , pizza_id, exclusions , extras,order_time
)
select 
	order_id , customer_id , srwi.pizza_id, exclusions , extras,order_time , pizza_name || ': ' || ingredient_list  as ingredient_list
	
from 
	sr_no_with_ingredients srwi
left join
	pizza_runner.pizza_names pn
on
	srwi.pizza_id = pn.pizza_id;
	

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with co_with_used_toppings as (
	select 
		row_number() over(order by order_id ) sr_no, unnest(string_to_array(toppings,','))::int topping_id 
	from
		pizza_runner.customer_orders co
	left join
		pizza_runner.pizza_recipes pr
	on
		co.pizza_id = pr.pizza_id
	
	EXCEPT
	
	select 
		row_number() over(order by order_id ) sr_no, unnest(string_to_array(exclusions,','))::int topping_id 
	from
		pizza_runner.customer_orders co
	
	UNION ALL
	
	select 
		row_number() over(order by order_id ) sr_no,  unnest(string_to_array(extras,','))::int topping_id
	from
		pizza_runner.customer_orders co
)
select 
	topping_name , count(*) total_quantity
from
	co_with_used_toppings cwut
left join
	pizza_runner.pizza_toppings pt
on
	cwut.topping_id =  pt.topping_id
group by
	topping_name
order by
	total_quantity DESC;
	

-- D. Pricing and Ratings

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
select 
	sum(case pizza_id
	   when 1 then 12
	   when 2 then 10
	   end) earnings
from
	pizza_runner.customer_orders;


-- What if there was an additional $1 charge for any pizza extras?
-- 	Add cheese is $1 extra
select 
	sum(case pizza_id
	   when 1 
			then 12 + coalesce(cardinality(string_to_array(extras,',')),0)
	   when 2 
			then 10 + coalesce(cardinality(string_to_array(extras,',')),0)
	   end) earnings
from
	pizza_runner.customer_orders;

-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- drop schema pizza_runner_ratings cascade
create schema  pizza_runner_ratings
	create table runner_ratings (
		order_id int ,
		runner_id int ,
		customer_id int ,
		rating int check (rating  between 0 and 5) not null,
		primary key (order_id,customer_id,runner_id)
	);
insert into 
	pizza_runner_ratings.runner_ratings 
values 
	(1,1,101,4),
	(2,1,101,5),
	(4,2,103,3);


-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- 	customer_id
-- 	order_id
-- 	runner_id
-- 	rating
-- 	order_time
-- 	pickup_time
-- 	Time between order and pickup
-- 	Delivery duration
-- 	Average speed
-- 	Total number of pizzas

select 
	co.customer_id , co.order_id , ro.runner_id, rr.rating, co.order_time, ro.pickup_time,
	ro.pickup_time::timestamp-co.order_time time_between_order_and_pickup, ro.duration || 'min' duration ,
	round((ro.distance::float/ro.duration::float*60.0)::numeric,2) || 'km/hr' speed,
	count(*) total_pizza_ordered
from
	pizza_runner.customer_orders co 
left join
	pizza_runner.runner_orders ro
on
	co.order_id = ro.order_id
left join
	pizza_runner_ratings.runner_ratings rr
on
	co.order_id = rr.order_id and ro.runner_id = rr.runner_id and co.customer_id = rr.customer_id
where
	ro.cancellation is  null
group by
	co.customer_id , co.order_id , ro.runner_id, rr.rating, co.order_time, ro.pickup_time,ro.duration,ro.distance

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

select
	sum(case pizza_id
	   when 1 then 12
	   when 2 then 10
	   end) earnings,
	round(sum(0.3 *ro.distance::float)::numeric,2) runners_paid,
	sum(case pizza_id
	   when 1 then 12
	   when 2 then 10
	   end) - round(sum(0.3 *ro.distance::float)::numeric,2) amount_left
from
	pizza_runner.customer_orders co
left join
	pizza_runner.runner_orders ro
on
	co.order_id = ro.order_id	


-- E. Bonus Questions

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

-- Adding a new pizaa with all ingredients as its recipie won't affrect the data design of any of the current tables
insert into 
	pizza_runner.pizza_names 
values
	(3,'Supreme pizza')
	
insert into
	pizza_runner.pizza_recipes
values
	(3,'1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12')
	
