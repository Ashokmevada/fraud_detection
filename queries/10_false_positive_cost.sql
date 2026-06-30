-- ============================================================
-- Q10: False Positive Cost of Blanket Rules
-- Business question: What is the operational cost of each
--   standalone fraud rule in terms of legitimate customers
--   blocked per fraud caught?
-- Expected finding: Every rule has 85-92% false positive rate.
--   Best rule (failed_attempts >= 2): 85.41% FP rate.
--   Night transaction rule flags 37.5% of all transactions
--   with 92% being legitimate.
--   Confirms supervised learning required over rule-based.
-- SQL techniques: UNION ALL for stacked rule comparison,
--   FILTER clause for conditional aggregation, precision
--   and recall calculation across multiple rules
-- ============================================================

WITH overall AS (
    SELECT
        SUM(is_fraud)                                   AS total_fraud,
        COUNT(*)                                        AS total_txns
    FROM transactions
)
-- Rule 1: Failed Attempts >= 2
SELECT
    'Rule 1: failed_attempts >= 2'                      AS rule_name,
    COUNT(*)                                            AS txns_flagged,
    ROUND(COUNT(*)::NUMERIC
        / o.total_txns * 100, 2)                        AS pct_of_all_txns,
    COUNT(*) FILTER (WHERE is_fraud = 1)                AS fraud_caught,
    COUNT(*) FILTER (WHERE is_fraud = 0)                AS legit_blocked,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)             AS fraud_rate_in_flagged,
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 1)::NUMERIC
        / o.total_fraud * 100, 2)                       AS recall_pct,
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / COUNT(*) * 100, 2)                            AS false_positive_rate_pct,
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE is_fraud = 1), 0), 1)
                                                        AS legit_blocked_per_fraud
FROM transactions
CROSS JOIN overall o
WHERE failed_attempts >= 2
GROUP BY o.total_fraud, o.total_txns

UNION ALL

-- Rule 2: Night Transaction
SELECT
    'Rule 2: is_night_transaction = 1',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / o.total_txns * 100, 2),
    COUNT(*) FILTER (WHERE is_fraud = 1),
    COUNT(*) FILTER (WHERE is_fraud = 0),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 1)::NUMERIC
        / o.total_fraud * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / COUNT(*) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE is_fraud = 1), 0), 1)
FROM transactions
CROSS JOIN overall o
WHERE is_night_transaction = 1
GROUP BY o.total_fraud, o.total_txns

UNION ALL

-- Rule 3: International Transaction
SELECT
    'Rule 3: is_international = 1',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / o.total_txns * 100, 2),
    COUNT(*) FILTER (WHERE is_fraud = 1),
    COUNT(*) FILTER (WHERE is_fraud = 0),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 1)::NUMERIC
        / o.total_fraud * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / COUNT(*) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE is_fraud = 1), 0), 1)
FROM transactions
CROSS JOIN overall o
WHERE is_international = 1
GROUP BY o.total_fraud, o.total_txns

UNION ALL

-- Rule 4: PIN Changed Recently
SELECT
    'Rule 4: pin_changed_recently = 1',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / o.total_txns * 100, 2),
    COUNT(*) FILTER (WHERE is_fraud = 1),
    COUNT(*) FILTER (WHERE is_fraud = 0),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 1)::NUMERIC
        / o.total_fraud * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / COUNT(*) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE is_fraud = 1), 0), 1)
FROM transactions
CROSS JOIN overall o
WHERE pin_changed_recently = 1
GROUP BY o.total_fraud, o.total_txns

UNION ALL

-- Rule 5: Night AND International Combined
SELECT
    'Rule 5: night AND international',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / o.total_txns * 100, 2),
    COUNT(*) FILTER (WHERE is_fraud = 1),
    COUNT(*) FILTER (WHERE is_fraud = 0),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 1)::NUMERIC
        / o.total_fraud * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / COUNT(*) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE is_fraud = 1), 0), 1)
FROM transactions
CROSS JOIN overall o
WHERE is_night_transaction = 1
  AND is_international = 1
GROUP BY o.total_fraud, o.total_txns

UNION ALL

-- Rule 6: High Risk Merchant Categories
SELECT
    'Rule 6: ATM/Jewelry/Crypto merchant',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / o.total_txns * 100, 2),
    COUNT(*) FILTER (WHERE is_fraud = 1),
    COUNT(*) FILTER (WHERE is_fraud = 0),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 1)::NUMERIC
        / o.total_fraud * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / COUNT(*) * 100, 2),
    ROUND(COUNT(*) FILTER (WHERE is_fraud = 0)::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE is_fraud = 1), 0), 1)
FROM transactions
CROSS JOIN overall o
WHERE merchant_category IN (
    'ATM Withdrawal', 'Jewelry', 'Crypto Exchange'
)
GROUP BY o.total_fraud, o.total_txns

ORDER BY false_positive_rate_pct ASC;