-- ============================================================
-- Q3: Account Profile Fraud Analysis
-- Business question: What account profiles are most targeted?


-- Part A: Fraud Rate by Customer Age Bucket
SELECT
    CASE
        WHEN customer_age BETWEEN 18 AND 25 THEN '1. 18-25'
        WHEN customer_age BETWEEN 26 AND 35 THEN '2. 26-35'
        WHEN customer_age BETWEEN 36 AND 50 THEN '3. 36-50'
        WHEN customer_age BETWEEN 51 AND 65 THEN '4. 51-65'
        WHEN customer_age > 65             THEN '5. 65+'
    END                                             AS age_bucket,
    COUNT(*)                                        AS total_transactions,
    SUM(is_fraud)                                   AS fraud_count,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS fraud_rate_pct,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)
        - 5.53                                      AS diff_from_avg_pp
FROM transactions
GROUP BY age_bucket
ORDER BY age_bucket;

-- Part B: Fraud Rate by Credit Score Bucket
SELECT
    CASE
        WHEN credit_score BETWEEN 300 AND 499 THEN '1. 300-499 (Poor)'
        WHEN credit_score BETWEEN 500 AND 649 THEN '2. 500-649 (Fair)'
        WHEN credit_score BETWEEN 650 AND 749 THEN '3. 650-749 (Good)'
        WHEN credit_score BETWEEN 750 AND 850 THEN '4. 750-850 (Excellent)'
    END                                             AS credit_bucket,
    COUNT(*)                                        AS total_transactions,
    SUM(is_fraud)                                   AS fraud_count,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS fraud_rate_pct,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)
        - 5.53                                      AS diff_from_avg_pp
FROM transactions
GROUP BY credit_bucket
ORDER BY credit_bucket;

-- Part C: Fraud Rate by Account Tenure Bucket
SELECT
    CASE
        WHEN account_age_years < 1              THEN '1. Under 1 year'
        WHEN account_age_years BETWEEN 1 AND 3  THEN '2. 1-3 years'
        WHEN account_age_years BETWEEN 3 AND 7  THEN '3. 3-7 years'
        WHEN account_age_years > 7              THEN '4. 7+ years'
    END                                             AS tenure_bucket,
    COUNT(*)                                        AS total_transactions,
    SUM(is_fraud)                                   AS fraud_count,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)         AS fraud_rate_pct,
    ROUND(AVG(is_fraud::NUMERIC) * 100, 2)
        - 5.53                                      AS diff_from_avg_pp
FROM transactions
GROUP BY tenure_bucket
ORDER BY tenure_bucket;