-- ============================================================
-- Q6: Failed Attempts Threshold Analysis
-- Business question: How many failed attempts precede fraud?
--   What threshold should trigger automatic review?


WITH attempt_stats AS (
    SELECT
        failed_attempts,
        COUNT(*)                                        AS total_transactions,
        SUM(is_fraud)                                   AS fraud_count,
        COUNT(*) - SUM(is_fraud)                        AS legit_count,
        ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS fraud_rate_pct
    FROM transactions
    GROUP BY failed_attempts
),
with_changes AS (
    SELECT
        failed_attempts,
        total_transactions,
        fraud_count,
        legit_count,
        fraud_rate_pct,
        -- Change from previous threshold level
        ROUND(
            fraud_rate_pct - LAG(fraud_rate_pct)
                OVER (ORDER BY failed_attempts), 2
        )                                               AS rate_change_pp,
        -- Fraud captured if flagging at this threshold and above
        SUM(fraud_count)
            OVER (ORDER BY failed_attempts
                  ROWS BETWEEN CURRENT ROW
                  AND UNBOUNDED FOLLOWING)              AS fraud_captured_at_threshold,
        -- Transactions flagged if flagging at this threshold and above
        SUM(total_transactions)
            OVER (ORDER BY failed_attempts
                  ROWS BETWEEN CURRENT ROW
                  AND UNBOUNDED FOLLOWING)              AS txns_flagged_at_threshold,
        -- Legitimate customers blocked at this threshold and above
        SUM(legit_count)
            OVER (ORDER BY failed_attempts
                  ROWS BETWEEN CURRENT ROW
                  AND UNBOUNDED FOLLOWING)              AS legit_blocked_at_threshold
    FROM attempt_stats
)
SELECT
    failed_attempts,
    total_transactions,
    fraud_count,
    fraud_rate_pct,
    COALESCE(rate_change_pp, 0)                         AS rate_change_pp,
    fraud_captured_at_threshold,
    txns_flagged_at_threshold,
    -- % of all fraud captured at this threshold
    ROUND(
        fraud_captured_at_threshold::NUMERIC
        / 55255 * 100, 2
    )                                                   AS pct_fraud_captured,
    -- False positive rate at this threshold
    ROUND(
        legit_blocked_at_threshold::NUMERIC
        / txns_flagged_at_threshold * 100, 2
    )                                                   AS false_positive_rate_pct
FROM with_changes
ORDER BY failed_attempts;