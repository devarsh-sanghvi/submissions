/*
	Case Study 5
*/

-- 1. Data Cleansing Steps
-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

--     Convert the week_date to a DATE format

--     Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

--     Add a month_number with the calendar month for each week_date value as the 3rd column

--     Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

--     Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

-- segment 	age_band
-- 1 		Young Adults
-- 2 		Middle Aged
-- 3 or 4 	Retirees

--     Add a new demographic column using the following mapping for the first letter in the segment values:

-- segment 	demographic
-- C 		Couples
-- F 		Families

--     Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

--     Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
create table if not exists
	data_mart.clean_weekly_sales 
as 
select week_date::date , date_part('week',week_date::date) week_number, date_part('month',week_date::date) month_number,
	date_part('year',week_date::date)  calender_year,
	region , platform, case segment when 'null' then 'unknown' else segment end segment,
	case right(segment,1)
		when '1' then 'Young Adults'
		when '2' then 'Middle Aged'
		when '3' then 'Retirees'
		when '4' then 'Retirees'
		else 'unknown'
	end age_band,
	case left(segment,1)
		when 'C' then 'Couples'
		when 'F' then 'Families'
		else 'unknown'
	end
	demographic,customer_type,transactions,sales,round(sales::numeric/transactions,2)  avg_transaction from data_mart.weekly_sales
	
	
-- 2. Data Exploration

-- What day of the week is used for each week_date value?
	select distinct week_date , EXTRACT (dow from week_date::date) day_of_week from data_mart.clean_weekly_sales;

-- What range of week numbers are missing from the dataset?
	(select * , '2020' calender_year from generate_series(1,52) misssing_week_numbers
	EXCEPT
	select distinct week_number , calender_year from data_mart.clean_weekly_sales where calender_year = '2020'
	)
	UNION
	(
	select * , '2019' calender_year from generate_series(1,52) misssing_week_numbers
	EXCEPT
	select distinct week_number , calender_year from data_mart.clean_weekly_sales where calender_year = '2019'
	)
	UNION
	(
	select * , '2018' calender_year from generate_series(1,52) misssing_week_numbers
	EXCEPT
	select distinct week_number , calender_year from data_mart.clean_weekly_sales where calender_year = '2018'
	)

-- How many total transactions were there for each year in the dataset?
	select 
		calender_year , sum(transactions) total_transactions
	from  
		data_mart.clean_weekly_sales
	group by
		calender_year

-- What is the total sales for each region for each month?
	select 
		region, date_trunc('month',week_date)::date each_month , sum(sales) total_sales
	from  
		data_mart.clean_weekly_sales
	group by
		1,2

-- What is the total count of transactions for each platform
	select 
		platform,sum(transactions) total_transactions
	from  
		data_mart.clean_weekly_sales
	group by
		1

-- What is the percentage of sales for Retail vs Shopify for each month?
	with monthly_sales as (
		select 	
			date_trunc('month',week_date)::date each_month , sum(sales) total_sales
		from  
			data_mart.clean_weekly_sales
		group by
			1
	),
	platform_sales as (
		select 
			platform , date_trunc('month',week_date)::date each_month , sum(sales) monthly_sales
		from  
			data_mart.clean_weekly_sales
		group by
			1,2
		order by
			2,1
	)
	select 
		ps.* , round(100*monthly_sales::numeric / total_sales,2) percentage_of_sales
	from 
		platform_sales ps
	left join
		monthly_sales ms
	on
		ps.each_month = ms.each_month
		
		
-- What is the percentage of sales by demographic for each year in the dataset?
with monthly_sales as (
		select 	
			date_trunc('month',week_date)::date each_month , sum(sales) total_sales
		from  
			data_mart.clean_weekly_sales
		group by
			1
	),
demographic_sales as (
	select 
		demographic , date_trunc('month',week_date)::date each_month , sum(sales) monthly_sales
	from  
		data_mart.clean_weekly_sales
	group by
		1,2
	order by
		2,1
)
select 
	ds.* , round(100*monthly_sales::numeric / total_sales,2) percentage_of_sales
from 
	demographic_sales ds
left join
	monthly_sales ms
on
	ds.each_month = ms.each_month

-- Which age_band and demographic values contribute the most to Retail sales?
select 
	age_band , demographic , sum(sales) retail_sales
from  
	data_mart.clean_weekly_sales
where
	platform = 'Retail'
group by
	1,2
order by
	3
limit 1

-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- NO, we cannot use avg_transaction column to calculate average transaction size as it will evaluated as avg(avg(sales/transactions)/transactions) which will not produce desired result 
select
	calender_year,platform ,round(sum(sales)::numeric/sum(transactions),2)
from
	data_mart.clean_weekly_sales
group by
	calender_year, platform
order by
	1,2
	
	
-- 3. Before & After Analysis

-- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

-- Using this analysis approach - answer the following questions:

