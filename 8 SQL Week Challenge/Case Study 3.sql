/*
	Case Study 3
*/

-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

select * 
from 
	foodie_fi.subscriptions s
left join
	foodie_fi.plans p
on
	s.plan_id = p.plan_id
where customer_id = ANY('{1,2,11,13,15,16,18,19}'::int[])

/*
customer_id : Description
	 1: upgraded to basic monthly
	 2: upgraded to pro annual
	11: cancelled after trial
	13: upgraded to basic monthly and after 3 months upgraded to pro monthly
	15: upgraded to pro monthly and after a month cancelled the service
	16: upgraded to basic monthly and after 4 months upgraded to pro annual
	18: upgraded to pro monthly
	19: upgraded to pro monthly and after 2 months upgraded to pro annual
	
*/	
	
	
-- B. Data Analysis Questions

-- How many customers has Foodie-Fi ever had?
select 
	count(distinct customer_id) customers_ever_had
from
	foodie_fi.subscriptions

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select 
	date_trunc('month',start_date)::date,count(*)
from
	foodie_fi.subscriptions
group by
	date_trunc('month',start_date)
order by
	date_trunc('month',start_date)
	

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select
	*
from
	foodie_fi.subscriptions
where 
	extract('year' from start_date) > 2020 
	
select 
	plan_name, count(*) events_occured
from
	foodie_fi.subscriptions s
left join
	foodie_fi.plans p
on
	s.plan_id = p.plan_id
group by
	plan_name
	

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
with churn_metix as (
	select
		sum(case plan_name
				when 'churn' then 1
			else 0
			end)::numeric total_churn_plans,
		count( distinct customer_id)::numeric total_customers
	from
		foodie_fi.subscriptions s
	left join
		foodie_fi.plans p
	on
		s.plan_id = p.plan_id
)
select 
	total_churn_plans churn_customer_count ,
	round(total_churn_plans/total_customers*100,1) percentage_of_churned_customers
from
	churn_metix


-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with prev as (
	select 
		customer_id ,plan_id ,lag(plan_id,1) over (partition by customer_id) prev 
	from
		foodie_fi.subscriptions
),
churn_after_trial as (
	select 
		sum(case
				when plan_id = 4 and prev = 0
				then 1
				else 0
			end
		   ) customers_churned_straight_after_trial
		,
		count(distinct customer_id) total_customers
	from
		prev

		
)
select 
	customers_churned_straight_after_trial,
	(customers_churned_straight_after_trial*100)/total_customers percnt_churned_customers 
from churn_after_trial


-- What is the number and percentage of customer plans after their initial free trial?
select
	sum(case plan_id
	   	when 0 then 0 else 1
	   	end),
	round((sum(case plan_id
	   	when 0 then 0 else 1
	   	end)::float/count(*)::float*100)::numeric,2)
from
		foodie_fi.subscriptions
		

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
select 
	distinct plan_name ,
	count(*) over(partition by plan_name),
	round(count(*) over(partition by plan_name)::numeric/count(*) over()::numeric * 100,2)
from
	foodie_fi.subscriptions s
left join
	foodie_fi.plans p
on
	s.plan_id = p.plan_id
where
	start_date <= '2020-12-31'::date

-- How many customers have upgraded to an annual plan in 2020?
select
	count(distinct customer_id) upgraded_annual_plan_2020
from
	foodie_fi.subscriptions
where
	extract(year from start_date) = 2020 and plan_id = 3

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with annual_plan_diff as (
select
	start_date - lag(start_date) over(partition by customer_id order by plan_id ) days_to_annual
from
	foodie_fi.subscriptions
where
	plan_id in (0,3)
)
select round(avg(days_to_annual),2) avg_days_to_annual_plan from annual_plan_diff

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with annual_plan_diff as (
	select
		start_date - lag(start_date) over(partition by customer_id order by plan_id ) days_to_annual
	from
		foodie_fi.subscriptions
	where
		plan_id in (0,3)
),
group_period_30 as (
	select 
		case 
			when days_to_annual%30 = 0 and days_to_annual<>30 then ((days_to_annual/30)-1)*30 +1 
			when days_to_annual<=30 then 0
			else
				(days_to_annual/30)*30+1
		end || '-'||
		case
			when days_to_annual%30 = 0 then days_to_annual
			else
				((days_to_annual/30)+1)*30 
		end || ' days' group_name , days_to_annual
	from
		annual_plan_diff
	where
		days_to_annual is not null
)
select 
	group_name , count(*)
from 
	group_period_30
group by
	group_name
order by
	split_part(group_name,'-',1)::int
	
	

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with prev_plan_ids as (
select
	* , lag(plan_id,1) over() prev_plan_id
from
	foodie_fi.subscriptions
where
	extract(year from start_date) = 2020
order by 
	customer_id , start_date
)
select 
	* 
