-- ============================================================
-- Q4: Distance from Home Fraud Rate Analysis
-- Business question: Is there a distance threshold beyond
--   which fraud rate increases sharply?


WITH overall AS (
    SELECT ROUND(AVG(is_fraud::NUMERIC) * 100, 2) AS overall_fraud_rate
    FROM transactions
)
SELECT
    CASE
        WHEN t.distance_from_home_km BETWEEN 0   AND 9.99  THEN '1. 0-10km'
        WHEN t.distance_from_home_km BETWEEN 10  AND 19.99 THEN '2. 10-20km'
        WHEN t.distance_from_home_km BETWEEN 20  AND 39.99 THEN '3. 20-40km'
        WHEN t.distance_from_home_km BETWEEN 40  AND 59.99 THEN '4. 40-60km'
        WHEN t.distance_from_home_km BETWEEN 60  AND 99.99 THEN '5. 60-100km'
        WHEN t.distance_from_home_km >= 100                THEN '6. 100km+'
    END                                             AS distance_bucket,
    COUNT(*)                                        AS total_transactions,
    SUM(t.is_fraud)                                 AS fraud_count,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)       AS fraud_rate_pct,
    o.overall_fraud_rate,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)
        - o.overall_fraud_rate                      AS diff_from_avg_pp
FROM transactions t
CROSS JOIN overall o
GROUP BY distance_bucket, o.overall_fraud_rate
ORDER BY distance_bucket;