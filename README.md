# Bank Transaction Fraud Detection

**Which transactions should be flagged for manual review to maximize fraud caught while minimizing disruption to legitimate customers?**

An end-to-end fraud detection pipeline built on 1 million synthetic banking transactions — covering exploratory analysis, SQL-based rule benchmarking, feature engineering, machine learning modeling, and operational threshold recommendations.

---

## Project at a Glance

| Property | Value |
|---|---|
| Dataset | 1,000,000 transactions · 26 features · 5.53% fraud rate |
| Period | 2020–2024 across 10 countries |
| Production Model | XGBoost V3 |
| Recommended Threshold | ≥ 0.60 — flags 11% of transactions, catches 28.5% of fraud |
| SQL Baseline | ADV5 rule-based system — 26.23% fraud captured at 10% flagging |
| ML Advantage over Rules | +2.28 percentage points at 11% flagging |
| Key Finding | Synthetic data ceiling — all models converge to ~2.63x lift due to dataset structure |
| Stack | Python · PostgreSQL · XGBoost · Scikit-learn · Power BI |

---

## Business Problem

Fraud detection is not a binary classification problem in practice — it is a **resource allocation problem**. A bank cannot manually review every transaction. Flagging too little means fraud goes undetected. Flagging too much means legitimate customers get blocked and review teams get overwhelmed.

This project answers one operational question: given a ranked list of transactions by fraud probability, where do you draw the line?

**Audience:** Risk management leadership at retail banks and fintech firms who need to know where fraud is concentrated, how much it costs, and which flagging strategy minimizes exposure without grinding operations to a halt.

---

## Key Results

### Model Performance on Held-Out Test Set (150,000 transactions)

| Model | AUC-PR | AUC-ROC | F1 | Lift @ 10% | Fraud Caught @ 10% |
|---|---|---|---|---|---|
| SQL ADV5 (rules baseline) | — | — | — | 2.62x | 26.23% |
| Logistic Regression | 0.1246 | 0.7220 | 0.1859 | 2.65x | 26.53% |
| **XGBoost V3** | **0.1218** | **0.7246** | **0.1925** | **2.63x** | **26.30%** |
| Isolation Forest | 0.0983 | 0.6473 | 0.1568 | 2.16x | 21.64% |

> Accuracy was never used as a primary metric — at 5.53% fraud rate, a model predicting "no fraud" on every transaction achieves 94.47% accuracy while catching zero fraud.

### Operational Tier Recommendation

| Tier | Threshold | Transactions Flagged | Fraud Caught | Precision | Legit per Fraud |
|---|---|---|---|---|---|
| **Tier 1 — Immediate Escalation** | **≥ 0.60** | 16,489 (11.0%) | 2,363 (28.5%) | 0.1433 | 6.0x |
| Tier 2 — Standard Review | 0.50–0.60 | 23,802 (15.9%) | 2,309 (27.9%) | 0.0970 | 9.3x |
| Tier 3 — Deprioritize | < 0.50 | 109,709 (73.1%) | 3,216 (38.8%) | 0.0293 | 33.2x |

**Critical constraint:** XGBoost outperforms the SQL rule-based system only at ≤11% flagging. Above that rate, rules are equally or more effective. The correct deployment is **complementary** — XGBoost for Tier 1 escalation, SQL rules for the broader review queue.

---

## The Synthetic Data Ceiling (Most Important Finding)

All three supervised models converge to approximately 2.63x lift at 10% flagging. This is not a modeling failure — it is a dataset property.

The synthetic dataset contains only discrete linear signals: failed login attempts, night timing, international flag, merchant category. These are the same signals the SQL rules encode. XGBoost's advantage appears only in the top 11% of ranked transactions where it finds non-linear combinations of these signals. Below that threshold, probability ranking adds no incremental value over hand-crafted rules.

**XGBoost's early stopping triggered at iteration 15 of 1,000.** This is the definitive diagnostic — the model exhausted all learnable signal in 15 trees.

On real banking data with customer behavioral baselines, velocity features, and device fingerprinting, XGBoost would maintain its advantage across a much wider flagging range.

---

## Project Stages

| Stage | Description | Status |
|---|---|---|
| 1 | Project Setup & Data Loading | ✅ Complete |
| 2 | Exploratory Data Analysis | ✅ Complete |
| 3 | PostgreSQL & SQL Query Analysis | ✅ Complete |
| 4 | Feature Engineering | ✅ Complete |
| 5 | Modeling & Validation Set Evaluation | ✅ Complete |
| 6 | Final Evaluation on Held-Out Test Set | ✅ Complete |
| 7 | Power BI Dashboard | 🔄 In Progress |
| 8 | Final Packaging & Portfolio Delivery | ⏳ Pending |

---

## Repository Structure

