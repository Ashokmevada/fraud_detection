-- ============================================================
-- Q9b: Multi-Signal Fraud Capture Rate
-- Business question: Does combining multiple weak signals
--   improve fraud capture over single-feature ranking?
-- Expected finding: Multi-signal top 10% should capture
--   significantly more fraud than single-feature 26.41%.
--   Demonstrates business value of combining signals.
-- SQL techniques: Chained CTEs, compound scoring expression,
--   PERCENTILE_CONT on computed score, capture rate analysis
-- ============================================================

WITH scored AS (
    -- Step 1: Assign risk score to every transaction
    SELECT
        is_fraud,
        transaction_amount,
        failed_attempts,
        is_international,
        is_night_transaction,
        pin_changed_recently,
        merchant_category,
        -- Compound risk score
        CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
        + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
        + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
        + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
        + CASE WHEN merchant_category IN (
            'ATM Withdrawal', 'Jewelry', 'Crypto Exchange'
          ) THEN 2 ELSE 0 END                           AS risk_score
    FROM transactions
),
threshold AS (
    -- Step 2: Find 90th percentile of risk score
    SELECT
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY risk_score)          AS p90_threshold
    FROM scored
),
classified AS (
    -- Step 3: Classify transactions as flagged or not
    SELECT
        s.is_fraud,
        s.transaction_amount,
        s.risk_score,
        CASE
            WHEN s.risk_score >= th.p90_threshold
            THEN 'Top 10% Flagged'
            ELSE 'Bottom 90% Not Flagged'
        END                                             AS flag_status
    FROM scored s
    CROSS JOIN threshold th
),
summary AS (
    -- Step 4: Aggregate by flag status
    SELECT
        flag_status,
        COUNT(*)                                        AS total_transactions,
        SUM(is_fraud)                                   AS fraud_count,
        COUNT(*) - SUM(is_fraud)                        AS legit_count,
        ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS fraud_rate_pct
    FROM classified
    GROUP BY flag_status
),
overall AS (
    SELECT
        SUM(is_fraud)                                   AS total_fraud,
        COUNT(*)                                        AS total_txns
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
    ROUND(s.fraud_count::NUMERIC
        / o.total_fraud * 100, 2)                       AS pct_of_fraud_captured,
    ROUND((s.fraud_count::NUMERIC / s.total_transactions)
        / (o.total_fraud::NUMERIC / o.total_txns), 2)   AS lift_over_random,
    ROUND(s.legit_count::NUMERIC
        / s.total_transactions * 100, 2)                AS false_positive_rate_pct
FROM summary s
CROSS JOIN overall o
ORDER BY s.fraud_rate_pct DESC;


-- Score distribution — how many transactions at each risk level
SELECT
    CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
    + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
    + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
    + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
    + CASE WHEN merchant_category IN (
        'ATM Withdrawal', 'Jewelry', 'Crypto Exchange'
      ) THEN 2 ELSE 0 END                               AS risk_score,
    COUNT(*)                                            AS total_transactions,
    SUM(is_fraud)                                       AS fraud_count,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)             AS fraud_rate_pct
FROM transactions
GROUP BY risk_score
ORDER BY risk_score DESC;


SELECT
    SUM(CASE WHEN (
        CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
        + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
        + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
        + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
        + CASE WHEN merchant_category IN (
            'ATM Withdrawal','Jewelry','Crypto Exchange'
          ) THEN 2 ELSE 0 END
    ) >= 4 THEN is_fraud ELSE 0 END)                    AS fraud_caught_score4plus,
    COUNT(CASE WHEN (
        CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
        + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
        + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
        + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
        + CASE WHEN merchant_category IN (
            'ATM Withdrawal','Jewelry','Crypto Exchange'
          ) THEN 2 ELSE 0 END
    ) >= 4 THEN 1 END)                                  AS txns_flagged,
    ROUND(SUM(CASE WHEN (
        CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
        + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
        + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
        + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
        + CASE WHEN merchant_category IN (
            'ATM Withdrawal','Jewelry','Crypto Exchange'
          ) THEN 2 ELSE 0 END
    ) >= 4 THEN is_fraud ELSE 0 END)::NUMERIC
        / 55255 * 100, 2)                               AS pct_fraud_captured,
    ROUND(SUM(CASE WHEN (
        CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
        + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
        + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
        + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
        + CASE WHEN merchant_category IN (
            'ATM Withdrawal','Jewelry','Crypto Exchange'
          ) THEN 2 ELSE 0 END
    ) >= 4 THEN is_fraud ELSE 0 END)::NUMERIC
        / NULLIF(COUNT(CASE WHEN (
        CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
        + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
        + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
        + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
        + CASE WHEN merchant_category IN (
            'ATM Withdrawal','Jewelry','Crypto Exchange'
          ) THEN 2 ELSE 0 END
    ) >= 4 THEN 1 END), 0) * 100, 2)                   AS fraud_rate_in_flagged
FROM transactions;

WITH scored AS (
    SELECT
        is_fraud,
        CASE WHEN failed_attempts >= 2 THEN 3 ELSE 0 END
        + CASE WHEN is_international = 1 THEN 2 ELSE 0 END
        + CASE WHEN is_night_transaction = 1 THEN 2 ELSE 0 END
        + CASE WHEN pin_changed_recently = 1 THEN 1 ELSE 0 END
        + CASE WHEN merchant_category IN (
            'ATM Withdrawal', 'Jewelry', 'Crypto Exchange'
          ) THEN 2 ELSE 0 END                           AS risk_score
    FROM transactions
)
SELECT
    'Score 3+' AS threshold,
    COUNT(*) AS txns_flagged,
    ROUND(COUNT(*)::NUMERIC / 1000000 * 100, 2) AS pct_of_dataset,
    SUM(is_fraud) AS fraud_caught,
    ROUND(SUM(is_fraud)::NUMERIC / 55255 * 100, 2) AS pct_fraud_captured,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2) AS fraud_rate_pct
FROM scored WHERE risk_score >= 3
UNION ALL
SELECT
    'Score 4+',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / 1000000 * 100, 2),
    SUM(is_fraud),
    ROUND(SUM(is_fraud)::NUMERIC / 55255 * 100, 2),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)
FROM scored WHERE risk_score >= 4
UNION ALL
SELECT
    'Score 5+',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / 1000000 * 100, 2),
    SUM(is_fraud),
    ROUND(SUM(is_fraud)::NUMERIC / 55255 * 100, 2),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)
FROM scored WHERE risk_score >= 5
UNION ALL
SELECT
    'Score 6+',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / 1000000 * 100, 2),
    SUM(is_fraud),
    ROUND(SUM(is_fraud)::NUMERIC / 55255 * 100, 2),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)
FROM scored WHERE risk_score >= 6
UNION ALL
SELECT
    'Score 7+',
    COUNT(*),
    ROUND(COUNT(*)::NUMERIC / 1000000 * 100, 2),
    SUM(is_fraud),
    ROUND(SUM(is_fraud)::NUMERIC / 55255 * 100, 2),
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)
FROM scored WHERE risk_score >= 7
ORDER BY threshold;