--     What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
	with before_after_data as (
		select
			sum(sales) total_sales, 'before 4 weeks' analysis_mode
		from 
			data_mart.clean_weekly_sales
		where
			week_date >= '2020-06-15'::date - '4 weeks'::interval and week_date < '2020-06-15'::date  
		UNION
		select
			sum(sales) total_sales , 'after 4 weeks' analysis_mode
		from 
			data_mart.clean_weekly_sales
		where
			week_date >= '2020-06-15'::date  and week_date < '2020-06-15'::date  + '4 weeks'::interval
	)
	select 
		bad.* , round(( total_sales - lead(total_sales,1) over() )::numeric/4,2) rate_of_growth_or_reduction_per_week, round(( total_sales - lead(total_sales,1) over() )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
	from
		before_after_data bad
	
--     What about the entire 12 weeks before and after?
with before_after_data as (
	select
		sum(sales) total_sales, 'before 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date - '12 weeks'::interval and week_date < '2020-06-15'::date
	UNION
	select
		sum(sales) total_sales , 'after 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date  and week_date < '2020-06-15'::date  + '12 weeks'::interval
)
select 
	bad.* , round(( total_sales - lead(total_sales,1) over() )::numeric/12,2) rate_of_growth_or_reduction_per_week, round(( total_sales - lead(total_sales,1) over() )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
from
	before_after_data bad

--     How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
with cte as (
	select
		calender_year as analysis_mode,sum(sales)  total_sales
	from 
		data_mart.clean_weekly_sales
	group by
		calender_year
	order by
		analysis_mode DESC
)
select 
	* ,
	round(( total_sales - lead(total_sales,1) over() )::numeric/12,2) rate_of_growth_or_reduction_per_week,
	round(( total_sales - lead(total_sales,1) over() )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
from cte

-- 4. Bonus Question

-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

--     region
with before_after_data as (
	select
		region, sum(sales) total_sales, 'before 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date - '12 weeks'::interval and week_date < '2020-06-15'::date
	group by 
		1
	UNION
	select
		region,sum(sales) total_sales , 'after 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date  and week_date < '2020-06-15'::date  + '12 weeks'::interval
	group by 
		1
	order by
		1 , analysis_mode
)
select 
	bad.* , round(( total_sales - lead(total_sales,1) over(partition by region order by analysis_mode) )::numeric/12,2) rate_of_growth_or_reduction_per_week,
	round(( total_sales - lead(total_sales,1) over(partition by region order by analysis_mode) )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
from
	before_after_data bad
order by
	rate_of_growth_or_reduction_per_week
limit 1

--     platform
with before_after_data as (
	select
		platform, sum(sales) total_sales, 'before 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date - '12 weeks'::interval and week_date < '2020-06-15'::date
	group by 
		1
	UNION
	select
		platform,sum(sales) total_sales , 'after 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date  and week_date < '2020-06-15'::date  + '12 weeks'::interval
	group by 
		1
	order by
		1 , analysis_mode
)
select 
	bad.* , round(( total_sales - lead(total_sales,1) over(partition by platform order by analysis_mode) )::numeric/12,2) rate_of_growth_or_reduction_per_week,
	round(( total_sales - lead(total_sales,1) over(partition by platform order by analysis_mode) )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
from
	before_after_data bad
order by
	rate_of_growth_or_reduction_per_week
limit 1

--     age_band
with before_after_data as (
	select
		age_band, sum(sales) total_sales, 'before 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date - '12 weeks'::interval and week_date < '2020-06-15'::date
	group by 
		1
	UNION
	select
		age_band,sum(sales) total_sales , 'after 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date  and week_date < '2020-06-15'::date  + '12 weeks'::interval
	group by 
		1
	order by
		1 , analysis_mode
)
select 
	bad.* , round(( total_sales - lead(total_sales,1) over(partition by age_band order by analysis_mode) )::numeric/12,2) rate_of_growth_or_reduction_per_week,
	round(( total_sales - lead(total_sales,1) over(partition by age_band order by analysis_mode) )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
from
	before_after_data bad
order by
	rate_of_growth_or_reduction_per_week
limit 1
--     demographic
with before_after_data as (
	select
		demographic, sum(sales) total_sales, 'before 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date - '12 weeks'::interval and week_date < '2020-06-15'::date
	group by 
		1
	UNION
	select
		demographic,sum(sales) total_sales , 'after 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date  and week_date < '2020-06-15'::date  + '12 weeks'::interval
	group by 
		1
	order by
		1 , analysis_mode
)
select 
	bad.* , round(( total_sales - lead(total_sales,1) over(partition by demographic order by analysis_mode) )::numeric/12,2) rate_of_growth_or_reduction_per_week,
	round(( total_sales - lead(total_sales,1) over(partition by demographic order by analysis_mode) )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
from
	before_after_data bad
order by
	rate_of_growth_or_reduction_per_week
limit 1
--     customer_type
with before_after_data as (
	select
		customer_type, sum(sales) total_sales, 'before 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date - '12 weeks'::interval and week_date < '2020-06-15'::date
	group by 
		1
	UNION
	select
		customer_type,sum(sales) total_sales , 'after 12 weeks' analysis_mode
	from 
		data_mart.clean_weekly_sales
	where
		week_date >= '2020-06-15'::date  and week_date < '2020-06-15'::date  + '12 weeks'::interval
	group by 
		1
	order by
		1 , analysis_mode
)
select 
	bad.* , round(( total_sales - lead(total_sales,1) over(partition by customer_type order by analysis_mode) )::numeric/12,2) rate_of_growth_or_reduction_per_week,
	round(( total_sales - lead(total_sales,1) over(partition by customer_type order by analysis_mode) )::numeric*100/lead(total_sales,1) over(),2) rate_of_growth_or_reduction_percentage
from
	before_after_data bad
order by
	rate_of_growth_or_reduction_per_week
limit 1

-- Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
/*
There could be many reasons why retailers not purchasing a product in sustainable packaging.
Package desgin
Customer's lack of awareness for sustaiability
lack of knowledge on operating such packaging

To overcome this,
Danny must use proper labeling to make it look more authentic and attractive
A small description about sustainable packaging and related symbols should be on label/ with label
Symbolic directions on how to get hands on new packing
*/ 