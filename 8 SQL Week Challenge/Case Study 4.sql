/* 
	Case Study 4
*/

-- A. Customer Nodes Exploration

-- How many unique nodes are there on the Data Bank system?
with cte as (
	select region_id || '->' || node_id region_node_group from data_bank.customer_nodes
)
select count(distinct region_node_group) unique_nodes_around_globe from cte

-- What is the number of nodes per region?
select region_id , count(distinct node_id) 
from data_bank.customer_nodes 
group by region_id


-- How many customers are allocated to each region?
select region_id , count(distinct customer_id) 
from data_bank.customer_nodes 
group by region_id

-- How many days on average are customers reallocated to a different node?
select round(avg(end_date-start_date+1),0) avg_days_per_node from data_bank.customer_nodes where end_date <> '9999-12-31' 

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with cte as (
	select 
		end_date-start_date+1 days_per_node 
	from 
		data_bank.customer_nodes 
	where 
		end_date <> '9999-12-31'
)
select 
	percentile_cont(0.5) within group (order by days_per_node) median,
	percentile_cont(0.8) within group (order by days_per_node) "80th percentile" ,
	percentile_cont(0.95) within group (order by days_per_node ) "95th percentile"
from
	cte



-- B. Customer Transactions

-- What is the unique count and total amount for each transaction type?
select 
	txn_type, count(distinct txn_date) total_txn_counts , sum(txn_amount) total_txn_amount
from
	data_bank.customer_transactions
group by
	txn_type

-- What is the average total historical deposit counts and amounts for all customers?
select 
	customer_id , count(*) historical_deposits , sum(txn_amount) total_amount_deposited
from
	data_bank.customer_transactions
where
	txn_type = 'deposit'
group by
	customer_id
	

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with calculated_cte as( 
select
	customer_id,
	date_trunc('month',txn_date)::date as month ,
	sum(case txn_type when 'deposit' then 1 else 0 end) deposit_count,
	sum(case txn_type when 'purchase' then 1 when 'withdrawal' then 1 else 0 end)  purchase_or_withdrawal_count
from
	data_bank.customer_transactions
group by 1,2
)
select 
	month, count(*)
from 
	calculated_cte 
where 
	deposit_count > 1 and purchase_or_withdrawal_count > 0
group by month
order by 1;

-- What is the closing balance for each customer at the end of the month?
with monthly_balance_sheet as (
select 
	customer_id , date_trunc('month',txn_date)::date month_end, sum(case txn_type when 'deposit' then txn_amount else txn_amount*(-1) end) monthly_balance
from
	data_bank.customer_transactions
group by
	1 ,2
order by 
	1,2
)
select 
	customer_id , month_end ,
	coalesce(lag(monthly_balance,1) over(partition by customer_id),0) + monthly_balance closing_balance
from
	monthly_balance_sheet;

-- What is the percentage of customers who increase their closing balance by more than 5%?
with monthly_balance_sheet as (
	select 
		customer_id , date_trunc('month',txn_date)::date month_end, sum(case txn_type when 'deposit' then txn_amount else txn_amount*(-1) end) monthly_balance
	from
		data_bank.customer_transactions
	group by
		1 ,2
	order by 
		1,2
)
,with_closing_balance as (
	select 
		customer_id , month_end ,
		(coalesce(lag(monthly_balance,1) over(partition by customer_id),0) + monthly_balance) closing_balance
	from
		monthly_balance_sheet
),
with_percent_incr_closing_bal as (
select 
	customer_id , month_end,
	case
		when lag(closing_balance,1) over(partition by customer_id) = 0 then null
		when closing_balance < 0 and lag(closing_balance,1) over(partition by customer_id)<0 
			then -100*(lag(closing_balance,1) over(partition by customer_id) - closing_balance) / lag(closing_balance,1) over(partition by customer_id)
		else
			100*(closing_balance - lag(closing_balance,1) over(partition by customer_id)) / lag(closing_balance,1) over(partition by customer_id)
			
	end "% increase in closing_balance"
from 
	with_closing_balance
)

select 
	month_end,
	round(sum( case when "% increase in closing_balance" > 5 then 1 else 0 end)*100.0/count(*),2)
	"% of customers who increase their closing_balance by 5%"
from 
	with_percent_incr_closing_bal
group by
	month_end
order by
	month_end
	

	
-- C. Data Allocation Challenge

-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers
-- would be allocated data using 3 different options:

--     Option 1: data is allocated based off the amount of money at the end of the previous month
--     Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--     Option 3: data is updated real-time

