                             

     
##1.Get the time range between which the orders were placed.
      select 
      date_diff(max(order_purchase_timestamp),min(order_purchase_timestamp),day) as days_difference
from `usa_retail_store.orders`

##2.Count the Cities & States of customers who ordered during the given period.
     select count(distinct(customer_city)) as city,
       count(distinct(customer_state)) as state
from `usa_retail_store.customers`

##3.Is there a growing trend in the no. of orders placed over the past years?
       select extract(year from order_purchase_timestamp) as years,
       count(order_id) as total_orders
from `usa_retail_store.orders`
group by extract(year from order_purchase_timestamp)
order by years asc 
;

##4.Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
       select format_date('%B',order_purchase_timestamp) as months,
      count(order_id) as total_orders
from `usa_retail_store.orders`
group by months, extract(month from order_purchase_timestamp)
order by  extract(month from order_purchase_timestamp)

##5.During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
##0-6 hrs : Dawn
##7-12 hrs : Mornings
##13-18 hrs : Afternoon
##19-23 hrs : Night
      select case 
    when extract(hour from order_purchase_timestamp) between 0 and 6 then 'Dawn'
    when extract(hour from order_purchase_timestamp) between 7 and 12 then 'Morning'
    when extract(hour from order_purchase_timestamp) between 13 and 18  then 'Afternoon'
    else 'Night'
    end as time_of_the_day,
  
  count(order_id) as total_orders
from `usa_retail_store.orders`
group by time_of_the_day
order by total_orders desc
;

##6.Get the month on month no. of orders placed in each state.
        select format_date('%B',order_purchase_timestamp) as months,c.customer_state,
      count(o.order_id) as total_orders
from `usa_retail_store.orders` o join `usa_retail_store.customers` c
on o.customer_id = c.customer_id
group by months,customer_state
order by  total_orders desc 
;

##7.How are the customers distributed across all the states?
        select customer_state,
      count(customer_id) as total_customers
from `usa_retail_store.customers`
group by customer_state
order by total_customers desc
;

##8.Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).You can use the "payment_value" column in the payments table to get the cost of orders.
      with year_ as
 (
    select extract(YEAR FROM o.order_purchase_timestamp) AS year,
        sum(p.payment_value) AS total_value
    from `usa_retail_store.orders` o join `usa_retail_store.payments` p
      on o.order_id = p.order_id
    where extract(month from o.order_purchase_timestamp) between 1 and 8
    group by year
)

select
    round(( max(case when year = 2018 then total_value end)- max(case when year = 2017 then total_value end))
    / max(case when year = 2017 then total_value end) * 100,
        2
    ) as pct_growth
from year_
;
       
##9.Calculate the Total & Average value of order price for each state.
      select c.customer_state,
      round(sum(oi.price),2) as total_price,
      round(avg(oi.price),2) as avg_price
from `usa_retail_store.order_items` oi join `usa_retail_store.orders` o
on oi.order_id = o.order_id
join `usa_retail_store.customers` c
on o.customer_id = c.customer_id
group by c.customer_state
order by customer_state asc
;

##10.Calculate the Total & Average value of order freight for each state.
     select c.customer_state,
      round(sum(oi.freight_value),2) as total_price,
      round(avg(oi.freight_value),2) as avg_price
from `usa_retail_store.order_items` oi join `usa_retail_store.orders` o
on oi.order_id = o.order_id
join `usa_retail_store.customers` c
on o.customer_id = c.customer_id
group by c.customer_state
order by customer_state asc
;


##11.Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.Also, calculate the difference (in days) between the estimated & actual delivery date of an order.Do this in a single query.You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
##time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
##diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date.
        select order_id,
        date_diff(order_delivered_customer_date,order_purchase_timestamp,day) as time_to_deliver,
        date_diff(order_delivered_customer_date,order_estimated_delivery_date,day) as diff_estimated_delivery
from `usa_retail_store.orders`
where order_status = 'Delivered'
;

##12.Find out the top 5 states with the lowest & highest average freight value.
       with highest_freight_states as
(
  select  c.customer_state,
        round(avg(oi.freight_value),2) as avg_freight_value,
        dense_rank() over(order by avg(oi.freight_value) desc) as rnk_1
from `usa_retail_store.order_items` oi join `usa_retail_store.orders` o
on oi.order_id = o.order_id
join `usa_retail_store.customers` c 
on o.customer_id = c.customer_id
group by c.customer_state
),

 lowest_freight_states as
(
  select c.customer_state,
      round(avg(oi.freight_value),2) as avg_freight_value,
      dense_rank() over(order by avg(oi.freight_value) asc) as rnk_2
  from `usa_retail_store.order_items` oi join `usa_retail_store.orders` o
  on oi.order_id = o.order_id
  join `usa_retail_store.customers` c
  on o.customer_id = c.customer_id
  group by c.customer_state
)
select lowest_freight_states.customer_state as low_value_states,
       lowest_freight_states.avg_freight_value as top_5_lowest,
       highest_freight_states.customer_state as high_value_states,
       highest_freight_states.avg_freight_value as top_5_highest
from highest_freight_states,lowest_freight_states
where rnk_1 = rnk_2
limit 5 
;

##13.Find out the top 5 states with the highest & lowest average delivery time.
    with t1 as 
(
select c.customer_state,
       avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day)) as avg_delivery_time,
       dense_rank() over(order by avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day)) desc) as rank_1
from `usa_retail_store.orders` o join `usa_retail_store.order_items` oi
on o.order_id = oi.order_id
join `usa_retail_store.customers` c
on o.customer_id = c.customer_id
group by c.customer_state
),

t2 as (
  select c.customer_state,
       avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day)) as avg_delivery_time,
       dense_rank() over(order by avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,day)) asc) as rank_2
from `usa_retail_store.orders` o join `usa_retail_store.order_items` oi
on o.order_id = oi.order_id
join `usa_retail_store.customers` c
on o.customer_id = c.customer_id
group by c.customer_state
) 

select t1.customer_state as top_5_highest_states,
       round(t1.avg_delivery_time,2) as highest_avg_delivery_time,
       t2.customer_state as top_5_lowest_states,
       round(t2.avg_delivery_time,2) as lowest_avg_delivery_time
from t1,t2
where rank_1 = rank_2
limit 5
;

##14.Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.
    with avg_days_taken as
(
  select c.customer_state,
       avg(date_diff(o.order_delivered_customer_date,order_estimated_delivery_date,day)) as days_taken,
from `usa_retail_store.orders` o join  `usa_retail_store.customers` c
on o.customer_id = c.customer_id
group by c.customer_state
)

select customer_state,
      round(days_taken,2) as avg_days_diff
from avg_days_taken
order by avg_days_diff asc
limit 5
;
##15.Find the month on month no. of orders placed using different payment types.
       select format_date('%B',order_purchase_timestamp) as months,p.payment_type,
     count(p.order_id) as total_orders
from `usa_retail_store.payments` p join `usa_retail_store.orders` o
on p.order_id = o.order_id
group by months, payment_type
order by total_orders desc
;

##16.Find the no. of orders placed on the basis of the payment installments that have been paid.
       select payment_installments,
       count(order_id) as total_orders
from `usa_retail_store.payments` 
group by payment_installments
order by payment_installments asc
;


