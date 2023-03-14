/*
	Case Study 6
*/

-- 1. Enterprise Relationship Diagram
-- Saved in assets folder


-- 2. Digital Analysis

-- Using the available datasets - answer the following questions using a single query for each one:

--     How many users are there?
select 
	count(distinct user_id) 
from 
	clique_bait.users

--     How many cookies does each user have on average?
with cte as (
	select 
		count(*) 
	from 
		clique_bait.users
	group by
		user_id
)
select round(avg(count)) avg_cookie_per_user from cte

--     What is the unique number of visits by all users per month?
select 
	date_trunc('month',event_time) visited_month , count(distinct visit_id)  total_unique_visits
from 
	clique_bait.events
group by
	1

--     What is the number of events for each event type?
select 
	event_type , count(*)  total_events
from 
	clique_bait.events
group by
	1

--     What is the percentage of visits which have a purchase event?
select 
	sum(case event_type when 3 then 1 else 0 end)::numeric,sum(case event_type when 3 then 1 else 0 end)::numeric * 100/ count(distinct visit_id) percentage_of_visits_of_purchase_events
from 
	clique_bait.events
	
--     What is the percentage of visits which view the checkout page but do not have a purchase event?
with cte as (
select 
	visit_id,
	sum(case event_type when 3 then 1 else 0 end) purchased ,
	sum(case page_id when 12 then 1 else 0 end) visited_checkout
from 
	clique_bait.events
group by visit_id
)
select 
	100*sum(
		case 
			when visited_checkout=1 and purchased = 0 
		then 1 else 0 
		end
	)::numeric/count(*) percentage_of_visit_checkout_no_purchase_events
from 
	cte 
	
--     What are the top 3 pages by number of views?
select
	page_id , sum(case event_type when 1 then 1 else 0 end) page_views
from
	clique_bait.events
group by
	1
order by
	page_views Desc
limit 3

--     What is the number of views and cart adds for each product category?
select
	product_category , sum(case event_type when 1 then 1 else 0 end) page_views , sum(case event_type when 2 then 1 else 0 end) cart_adds
from
	clique_bait.events cbe
left join
	clique_bait.page_hierarchy cbph
on
	cbe.page_id = cbph.page_id
group by
	1
order by
	page_views Desc

--     What are the top 3 products by purchases?
with cte as (
select
	* , max(cbe.page_id) over(partition by visit_id) max_page_id
from
	clique_bait.events cbe
left join
	clique_bait.page_hierarchy cbph
on
	cbe.page_id = cbph.page_id
where
	event_type = 2 or event_type = 3
)
select 
	page_name , count(*) purchases
from
	cte
where
	max_page_id  = 13 and event_type = 2
group by
	page_name
order by
	purchases Desc
limit 3


-- 3. Product Funnel Analysis
-- Using a single SQL query - create a new output table which has the following details:

--     How many times was each product viewed?
--     How many times was each product added to cart?
--     How many times was each product added to a cart but not purchased (abandoned)?
--     How many times was each product purchased?

create table 
	clique_bait.product_metrices 
as
	with cte as (
		select
			* , max(cbe.page_id) over(partition by visit_id) max_page_id
		from
			clique_bait.events cbe
		left join
			clique_bait.page_hierarchy cbph
		on
			cbe.page_id = cbph.page_id
	)
	select 
		page_name ,
		sum(case event_type when 1 then 1 else 0 end) page_views,
		sum(case event_type when 2 then 1 else 0 end) added_to_cart,
		sum(case when event_type = 2 and max_page_id = 13 then 1 else 0 end) purchases,
		sum(case when event_type = 2 and max_page_id <> 13 then 1 else 0 end) abandoned,
		100*(sum(case when event_type = 2 and max_page_id = 13 then 1 else 0 end))::numeric /sum(case event_type when 1 then 1 else 0 end) view_to_purchase_percentage,
		100*(sum(case event_type when 2 then 1 else 0 end))::numeric /sum(case event_type when 1 then 1 else 0 end) view_to_cartadd_rate,
		100*(sum(case when event_type = 2 and max_page_id = 13 then 1 else 0 end))::numeric /sum(case event_type when 2 then 1 else 0 end) cartadd_to_purchase_rate
	from
		cte
	where
		product_id is not null
	group by
		page_name