from 
	prev_plan_ids
where
	plan_id = 2 and prev_plan_id = 3


-- C. Challenge Payment Question
create table foodie_fi.payments(
	customer_id int,
	plan_id int,
	plan_name text,
	payment_date date,
	amount int,
	payment_order int,
	primary key(customer_id , payment_order))

with recursive cte as (
	select 
		customer_id,
		plan_id,
		start_date ,
		case plan_id
		when 0 then (start_date + '7 days'::interval)::date 
		when 1 then (start_date + '1 month'::interval)::date 
		when 2 then (start_date + '1 month'::interval)::date 
		when 3 then (start_date + '1 year'::interval)::date 
		else start_date
		end next_date,
		case plan_id
		when 0 then (start_date + '14 days'::interval)::date 
		when 1 then (start_date + '2 month'::interval)::date 
		when 2 then (start_date + '2 month'::interval)::date 
		when 3 then (start_date + '2 year'::interval)::date 
		else start_date
		end next_2_next_date,
		case plan_id
		when 0 then 1
		end active,
		lead(plan_id,1 ) over(partition by customer_id) next_plan_id,
		lead(plan_id,2 ) over(partition by customer_id) next_2_next_plan_id,
		lead(start_date,1 ) over(partition by customer_id) next_plan_date,
		lead(start_date,2 ) over(partition by customer_id) next_2_next_plan_date,
		row_number() over(partition by customer_id order by start_date)::int,
		0 amount_id,
		0 discount_id,
		1 iteration,
		case 
			when plan_id <> 0  and start_date =  (lag(start_date,1) over(partition by customer_id order by start_date) +'7 days'::interval)::date
				then 1
			else 0
		end remove,
		 lag(start_date,1) over(partition by customer_id order by start_date ) extra
	from 
		foodie_fi.subscriptions 
	union
	select 
		customer_id ,
		case 
			when active=1 and plan_id =0
			then next_plan_id
			when active = 1 and plan_id IN (1,2,3) and   next_date < next_plan_date 
			then plan_id
			when active = 1 and plan_id IN (1,2,3) and   next_date >= next_plan_date and next_plan_id = 4
			then 4
			when active = 1 and plan_id = 1 and   next_date >= next_plan_date and next_plan_id in (2,3)
			then next_plan_id
			when active = 1 and plan_id in (2,3)  and next_date >= next_plan_date
			then next_plan_id
			else plan_id
		end plan_id,
		case
			when active=1 and plan_id =0
			then next_plan_date
			when active = 1 and plan_id = 1 and   next_date >= next_plan_date and next_plan_id in (2,3)
			then next_plan_date
			when active = 1 and plan_id in (2,3) and   next_date >= next_plan_date
			then next_plan_date
			when active = 1 and plan_id in (1,2,3) and  next_date <= coalesce(next_plan_date,next_date) 
			then next_date

			when active=1
			then next_date

			else start_date
		end start_date,

		case
			when active=1 and plan_id =0 and next_plan_id in (1,2)
			then (next_plan_date + '1 month'::interval)::date
			when active=1 and plan_id =0 and next_plan_id = 3
			then (next_plan_date + '1 year'::interval)::date
			when active = 1 and plan_id = 3 and next_date < next_plan_date
			then (next_date + '1 year'::interval)::date
			when active = 1 and plan_id in (1,3) and   next_date >= next_plan_date and next_plan_id =2 
			then (next_plan_date + '1 month'::interval)::date
			when active = 1 and plan_id in (1,2) and   next_date >= next_plan_date and next_plan_id =3 
			then (next_plan_date + '1 year'::interval)::date
			when active = 1 and plan_id in (0,1,2,3) and   next_date >= next_plan_date and next_plan_id =4
			then null
			when active = 1 and plan_id in (1,2) and next_date <= coalesce(next_plan_date,next_date)
			then (next_date + '1 month'::interval)::date
			else next_date
		end next_date,
		case
			when active=1 and plan_id =0 and next_plan_id in (1,2)
			then (next_plan_date + '2 month'::interval)::date
			when active=1 and plan_id =0 and next_plan_id = 3
			then (next_plan_date + '2 year'::interval)::date
			when active = 1 and plan_id in (1,2) and   next_date < next_plan_date
			then (next_date + '2 month'::interval)::date
			when active = 1 and plan_id = 3 and   next_date < next_plan_date
			then (next_date + '2 year'::interval)::date
			when active = 1 and plan_id in (1,3) and   next_date > next_plan_date and next_plan_id =2 
			then (next_plan_date + '2 month'::interval)::date
			when active = 1 and plan_id in (1,2) and   next_date > next_plan_date and next_plan_id =3
			then (next_plan_date + '2 year'::interval)::date
			when active = 1 and plan_id in (0,1,2,3) and   next_date > next_plan_date and next_plan_id =4
			then null
		end next_2_next_date,

		case
			when active=1 then 1

			else active
		end active,

		case
			when active=1 and plan_id =0
			then next_2_next_plan_id
			when active = 1 and plan_id in (1,2,3) and   next_date < next_plan_date
			then next_plan_id
			when active = 1 and plan_id in (1,2,3) and   next_date > next_plan_date and next_plan_id in (1,2,3)
			then next_2_next_plan_id

			else next_plan_id
		end next_plan_id,

		case
			when active = 1
				then nth_value(plan_id,3) over(partition by customer_id order by start_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)

			else next_2_next_plan_id
		end
		 next_2_next_plan_id,

		case
			when active=1 and plan_id =0
				then next_2_next_plan_date
			when active = 1 and plan_id in (1,2,3) and   next_date < next_plan_date
			then next_plan_date
			when active = 1 and plan_id in (1,2,3) and   next_date >= next_plan_date and next_plan_id in (1,2,3)
			then next_2_next_plan_date


			else next_plan_date
		end next_plan_date,

		case
			when active = 1
				then nth_value(start_date,3) over(partition by customer_id order by start_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)

			else next_2_next_plan_date
		end next_2_next_plan_date,
		row_number() over(partition by customer_id order by start_date)::int,
		case
			when active=1 and plan_id =0
			then next_plan_id
			when active = 1 and plan_id in (1,2,3) and   next_date < next_plan_date
			then amount_id
			when active = 1 and plan_id in (1,2,3) and   next_date >= next_plan_date and next_plan_id in (1,2,3)
			then next_plan_id
			else amount_id 

		end amount_id,

		case
			when active=1 and plan_id =0
			then plan_id
			when active = 1 and plan_id in (1,2,3) and   next_date < next_plan_date
			then 0
			when active = 1 and plan_id in (1,2,3) and   next_date >= next_plan_date and next_plan_id in (1,2,3) and plan_id <> next_plan_id
			then plan_id

			else 0
		end discount_id,
		iteration + 1,
		case 
			when active is null and (start_date <=  lag(next_date,1) over(partition by customer_id order by start_date ) or start_date <=  lag(next_2_next_date,1) over(partition by customer_id order by start_date ))
				and lag(active,1) over(partition by customer_id order by start_date ) = 1
				then 1
			when active = 1 and plan_id = 4 then 1
			else 0
		end remove,
		lag(next_date,1) over(partition by customer_id order by start_date ) extra
		from 
			cte  
		where remove = 0 and extract(year from start_date) = 2020 -- and iteration < 15
	)
