-- ============================================================
-- Q8b: Financial Loss by Merchant Category
-- Business question: Which merchant categories drive highest
--   fraud losses? Does highest fraud rate = highest loss?


WITH category_stats AS (
    SELECT
        merchant_category,
        COUNT(*)                                        AS total_transactions,
        SUM(is_fraud)                                   AS fraud_cases,
        COUNT(*) - SUM(is_fraud)                        AS legit_transactions,
        ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS fraud_rate_pct,
        -- Total fraud loss
        ROUND(SUM(
            CASE WHEN is_fraud = 1
            THEN transaction_amount ELSE 0 END
        ), 2)                                           AS total_fraud_loss_usd,
        -- Average fraud transaction amount
        ROUND(AVG(
            CASE WHEN is_fraud = 1
            THEN transaction_amount END
        ), 2)                                           AS avg_fraud_amount,
        -- Average legitimate transaction amount for comparison
        ROUND(AVG(
            CASE WHEN is_fraud = 0
            THEN transaction_amount END
        ), 2)                                           AS avg_legit_amount
    FROM transactions
    GROUP BY merchant_category
),
overall AS (
    SELECT
        SUM(CASE WHEN is_fraud = 1
            THEN transaction_amount ELSE 0 END)         AS total_fraud_loss
    FROM transactions
)
SELECT
    cs.merchant_category,
    cs.total_transactions,
    cs.fraud_cases,
    cs.fraud_rate_pct,
    cs.total_fraud_loss_usd,
    ROUND(cs.total_fraud_loss_usd / 1000000, 3)        AS total_loss_millions,
    cs.avg_fraud_amount,
    cs.avg_legit_amount,
    -- Share of total dataset fraud loss
    ROUND(cs.total_fraud_loss_usd
        / o.total_fraud_loss * 100, 2)                  AS pct_of_total_loss,
    -- Fraud profile classification
    CASE
        WHEN cs.fraud_rate_pct > 7.0
         AND cs.avg_fraud_amount < 200    THEN 'HIGH-RATE / LOW-VALUE'
        WHEN cs.avg_fraud_amount > 300    THEN 'HIGH-VALUE / MODERATE-RATE'
        ELSE                                   'BASELINE'
    END                                                 AS fraud_profile
FROM category_stats cs
CROSS JOIN overall o
ORDER BY cs.total_fraud_loss_usd DESC;