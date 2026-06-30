-- ============================================================
-- Q5: Payment Method & Device Type Fraud Rate Analysis
-- Business question: Which payment methods and device types
--   are most vulnerable? Is any combination high risk?

-- Part A: Fraud Rate by Payment Method

WITH overall AS (
    SELECT ROUND(AVG(is_fraud::NUMERIC) * 100, 2) AS overall_fraud_rate
    FROM transactions
)
SELECT
    'Payment Method'                                AS analysis_type,
    t.payment_method                                AS category,
    COUNT(*)                                        AS total_transactions,
    SUM(t.is_fraud)                                 AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)       AS fraud_rate_pct,
    o.overall_fraud_rate,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)
        - o.overall_fraud_rate                      AS diff_from_avg_pp
FROM transactions t
CROSS JOIN overall o
GROUP BY t.payment_method, o.overall_fraud_rate
UNION ALL
-- Part B: Fraud Rate by Device Type
SELECT
    'Device Type'                                   AS analysis_type,
    t.device_type                                   AS category,
    COUNT(*)                                        AS total_transactions,
    SUM(t.is_fraud)                                 AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)       AS fraud_rate_pct,
    o.overall_fraud_rate,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)
        - o.overall_fraud_rate                      AS diff_from_avg_pp
FROM transactions t
CROSS JOIN overall o
GROUP BY t.device_type, o.overall_fraud_rate
ORDER BY analysis_type, fraud_rate_pct DESC;

-- Part C: High Risk Combination Check — Mobile + Crypto
WITH overall AS (
    SELECT ROUND(AVG(is_fraud::NUMERIC) * 100, 2) AS overall_fraud_rate
    FROM transactions
)
SELECT
    t.payment_method,
    t.device_type,
    COUNT(*)                                        AS total_transactions,
    SUM(t.is_fraud)                                 AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)       AS fraud_rate_pct,
    o.overall_fraud_rate,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)
        - o.overall_fraud_rate                      AS diff_from_avg_pp
FROM transactions t
CROSS JOIN overall o
GROUP BY t.payment_method, t.device_type, o.overall_fraud_rate
ORDER BY fraud_rate_pct DESC
LIMIT 10;