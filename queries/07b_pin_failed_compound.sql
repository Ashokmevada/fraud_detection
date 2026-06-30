-- ============================================================
-- Compound Signal: PIN Changed Recently AND Failed Attempts >= 2
-- Business question: Does combining PIN change with failed
--   attempts produce a stronger fraud signal than either alone?
-- Expected finding: Fraud rate significantly higher than both
--   standalone signals — classic account takeover profile.
-- SQL techniques: Multiple WHERE conditions, comparison across
--   three populations (standalone vs compound)
-- ============================================================

WITH overall AS (
    SELECT
        COUNT(*)                                    AS total_txns,
        SUM(is_fraud)                               AS total_fraud
    FROM transactions
)
SELECT
    'PIN Change Only'                               AS segment,
    COUNT(*)                                        AS total_transactions,
    SUM(t.is_fraud)                                 AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)       AS fraud_rate_pct,
    ROUND(SUM(t.is_fraud)::NUMERIC
        / o.total_fraud * 100, 2)                   AS pct_of_all_fraud,
    ROUND((COUNT(*) - SUM(t.is_fraud))::NUMERIC
        / NULLIF(SUM(t.is_fraud), 0), 1)            AS legit_per_fraud_caught
FROM transactions t
CROSS JOIN overall o
WHERE t.pin_changed_recently = 1
  AND t.failed_attempts < 2
GROUP BY o.total_fraud

UNION ALL

SELECT
    'Failed Attempts >= 2 Only'                     AS segment,
    COUNT(*)                                        AS total_transactions,
    SUM(t.is_fraud)                                 AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)       AS fraud_rate_pct,
    ROUND(SUM(t.is_fraud)::NUMERIC
        / o.total_fraud * 100, 2)                   AS pct_of_all_fraud,
    ROUND((COUNT(*) - SUM(t.is_fraud))::NUMERIC
        / NULLIF(SUM(t.is_fraud), 0), 1)            AS legit_per_fraud_caught
FROM transactions t
CROSS JOIN overall o
WHERE t.failed_attempts >= 2
  AND t.pin_changed_recently = 0
GROUP BY o.total_fraud

UNION ALL

SELECT
    'BOTH: PIN Change + Failed >= 2'                AS segment,
    COUNT(*)                                        AS total_transactions,
    SUM(t.is_fraud)                                 AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)       AS fraud_rate_pct,
    ROUND(SUM(t.is_fraud)::NUMERIC
        / o.total_fraud * 100, 2)                   AS pct_of_all_fraud,
    ROUND((COUNT(*) - SUM(t.is_fraud))::NUMERIC
        / NULLIF(SUM(t.is_fraud), 0), 1)            AS legit_per_fraud_caught
FROM transactions t
CROSS JOIN overall o
WHERE t.pin_changed_recently = 1
  AND t.failed_attempts >= 2
GROUP BY o.total_fraud

ORDER BY fraud_rate_pct DESC;