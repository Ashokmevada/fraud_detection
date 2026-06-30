-- ============================================================
-- Q9: Top 10% Fraud Capture Rate Analysis
-- Business question: If top 10% riskiest transactions are
--   flagged using failed_attempts, what % of fraud is caught?
-- Expected finding: Top 10% (failed_attempts >= 2) captures
--   26.41% of fraud — 2.64x lift over random selection.
--   73.59% of fraud remains undetected — confirms single
--   features are insufficient, supervised learning required.
-- SQL techniques: PERCENTILE_CONT for quantile threshold,
--   chained CTEs, capture rate and lift calculation
-- ============================================================

WITH threshold AS (
    -- Step 1: Compute the 90th percentile threshold
    SELECT
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY failed_attempts)     AS p90_threshold
    FROM transactions
),
classified AS (
    -- Step 2: Classify every transaction as top 10% or not
    SELECT
        t.is_fraud,
        t.failed_attempts,
        t.transaction_amount,
        CASE
            WHEN t.failed_attempts >= th.p90_threshold
            THEN 'Top 10% Flagged'
            ELSE 'Bottom 90% Not Flagged'
        END                                             AS flag_status
    FROM transactions t
    CROSS JOIN threshold th
),
summary AS (
    -- Step 3: Aggregate by flag status
    SELECT
        flag_status,
        COUNT(*)                                        AS total_transactions,
        SUM(is_fraud)                                   AS fraud_count,
        COUNT(*) - SUM(is_fraud)                        AS legit_count,
        ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS fraud_rate_pct,
        ROUND(SUM(transaction_amount), 2)               AS total_transaction_value
    FROM classified
    GROUP BY flag_status
),
overall AS (
    -- Step 4: Overall totals for capture rate calculation
    SELECT
        SUM(is_fraud)                                   AS total_fraud,
        COUNT(*)                                        AS total_txns,
        SUM(transaction_amount)                         AS total_value
    FROM transactions
)
SELECT
    s.flag_status,
    s.total_transactions,
    ROUND(s.total_transactions::NUMERIC
        / o.total_txns * 100, 2)                        AS pct_of_all_transactions,
    s.fraud_count,
    s.legit_count,
    s.fraud_rate_pct,
    -- % of all fraud captured in this segment
    ROUND(s.fraud_count::NUMERIC
        / o.total_fraud * 100, 2)                       AS pct_of_fraud_captured,
    -- Lift over random selection
    ROUND((s.fraud_count::NUMERIC / s.total_transactions)
        / (o.total_fraud::NUMERIC / o.total_txns), 2)   AS lift_over_random,
    -- False positive rate
    ROUND(s.legit_count::NUMERIC
        / s.total_transactions * 100, 2)                AS false_positive_rate_pct
FROM summary s
CROSS JOIN overall o
ORDER BY s.fraud_rate_pct DESC;