select 
	customer_id ,c.plan_id, p.plan_name, start_date as payment_date, a.price - d.price as amount ,
	row_number() over(partition by customer_id order by start_date) as payment_order
from 
	cte c
left join
	foodie_fi.plans p
on
	c.plan_id = p.plan_id
left join
	foodie_fi.plans a
on
	c.amount_id = a.plan_id
left join
	foodie_fi.plans d
on
	c.discount_id = d.plan_id
where 
	c.plan_id not in (0,4) and extract(year from start_date) = 2020 and remove = 0 and active =1 and a.price - d.price> 0
order by 
	customer_id , active , iteration


-- D. Outside The Box Questions

/*
How would you calculate the rate of growth for Foodie-Fi?
	We can calculate rate of growth on basis of following:
	no of new users
	no of pro plan users
	no of stable users
*/
/* What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
	screen time of users
	ratio of visited videos vs completed videos
	category of cusin most wacthed
	category of cusin most interacted
	user-age wise most interestd cusins
*/
/*
What are some key customer journeys or experiences that you would analyse further to improve customer retention?
	which category of videos most viewed before customer joined pro plan
	geographical relation between users and content
	which category of videos most viewed before customer churn the plan
*/
/*
If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
	Was the content of their interest was on Foodi-FI. If not what was missing?
	Was the content on Foodie-fi informational?
*/
/*
What business levers could the Foodie-Fi team use to reduce the customer churn rate?
How would you validate the effectiveness of your ideas?
	A powerfull recomendation system can help foodie-fi to grow and expand dynamically (example netflix knows our interest better than us)
	As shorts are getting too much attention nowadays. Fooie_fi can add shorts for regional trending contents and promote cusins to another level.
	Foodie_fi can organise meet-ups and build an awesome community which can create a new category of "customized by community" giving exposure to awesome chefs as well entertaining invention of new cusins exclusively on Foodie_fi
*/