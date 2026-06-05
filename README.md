# Bank Transaction Fraud Detection
### Identifying high-risk transactions to minimize financial loss while reducing false positives

---

## Business Problem

Financial fraud costs institutions billions annually. The challenge is not simply detecting fraud — it is catching as much fraud as possible without flagging so many legitimate transactions that operations grind to a halt.

This project analyzes **1 million banking transactions** (2020–2024) to answer one core question:

> **Which transactions should be flagged for manual review to maximize fraud caught while minimizing disruption to legitimate customers?**

**Audience:** Risk Management Leadership at retail banks and fintech firms — stakeholders who need to know *where* fraud is concentrated, *how much* it costs, and *which interventions* reduce exposure most effectively.

---

## Key Findings

> ⚠️ *This section will be completed after modeling. Placeholder structure shown.*

- **[X]% of fraud** is concentrated in **[top merchant categories]**
- Night + international transactions together show **[X]x higher fraud rate** than daytime domestic transactions
- Flagging the **top 10% riskiest transactions** captures approximately **[X]% of all fraud**
- Estimated **$[X]M in annual loss prevention** at the recommended review threshold
- XGBoost achieved **[X]% recall** at a **[X]% false positive rate** — meaning 1 in [X] flagged transactions is a false alarm

---

## Project Structure

```
fraud-detection-capstone/
├── notebooks/
│   ├── 01_eda.ipynb              # Exploratory data analysis
│   └── 02_modeling.ipynb         # Feature engineering, modeling, evaluation
├── sql/
│   ├── 01_fraud_by_merchant.sql
│   ├── 02_night_international_risk.sql
│   ├── 03_account_profile_targeting.sql
│   ├── 04_payment_device_vulnerability.sql
│   ├── 05_failed_attempts_analysis.sql
│   ├── 06_financial_loss_by_country.sql
│   └── 07_risk_tier_segmentation.sql
├── dashboard/
│   └── fraud_dashboard.pbix      # Power BI dashboard
├── README.md
└── requirements.txt
```

---

## Methodology

### Data
- **Source:** Bank Transaction Fraud Detection Dataset (synthetic, Kaggle)
- **Size:** 1,000,000 transactions × 26 features
- **Fraud rate:** ~5.5% (realistic class imbalance)
- **Period:** 2020–2024 across 10 countries

### Models Built
| Model | Purpose | Imbalance Handling |
|---|---|---|
| Logistic Regression | Interpretable baseline | `class_weight='balanced'` |
| XGBoost | Primary classifier | `scale_pos_weight` |
| Isolation Forest | Unsupervised anomaly benchmark | N/A |

### Evaluation Metrics
Accuracy was **never used** as a primary metric given the class imbalance. All models evaluated on:
- **Recall** (fraud caught rate) — primary metric for a fraud operations team
- **Precision** (how often a flagged transaction is actually fraud)
- **F1-Score** (balance of precision and recall)
- **AUC-ROC** (overall discriminatory power)

### Business Cost Matrix
| | Predicted Fraud | Predicted Legitimate |
|---|---|---|
| **Actual Fraud** | True Positive ✅ | False Negative ❌ (costly — missed fraud) |
| **Actual Legitimate** | False Positive ⚠️ (friction — blocked customer) | True Negative ✅ |

False negatives cost more than false positives. Model threshold was tuned to reflect this asymmetry.

---

## SQL Analysis

Seven analytical queries answer the supporting business questions directly. Located in `/sql`:

| File | Business Question |
|---|---|
| `01_fraud_by_merchant.sql` | Which merchant categories have the highest fraud rates? |
| `02_night_international_risk.sql` | Do night + international transactions compound risk? |
| `03_account_profile_targeting.sql` | What account profiles are most frequently targeted? |
| `04_payment_device_vulnerability.sql` | Which payment methods and device types are most vulnerable? |
| `05_failed_attempts_analysis.sql` | How many failed attempts precede a fraudulent transaction? |
| `06_financial_loss_by_country.sql` | What is estimated financial loss from undetected fraud by country? |
| `07_risk_tier_segmentation.sql` | If we flag the top 10% riskiest transactions, what share of fraud is captured? |

---

## Dashboard

The Power BI dashboard (`/dashboard/fraud_dashboard.pbix`) targets Risk Management Leadership with 5 focused visuals:

1. **Total financial exposure** by fraud type and country
2. **Fraud rate** by merchant category and payment method
3. **Month-over-month fraud trend** (2020–2024)
4. **Risk score distribution** — flagged vs legitimate transactions
5. **Detection rate vs false positive rate** tradeoff curve

---

## How to Run

```bash
# 1. Clone the repo
git clone https://github.com/[your-username]/fraud-detection-capstone.git
cd fraud-detection-capstone

# 2. Install dependencies
pip install -r requirements.txt

# 3. Download the dataset
# https://www.kaggle.com/datasets/[dataset-link]
# Place the CSV in /data/transactions.csv

# 4. Run EDA notebook
jupyter notebook notebooks/01_eda.ipynb

# 5. Run modeling notebook
jupyter notebook notebooks/02_modeling.ipynb
```

---

## Tools & Stack

| Layer | Tool |
|---|---|
| Data processing | Python (Pandas, NumPy) |
| Visualization | Matplotlib, Seaborn, Power BI |
| SQL analysis | SQLite / PostgreSQL |
| Modeling | Scikit-learn, XGBoost, imbalanced-learn |
| Version control | Git + GitHub |

---

*Dataset is synthetic and does not contain real customer data.*
