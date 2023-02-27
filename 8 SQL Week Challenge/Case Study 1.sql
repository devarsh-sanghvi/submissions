/* --------------------
   Case Study Questions
   --------------------*/

select * from dannys_diner.sales

-- 1. What is the total amount each customer spent at the restaurant?

select 
	sl.customer_id , sum(price) amount_spent
from 
	dannys_diner.sales sl
left join
	dannys_diner.menu mn
on
	sl.product_id = mn.product_id
group by
	sl.customer_id
order by
	sl.customer_id

-- 2. How many days has each customer visited the restaurant?

with distinct_dates as (
select 
	distinct customer_id ,  order_date
from 
	dannys_diner.sales
)
select 
	customer_id , count(*) days_visited
from 
	distinct_dates
group by
	customer_id
order by
	customer_id


-- 3. What was the first item from the menu purchased by each customer?
-- Unpredictable as input table seems to be sorted with product_id after join. If thats okay then here is the query.
-- can add datetime when placing order for each item or can accept multiple items as first purchase.

with cte as (select 
	customer_id , order_date, product_name, row_number() over(partition by customer_id order by customer_id , order_date)
from
	dannys_diner.sales sl
left join
	dannys_diner.menu mn
on
	sl.product_id = mn.product_id
)
select customer_id , order_date, product_name from cte where row_number = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select 
	sl.product_id,mn.product_name , count(*) sales_count
from
	dannys_diner.sales sl
inner join
	dannys_diner.menu mn
on
	sl.product_id = mn.product_id
group by
	sl.product_id,mn.product_name
order by
	sales_count DESC
fetch first row only;
	
with cte as (
	select 
		product_id , count(*)
	from
		dannys_diner.sales
	group by
		product_id
	order by
		count DESC
	fetch first row only
)
select 
	customer_id , count(*)
from
	dannys_diner.sales
where 
	product_id = (
		select 
			product_id 
		from 
			cte)
group by
	customer_id

-- 5. Which item was the most popular for each customer?

with sales_counted as (
	select 
		customer_id , product_id,count(*) sales_count
	from 
		dannys_diner.sales
	group by
		customer_id,product_id
	),
favourite_ranked as (
	select 
		*,
		dense_rank()  over(
						partition by 
							customer_id
						order by 
							sales_count DESC
		) as favourite_rank 
	from 
		sales_counted )
select 
	customer_id, product_name as most_popular_item -- ,sales_count
from 
	favourite_ranked  fr
left join
	dannys_diner.menu mn
on
	fr.product_id = mn.product_id
where 
	favourite_rank = 1
order by
	customer_id

-- 6. Which item was purchased first by the customer after they became a member?

-- Q1 via subquery
with ranked_data as (
	select 
		* , dense_rank() over(partition by s1.customer_id order by order_date) ranking
	from 
		dannys_diner.sales s1
	where 
		exists (
			select 
				1 
			from 
				dannys_diner.members s2 
			where 
				s1.customer_id = s2.customer_id 
			and 
				s1.order_date >= s2.join_date
		)
)
select
	rd.customer_id, rd.order_date,mn.product_name as first_purchased_after_becoming_member
from 
	ranked_data rd
left join
	dannys_diner.menu mn
on 
	rd.product_id = mn.product_id
where
	ranking = 1
order by
	customer_id;


--Q2 via joins
with ranked_data as (
select 
	sl.customer_id,sl.order_date,sl.product_id,dense_rank() over(partition by sl.customer_id order by order_date) ranking
from
	dannys_diner.sales sl
left join
	dannys_diner.members mn
on 
	sl.customer_id = mn.customer_id
where
	order_date >= join_date
)
select
	rd.customer_id, rd.order_date,mn.product_name as first_purchased_after_becoming_member
from 
	ranked_data rd
left join
	dannys_diner.menu mn
on 
	rd.product_id = mn.product_id
where
	ranking = 1
order by
	customer_id;

-- 7. Which item was purchased just before the customer became a member?

with ranked_data as (
	select 
		* , dense_rank() over(partition by s1.customer_id order by order_date DESC) ranking
	from 
		dannys_diner.sales s1
	where 
		exists (
			select 
				1 
			from 
				dannys_diner.members s2 
			where 
				s1.customer_id = s2.customer_id 
			and 
				s1.order_date < s2.join_date
		)
)
select
	rd.customer_id, rd.order_date,mn.product_name as purchased_just_before_becoming_member