-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

with cte as (
	select
		* , max(cbe.page_id) over(partition by visit_id) max_page_id
	from
		clique_bait.events cbe
	left join
		clique_bait.page_hierarchy cbph
	on
		cbe.page_id = cbph.page_id
)
select 
	product_category ,
	sum(case event_type when 1 then 1 else 0 end) page_views,
	sum(case event_type when 2 then 1 else 0 end) added_to_cart,
	sum(case when event_type = 2 and max_page_id = 13 then 1 else 0 end) purchases,
	sum(case when event_type = 2 and max_page_id <> 13 then 1 else 0 end) abandoned
from
	cte
where
	product_id is not null
group by
	product_category

-- Use your 2 new output tables - answer the following questions:

--     Which product had the most views, cart adds and purchases?
SELECT * from clique_bait.product_metrices where page_views = (select max(page_views) from clique_bait.product_metrices)
SELECT * from clique_bait.product_metrices where added_to_cart = (select max(added_to_cart) from clique_bait.product_metrices)
SELECT * from clique_bait.product_metrices where purchases = (select max(purchases) from clique_bait.product_metrices)
/*	Most of prduct matrices:
 		views: Oyster, Cart adds: Lobster, purchases: Lobster
*/
--     Which product was most likely to be abandoned?
SELECT * from clique_bait.product_metrices where abandoned = (select max(abandoned) from clique_bait.product_metrices)
/*	Most likely Abandoned: Russian Caviar
*/
--     Which product had the highest view to purchase percentage?
SELECT * from clique_bait.product_metrices where view_to_purchase_percentage = (select max(view_to_purchase_percentage) from clique_bait.product_metrices)
/*	Lobster
*/
--     What is the average conversion rate from view to cart add?
SELECT avg(view_to_cartadd_rate) avg_view_to_cartadd_rate from clique_bait.product_metrices
/*	
*/
--     What is the average conversion rate from cart add to purchase?
SELECT avg(cartadd_to_purchase_rate) avg_cartadd_to_purchase_rate from clique_bait.product_metrices


-- 3. Campaigns Analysis

-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:

--     user_id
--     visit_id
--     visit_start_time: the earliest event_time for each visit
--     page_views: count of page views for each visit
--     cart_adds: count of product cart add events for each visit
--     purchase: 1/0 flag if a purchase event exists for each visit
--     campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
--     impression: count of ad impressions for each visit
--     click: count of ad clicks for each visit
--     (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

-- create table if not exists clique_bait.campaign_analysis as
select 
	usr.user_id, visit_id, min(event_time) visit_start_time,
	sum(case event_type when 1 then 1 else 0 end) page_views,
	sum(case event_type when 2 then 1 else 0 end) cart_adds,
	sum(case when event_type = 3 then 1 else 0 end) purchase,
	campaign_name,
	sum(case when event_type = 4 then 1 else 0 end) impression,
	sum(case when event_type = 5 then 1 else 0 end) click,
	string_agg(case when product_id is not null then page_name end , ',' order by sequence_number) cart_products
from 
	clique_bait.events evn
left join
	clique_bait.users usr
on
	usr.cookie_id  = evn.cookie_id
left join
	clique_bait.campaign_identifier ci
on
	evn.event_time between ci.start_date and ci.end_date
left join
	clique_bait.page_hierarchy ph
on
	ph.page_id = evn.page_id 
group by
	usr.user_id, evn.visit_id , ci.campaign_name
order by
	1,2

-- Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.
-- SKIPPING INFOGRAPHICS
-- Some ideas you might want to investigate further include:

--     Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
--     Does clicking on an impression lead to higher purchase rates?
--     What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
--     What metrics can you use to quantify the success or failure of each campaign compared to eachother?




select * from clique_bait.events