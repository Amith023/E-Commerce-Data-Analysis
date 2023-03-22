CREATE database ecommerce;
USE ecommerce;

--- Inspecting Data
SELECT * from sales_data;

--- Checking unique values
SELECT distinct status from sales_data; ---Nice one to plot
SELECT distinct year_id from sales_data;
SELECT distinct productline from sales_data; ---Nice to plot
SELECT distinct country from sales_data; ---Nice to plot
SELECT distinct dealsize from sales_data; ---Nice to plot
SELECT distinct territory from sales_data; ---Nice to plot


--- ANALYSIS
--- Let's start by grouping sales by productline;
SELECT productline, sum(sales) revenue
from sales_data group by productline
order by 2 desc;


SELECT year_id, sum(sales) revenue
from sales_data group by year_id
order by 2 desc;

--Now if you see sales in 2005 is less than half the sales of 2004;
--Looking close you would find that, the company has only operated 
--for 5 months in that year;

SELECT distinct month_id from sales_data where year_id=2005;



SELECT dealsize, sum(sales) revenue
from sales_data group by dealsize
order by 2 desc;


--- What was the best month for sales in a specific year? How much was earned that month?
SELECT month_id, sum(sales) revenue, count(ordernumber) Frequency
from sales_data
where year_id=2003 
group by month_id 
order by 2 desc;


--- November seems to be the month, what product do you sell in November, Classic I belive
SELECT month_id, productline, sum(sales) Revenue, count(ordernumber)
from sales_data
where year_id=2003 and month_id=11
group by month_id, productline
order by 3 desc


SELECT * from sales_data;

---- Who is our best customer (this could be best answered with RFM)

SELECT year_id, customername, sum(sales) Revenue, count(ordernumber)
from sales_data
where year_id=2003
group by year_id, customername
order by 3 desc
DATEDIFF(millisecond


--- Who is our best customer (this could be best answered with RFM)
drop table if exists #rfm;
with rfm as
(
	select 
		customername, 
		sum(sales) MonetoryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from sales_data) max_order_date,
		DATEDIFF(DD,max(ORDERDATE),(select max(ORDERDATE) from sales_data)) Recency
	from sales_data
	group by CUSTOMERNAME
),
rfm_calc as 
(
	select r.*,
		NTILE(4) over (order by Recency desc) rfm_recency,--- In all these three entiles, the bucket value with highest
		NTILE(4) over (order by Frequency) rfm_frequency, --- value would be the best in each of these 3 columns.
		NTILE(4) over (order by AvgMonetaryValue) rfm_monetary
	from rfm r
)

	select *,
		rfm_recency+rfm_frequency+rfm_monetary rfm_cell,
		cast(rfm_recency as varchar)+cast(rfm_frequency as varchar)+cast(rfm_monetary as varchar) rfm_cell_string
	into #rfm
	from rfm_calc c;



select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112, 121, 122, 132, 211, 212, 114, 141) then 'lost_customer' ---lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' ---(Big spenders who haven't purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new_customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333 ,321, 422, 332, 432) then 'active' ---(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm;




--- What products are most often sold together;



select distinct ordernumber, stuff(
(select ',' + PRODUCTCODE
from sales_data p
where ORDERNUMBER in
	(
	select ORDERNUMBER
	from (
		select ORDERNUMBER, count(*) rn
		from sales_data
		where status='shipped'
		group by ORDERNUMBER
	) m
	where rn=3
	) 
	and p.ORDERNUMBER=s.ORDERNUMBER
	for xml path (''))
	,1,1,'') ProductCodes

from sales_data s
order by 2 desc