-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

--     running customer balance column that includes the impact of each transaction
--     customer balance at the end of each month
--     minimum, average and maximum values of the running balance for each customer

-- Using all of the data available - how much data would have been required for each option on a monthly basis?

select 
	* 
from
	data_bank.customer_transactions

--     running customer balance column that includes the impact of each transaction	
select 
	*,
	 sum( 
		case txn_type 
			when 'deposit' 
			then txn_amount 
			else txn_amount*-1 
		end
	 ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) running_customer_balance
from
	data_bank.customer_transactions

--     customer balance at the end of each month
with monthly_balance_sheet as (
	select 
		customer_id , date_trunc('month',txn_date)::date month_end, sum(case txn_type when 'deposit' then txn_amount else txn_amount*(-1) end) monthly_balance
	from
		data_bank.customer_transactions
	group by
		1 ,2
	order by 
		1,2
)
select 
	customer_id , month_end ,
	coalesce(lag(monthly_balance,1) over(partition by customer_id),0) + monthly_balance closing_balance
from
	monthly_balance_sheet;
	

--     minimum, average and maximum values of the running balance for each customer
with with_running_balance as (
	select 
		*,
		 sum( 
			case txn_type 
				when 'deposit' 
				then txn_amount 
				else txn_amount*-1 
			end
		 ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) running_balance
	from
		data_bank.customer_transactions
)
select 
	customer_id ,
	date_trunc('month',txn_date)::date month_end,
	min(running_balance) minimum,
	round(avg(running_balance),2) average,
	max(running_balance) maximum
from 
	with_running_balance
group by
	1,2
order by 1,2


-- Option 1 : data is allocated based off the amount of money at the end of the previous month
with monthly_balance_sheet as (
	select 
		customer_id , date_trunc('month',txn_date)::date month_end, sum(case txn_type when 'deposit' then txn_amount else txn_amount*(-1) end) monthly_balance
	from
		data_bank.customer_transactions
	group by
		1 ,2
	order by 
		1,2
)
, closing_bal as (
select 
	customer_id , month_end ,
	coalesce(lag(monthly_balance,1) over(partition by customer_id),0) + monthly_balance closing_balance
from
	monthly_balance_sheet
)
select month_end, sum(closing_balance) data_required_for_option_1
from closing_bal
group by month_end


-- Option 2 : data is allocated on the average amount of money kept in the account in the previous 30 days
with running_bal as (
select 
	*,
	 sum( 
		case txn_type 
			when 'deposit' 
			then txn_amount 
			else txn_amount*-1 
		end
	 ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) running_customer_balance
from
	data_bank.customer_transactions
)
,
average_money_prev_30_days as (
select 
	* ,
	avg(running_customer_balance) over(partition by customer_id order by txn_date rows 30 preceding ) 
	from running_bal
)
select 
	date_trunc('month',txn_date)::date month_end , round(sum(avg),2)
from
	average_money_prev_30_days
group by
	1

-- Option 3: data is updated real-time
with real_time_balance as (
select 
	txn_date,
	 sum( 
		case txn_type 
			when 'deposit' 
			then txn_amount 
			else txn_amount*-1 
		end
	 ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) running_customer_balance
from
	data_bank.customer_transactions
)
select 
	date_trunc('month',txn_date)::date , sum(running_customer_balance) 
from
	real_time_balance
group by 1




-- D. Extra Challenge


-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

-- Special notes:

--     Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
with day_wise_txns as (
	select 
		customer_id,txn_date,
		 sum( 
			case txn_type 
				when 'deposit' 
				then txn_amount 
				else txn_amount*-1 
			end
		 )  whole_day_txn
	from
		data_bank.customer_transactions
	group by 
		customer_id, txn_date
	order by customer_id
)
, daily_running_balance as (
	select 
		*,
		 sum( 
			whole_day_txn
		 ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) running_balance
	from
		day_wise_txns
)
select 
	date_trunc('month',txn_date)::date , sum((6.0/365)*running_balance) monthly_earned_data
from daily_running_balance
group by 1

-- Compounded Interest
with day_wise_txns_compounded as (
	select 
		customer_id,txn_date,
		 sum( 
			case txn_type 
				when 'deposit' 
				then (txn_amount * (1+(6.0/365))
				else (txn_amount*(1+(6.0/365)*-1 )
			end
		 )  whole_day_txn
	from
		data_bank.customer_transactions
	group by 
		customer_id, txn_date
	order by customer_id
)

-- Extension Request

-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

--     Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

--     With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.