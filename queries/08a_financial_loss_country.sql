-- ============================================================
-- Q8a: Financial Loss by Country
-- Business question: Which countries have highest fraud losses?
--   Is loss driven by fraud rate or transaction volume?


WITH overall AS (
    SELECT
        SUM(CASE WHEN is_fraud = 1
            THEN transaction_amount ELSE 0 END)         AS total_fraud_loss,
        COUNT(*)                                        AS total_txns,
        SUM(is_fraud)                                   AS total_fraud_cases
    FROM transactions
)
SELECT
    t.country,
    COUNT(*)                                            AS total_transactions,
    SUM(t.is_fraud)                                     AS fraud_cases,
    ROUND(AVG(t.is_fraud::NUMERIC) * 100, 2)           AS fraud_rate_pct,
    -- Total fraud loss in dollars
    ROUND(SUM(
        CASE WHEN t.is_fraud = 1
        THEN t.transaction_amount ELSE 0 END
    ), 2)                                               AS total_fraud_loss_usd,
    -- Total fraud loss in millions for readability
    ROUND(SUM(
        CASE WHEN t.is_fraud = 1
        THEN t.transaction_amount ELSE 0 END
    ) / 1000000, 3)                                     AS total_fraud_loss_millions,
    -- Average fraud transaction amount for this country
    ROUND(AVG(
        CASE WHEN t.is_fraud = 1
        THEN t.transaction_amount END
    ), 2)                                               AS avg_fraud_amount,
    -- This country's share of total dataset fraud loss
    ROUND(SUM(
        CASE WHEN t.is_fraud = 1
        THEN t.transaction_amount ELSE 0 END
    ) / o.total_fraud_loss * 100, 2)                    AS pct_of_total_loss,
    -- Transaction volume share
    ROUND(COUNT(*)::NUMERIC / o.total_txns * 100, 2)   AS pct_of_total_volume
FROM transactions t
CROSS JOIN overall o
GROUP BY t.country, o.total_fraud_loss, o.total_txns, o.total_fraud_cases
ORDER BY total_fraud_loss_usd DESC;