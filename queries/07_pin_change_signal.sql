-- ============================================================
-- Q7: PIN Change Signal Analysis
-- Business question: Does recent PIN change signal account
--   takeover fraud? Is it viable as a standalone rule?


WITH overall AS (
    SELECT
        COUNT(*)                                        AS total_txns,
        SUM(is_fraud)                                   AS total_fraud,
        ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS overall_fraud_rate
    FROM transactions
)
SELECT
    t.pin_changed_recently,
    CASE
        WHEN t.pin_changed_recently = 1 THEN 'PIN Changed Recently'
        ELSE 'No PIN Change'
    END                                                 AS segment_label,
    COUNT(*)                                            AS total_transactions,
    SUM(t.is_fraud)                                     AS fraud_count,
    COUNT(*) - SUM(t.is_fraud)                          AS legit_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)           AS fraud_rate_pct,
    o.overall_fraud_rate,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)
        - o.overall_fraud_rate                          AS diff_from_avg_pp,
    -- Relative lift: how much does PIN change multiply fraud rate
    ROUND(
        AVG(t.is_fraud::NUMERIC)
        / (o.overall_fraud_rate / 100), 2
    )                                                   AS relative_lift_x,
    -- Rule precision: of flagged transactions, what % is fraud
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)           AS rule_precision_pct,
    -- Rule recall: of all fraud, what % does this rule catch
    ROUND(
        SUM(t.is_fraud)::NUMERIC
        / o.total_fraud * 100, 2
    )                                                   AS rule_recall_pct,
    -- Legitimate customers blocked per fraud caught
    ROUND(
        (COUNT(*) - SUM(t.is_fraud))::NUMERIC
        / NULLIF(SUM(t.is_fraud), 0), 1
    )                                                   AS legit_blocked_per_fraud_caught
FROM transactions t
CROSS JOIN overall o
GROUP BY t.pin_changed_recently, o.overall_fraud_rate, o.total_fraud, o.total_txns
ORDER BY t.pin_changed_recently DESC;