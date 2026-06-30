-- Q1: Fraud Rate by Merchant Category
-- Business question: Which merchant categories have the highest
--   fraud rates and how far above average are they?

with overall as (
	select round(avg(is_fraud :: NUMERIC)*100,2) as overall_fraud_rate from transactions
)
select t.merchant_category,
	count(*) as total_transactions,
	sum(t.is_fraud) as fraud_count,
	round(avg(t.is_fraud :: NUMERIC)*100,2) as fraud_rate_pct,
	o.overall_fraud_rate,
	round(avg(t.is_fraud::NUMERIC)*100,2) - o.overall_fraud_rate as diff_from_avg_pp
from transactions t
cross join overall o
group by t.merchant_category , o.overall_fraud_rate
order by fraud_rate_pct Desc;

