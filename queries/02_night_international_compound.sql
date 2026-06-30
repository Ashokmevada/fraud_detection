-- ============================================================
-- Q2: Night × International Compound Risk Analysis
-- Business question: Do night and international transactions
--   compound fraud risk super-additively or just additively?


WITH overall AS (
    SELECT
        ROUND(AVG(is_fraud::NUMERIC) * 100, 2) AS overall_rate,
        ROUND(AVG(CASE WHEN is_night_transaction = 1
                       THEN is_fraud::NUMERIC END) * 100, 2) AS night_rate,
        ROUND(AVG(CASE WHEN is_international = 1
                       THEN is_fraud::NUMERIC END) * 100, 2) AS intl_rate
    FROM transactions
)
SELECT
    CASE
        WHEN t.is_night_transaction = 0 AND t.is_international = 0
            THEN 'Day + Domestic'
        WHEN t.is_night_transaction = 0 AND t.is_international = 1
            THEN 'Day + International'
        WHEN t.is_night_transaction = 1 AND t.is_international = 0
            THEN 'Night + Domestic'
        WHEN t.is_night_transaction = 1 AND t.is_international = 1
            THEN 'Night + International'
    END                                                     AS segment,
    COUNT(*)                                                AS total_transactions,
    SUM(t.is_fraud)                                         AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)               AS fraud_rate_pct,
    o.overall_rate,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)
        - o.overall_rate                                    AS diff_from_avg_pp,
    ROUND(o.night_rate + o.intl_rate - o.overall_rate, 2)  AS additive_expectation,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)
        - ROUND(o.night_rate + o.intl_rate
        - o.overall_rate, 2)                               AS actual_vs_expected_pp
FROM transactions t
CROSS JOIN overall o
GROUP BY
    t.is_night_transaction,
    t.is_international,
    o.overall_rate,
    o.night_rate,
    o.intl_rate
ORDER BY fraud_rate_pct DESC;