```
fraud-detection/
├── notebook/
│   ├── EDA.ipynb                    # Exploratory data analysis (Stages 2–2.5)
│   ├── feature_engineering.ipynb    # Feature construction & train/val/test split
│   ├── modeling.ipynb               # LR, XGBoost, Isolation Forest training & validation
│   └── final_evaluation.ipynb       # Held-out test set evaluation & tier thresholds
├── queries/
│   ├── 02_night_international_compound.sql
│   ├── 03_account_profile.sql
│   ├── 04_distance_buckets.sql
│   ├── 05_payment_device_fraud_rate.sql
│   ├── 06_failed_attempts_threshold.sql
│   ├── 07_pin_change_signal.sql
│   ├── 07b_pin_failed_compound.sql
│   ├── 08a_financial_loss_country.sql
│   ├── 08b_financial_loss_merchant.sql
│   ├── 09_top10pct_fraud_capture.sql
│   ├── 09b_multisignal_capture.sql
│   └── 10_false_positive_cost.sql
├── data/
│   ├── dashboard_data.csv           # Power BI input — full scored test set
│   ├── model_scores_test.csv        # Fraud probabilities + risk tiers
│   └── shap_importance.csv          # SHAP feature importance values
├── models/
│   ├── pipeline_xgb_final.pkl       # Production XGBoost pipeline
│   ├── model_comparison.csv         # Val vs test metrics side-by-side
│   └── threshold_decision_table.csv # Full threshold analysis — all operating points
├── notebook/plots/                  # All EDA and modeling visualizations
├── src/
│   └── fraud_utils.py               # Shared feature engineering functions
└── README.md
```

---

## Methodology

### Data Split

| Set | Rows | Fraud Rate |
|---|---|---|
| Train | 699,975 | 5.53% |
| Validation | 150,025 | 5.53% |
| Test (held out) | 150,000 | 5.53% |

Stratified split preserved the original class distribution across all three sets.

### Feature Engineering

Two engineered features were added on top of the 19 raw features:

- `high_risk_attempts` — step-function threshold on failed login attempts (threshold selected from EDA)
- `high_value_transaction` — binary flag for transactions in the top percentile by amount

All feature construction is encapsulated inside the production pipeline object. The test set stores only raw features; the pipeline applies all transformations at inference time.

> Note: `compound_risk_score` was evaluated but removed from the XGBoost pipeline after it absorbed 39.3% of SHAP importance and crowded out other signals. It is retained in the Logistic Regression pipeline only.

### Class Imbalance Handling

| Model | Method |
|---|---|
| Logistic Regression | `class_weight='balanced'` |
| XGBoost V3 | `scale_pos_weight` set to reflect 17:1 class ratio |
| Isolation Forest | Unsupervised — no imbalance handling required |

### Why Logistic Regression Was Excluded from Threshold Analysis

LR probability outputs on the test set collapsed to a range of 0.17–0.51. Only 1 of 150,000 transactions scored above 0.50, making threshold-based metrics meaningless. Root cause: the LR pipeline was fitted with compound interaction features not present in the raw test set. Reconstructing those features externally introduced scaling differences that compressed output probabilities. AUC-PR deviation was 0.0295 — three times the tolerance threshold. This is a pipeline consistency issue, not a modeling failure, and it validates the standard practice of encapsulating all feature construction inside the pipeline object.

### SQL Baseline (Stage 3)

Fifteen SQL queries were written against PostgreSQL 16.3 to answer operational business questions before any ML modeling. The most important: ADV5, a multi-signal rule-based review queue simulation that established the 2.62x lift ceiling. Every ML model in Stages 5–6 is evaluated against this benchmark.

---

## How to Run

```bash
# 1. Clone the repo
git clone https://github.com/Ashokmevada/fraud_detection.git
cd fraud_detection

# 2. Create and activate virtual environment
python -m venv fraud
fraud\Scripts\activate        # Windows
# source fraud/bin/activate   # Mac/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Download the dataset from Kaggle
# https://www.kaggle.com/datasets/[dataset-link]
# Place the CSV in /data/bank_fraud.csv

# 5. Run notebooks in order
jupyter notebook notebook/EDA.ipynb
jupyter notebook notebook/feature_engineering.ipynb
jupyter notebook notebook/modeling.ipynb
jupyter notebook notebook/final_evaluation.ipynb
```

> **Important:** The `engineer_features` function must be defined in your notebook session before loading any `.pkl` pipeline files. `joblib` serializes `FunctionTransformer` steps by function reference — if the function is not present in the namespace at load time, deserialization fails with `AttributeError`. This is handled in `src/fraud_utils.py`.

---

## Tools & Stack

| Layer | Tool |
|---|---|
| Language | Python 3.x |
| Data Processing | Pandas, NumPy |
| Database | PostgreSQL 16.3, pgAdmin 4 |
| Machine Learning | Scikit-learn, XGBoost |
| Explainability | SHAP |
| Visualization | Matplotlib, Seaborn, Power BI |
| Pipeline Serialization | joblib |
| Version Control | Git + GitHub |

---

## What Would Improve This Model on Real Banking Data

Three things specifically, and in priority order:

1. **Customer behavioral baselines** — average transaction amount, typical merchant categories, usual hours per customer. Lets the model detect deviation from normal behavior rather than just absolute risk factors. This is the biggest gap in this dataset.
2. **Velocity features** — transactions per hour per account, rapid retransaction sequences. The strongest real-world fraud signal, entirely absent here because each row was generated independently.
3. **Device and session metadata** — IP addresses, device fingerprints, browser patterns. Together with the above, these additions would likely push XGBoost to 5–8x lift at 10% flagging on real data versus 2.63x here.

---

*Dataset is synthetic and does not contain real customer data. Generated with realistic correlations for educational and portfolio purposes.*