from 
	ranked_data rd
left join
	dannys_diner.menu mn
on 
	rd.product_id = mn.product_id
where
	ranking = 1
order by
	customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
with before_member_data as (
	select 
		customer_id , product_id
	from 
		dannys_diner.sales s1
	where 
		exists (
			select 
				1 
			from 
				dannys_diner.members s2 
			where 
				s1.customer_id = s2.customer_id 
			and 
				s1.order_date < s2.join_date
		)
)
select
	bm.customer_id, count(*) total_items_before_member, sum(price) amount_spent_before_member
from
	before_member_data bm
left join
	dannys_diner.menu mn
on
	bm.product_id = mn.product_id
group by
	bm.customer_id
order by
	bm.customer_id
	
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with customer_points as (
	select 
		sl.customer_id ,
		mn.price,
		10 points,
		case mn.product_name
			when 'sushi' then 2
			else 1
		end points_multiplier

	from
		dannys_diner.sales sl
	left join
		dannys_diner.menu mn
	on
		sl.product_id = mn.product_id
)
select customer_id , sum(price*points*points_multiplier)
from customer_points
group by
	customer_id
order by
	customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with normal_orders as (
	select 
		sl.customer_id,sl.order_date,mn.join_date,sl.product_id
	from
		dannys_diner.sales sl
	left join
		dannys_diner.members mn
	on 
		sl.customer_id = mn.customer_id
	where
		(order_date < join_date or order_date >= join_date and order_date>= join_date + '7 days'::interval )and Extract(month from order_date)  = 1 
),
orders_in_loyalty_program as (
	select 
		sl.customer_id,sl.order_date,mn.join_date,sl.product_id
	from
		dannys_diner.sales sl
	left join
		dannys_diner.members mn
	on 
		sl.customer_id = mn.customer_id
	where
		join_date <= order_date and order_date< join_date + '7 days'::interval  and Extract(month from order_date)  = 1 
),
customer_points as (
	select 
		*,
		10 points,
		case mn.product_name
			when 'sushi' then 2
			else 1
		end points_multiplier
	from
		normal_orders nmo
	left join
		dannys_diner.menu mn
	on
		nmo.product_id = mn.product_id
	UNION
	select 
		*,
		10 points,
		
		2 points_multiplier

	from
		orders_in_loyalty_program olp
	left join
		dannys_diner.menu mn
	on
		olp.product_id = mn.product_id	
)
select 
	customer_id , sum(price*points*points_multiplier)
from 
	customer_points
group by
	customer_id
order by
	customer_id
	
-- Bonus Queries 

-- (Join All The Things)
-- output columns: customer_id 	order_date 	product_name 	price 	member:(Y/N)

select 
	sl.customer_id , sl.order_date, mn.product_name, mn.price,
	CASE
		when sl.order_date >= mm.join_date then 'Y'
		else 'N' 
	END as member
from
	dannys_diner.sales sl
left join
	dannys_diner.menu mn
on
	sl.product_id = mn.product_id
left join
	dannys_diner.members mm
on
	sl.customer_id = mm.customer_id
order by
	sl.customer_id , sl.order_date, mn.price Desc
	
-- (Rank All The Things)
-- output columns: customer_id 	order_date 	product_name 	price 	member 	ranking

with final_result as (
	select 
		sl.customer_id , sl.order_date, mn.product_name, mn.price,
		'Y' as member,
		dense_rank() over(partition by sl.customer_id order by sl.order_date,mn.price DESC) ranking
	from
		dannys_diner.sales sl
	left join
		dannys_diner.menu mn
	on
		sl.product_id = mn.product_id
	left join
		dannys_diner.members mm
	on
		sl.customer_id = mm.customer_id
	where
		sl.order_date >= mm.join_date	
	
	UNION ALL
	
	select 
		sl.customer_id , sl.order_date, mn.product_name, mn.price,
		'N' as member, null as ranking
	from
		dannys_diner.sales sl
	left join
		dannys_diner.menu mn
	on
		sl.product_id = mn.product_id
	left join
		dannys_diner.members mm
	on
		sl.customer_id = mm.customer_id
	where
		sl.order_date < mm.join_date or mm.join_date is null
	
)
select
	* 
from 
	final_result 
order by
	customer_id , order_date, price Desc