import numpy as np
import pandas as pd
from sklearn.metrics import (
    precision_score, recall_score, f1_score,
    roc_auc_score, average_precision_score, confusion_matrix
)


# ── Column definitions ─────────────────────────────────────────────────────

CAT_COLS = ['merchant_category', 'payment_method', 'device_type', 'country']

LOG_SCALE_COLS_LR = [
    'transaction_amount', 'account_balance', 'account_age_years',
    'distance_from_home_km', 'time_since_last_txn_hrs'
]

SCALE_ONLY_COLS_LR = [
    'customer_age', 'credit_score', 'num_prev_transactions',
    'transaction_freq_monthly', 'hour_of_day', 'failed_attempts',
    'compound_risk_score'
]

# LR binary cols include compound interaction flags (engineer_features output)
BINARY_COLS_LR = [
    'is_weekend', 'is_night_transaction', 'is_international',
    'pin_changed_recently', 'high_risk_attempts',
    'night_international', 'high_risk_merchant', 'high_value_transaction'
]

# XGB binary cols — compound flags removed; XGBoost discovers interactions itself
BINARY_COLS_XGB = [
    'is_weekend', 'is_night_transaction', 'is_international',
    'pin_changed_recently', 'high_risk_attempts', 'high_value_transaction'
]

PASSTHROUGH_COLS_XGB = [
    'customer_age', 'credit_score', 'num_prev_transactions',
    'transaction_freq_monthly', 'hour_of_day', 'failed_attempts',
    'distance_from_home_km', 'time_since_last_txn_hrs',
    'transaction_amount', 'account_balance', 'account_age_years'
]

# XGB V1 passthrough — includes compound_risk_score (removed in V2/V3)
PASSTHROUGH_COLS_XGB_V1 = [
    'customer_age', 'credit_score', 'num_prev_transactions',
    'transaction_freq_monthly', 'hour_of_day', 'failed_attempts',
    'compound_risk_score', 'distance_from_home_km', 'time_since_last_txn_hrs'
]


# ── Feature engineering ────────────────────────────────────────────────────

def engineer_features(X):
    """
    Feature engineering for Logistic Regression and Isolation Forest pipelines.
    Adds compound interaction features — LR requires these pre-computed because
    it cannot discover non-linear interactions on its own.

    Features added:
        high_risk_attempts    — binary threshold at failed_attempts >= 2
        night_international   — AND of is_night_transaction & is_international
        high_risk_merchant    — ATM Withdrawal / Jewelry / Crypto Exchange flag
        compound_risk_score   — weighted sum of top risk signals (0–10)
        high_value_transaction — p95 transaction amount flag
    """
    X = X.copy()

    # SQL Q6: step function at exactly 2 attempts (4.52% → 14.60% fraud rate)
    X['high_risk_attempts'] = (X['failed_attempts'] >= 2).astype(int)

    # SQL Q2: night + international segment — 12.22% fraud rate
    X['night_international'] = (
        (X['is_night_transaction'] == 1) & (X['is_international'] == 1)
    ).astype(int)

    # SQL Q1: ATM/Jewelry/Crypto at 8.65–8.74% vs 5.53% baseline
    X['high_risk_merchant'] = X['merchant_category'].isin(
        ['ATM Withdrawal', 'Jewelry', 'Crypto Exchange']
    ).astype(int)

    # SQL ADV1: compound score gradient 1.25% (score 0) → 26.97% (score 10)
    X['compound_risk_score'] = (
        (X['failed_attempts'] >= 2).astype(int) * 3
        + X['is_international'] * 2
        + X['is_night_transaction'] * 2
        + X['high_risk_merchant'] * 2
        + X['pin_changed_recently'] * 1
    )

    # SQL Q8b: high-value fraud profile ($693–$734 avg fraud amount)
    p95 = X['transaction_amount'].quantile(0.95)
    X['high_value_transaction'] = (X['transaction_amount'] >= p95).astype(int)

    return X


def engineer_features_xgb(X):
    """
    Minimal feature engineering for XGBoost pipeline (V2/V3).
    Compound features removed — XGBoost discovers interactions via tree splits.
    compound_risk_score absorbed 39.3% of V1 importance, preventing the model
    from learning underlying signals independently.

    Features added:
        high_risk_attempts    — binary threshold at failed_attempts >= 2
        high_value_transaction — p95 transaction amount flag
    """
    X = X.copy()

    # SQL Q6: step function at exactly 2 (4.52% → 14.60%)
    X['high_risk_attempts'] = (X['failed_attempts'] >= 2).astype(int)

    # SQL Q8b: high-value fraud profile
    p95 = X['transaction_amount'].quantile(0.95)
    X['high_value_transaction'] = (X['transaction_amount'] >= p95).astype(int)

    return X


# ── Feature name reconstruction ────────────────────────────────────────────

def get_feature_names_lr(pipeline_lr):
    """
    Reconstruct ordered feature names from a fitted LR pipeline.
    ColumnTransformer drops column names — this rebuilds them in output order:
        log_scale → scale → ohe → binary passthrough

    Args:
        pipeline_lr: fitted sklearn Pipeline with 'preprocessor' step

    Returns:
        list of feature name strings matching model.coef_ order
    """
    ohe = pipeline_lr.named_steps['preprocessor'].named_transformers_['ohe']
    ohe_names = ohe.get_feature_names_out(CAT_COLS).tolist()
    return LOG_SCALE_COLS_LR + SCALE_ONLY_COLS_LR + ohe_names + BINARY_COLS_LR


def get_feature_names_xgb(preprocessor_xgb_v2):
    """
    Reconstruct ordered feature names from a fitted XGB V2/V3 preprocessor.
    Output order: ohe → binary passthrough → numerical passthrough (53 total)

    Args:
        preprocessor_xgb_v2: fitted ColumnTransformer from XGB V2/V3 pipeline

    Returns:
        list of 53 feature name strings matching xgb_v3.n_features_in_
    """
    ohe = preprocessor_xgb_v2.named_transformers_['ohe']
    ohe_names = ohe.get_feature_names_out(CAT_COLS).tolist()
    return ohe_names + BINARY_COLS_XGB + PASSTHROUGH_COLS_XGB


def get_feature_names_xgb_v1(preprocessor_xgb_v1):
    """
    Reconstruct ordered feature names from a fitted XGB V1 preprocessor.
    V1 used engineer_features (full compound set) so binary cols = BINARY_COLS_LR (8)
    and passthrough = PASSTHROUGH_COLS_XGB_V1 (9, includes compound_risk_score).
    Output: ohe -> binary passthrough -> numerical passthrough (55 total)

    Args:
        preprocessor_xgb_v1: fitted ColumnTransformer from XGB V1 pipeline

    Returns:
        list of 55 feature name strings matching pipeline_xgb V1 n_features_in_
    """
    ohe = preprocessor_xgb_v1.named_transformers_['ohe']
    ohe_names = ohe.get_feature_names_out(CAT_COLS).tolist()
    return ohe_names + BINARY_COLS_LR + PASSTHROUGH_COLS_XGB_V1


# ── LR test-set preparation ────────────────────────────────────────────────

def prepare_for_lr(X):
    """
    Reconstruct compound features required by the LR pipeline on raw X_test.
    The LR pipeline was fitted with engineer_features (full compound set).
    X_test only contains 19 raw columns — this adds the missing engineered cols.

    Note: compound_risk_score formula here is simplified vs training
    (sum/3 normalization vs weighted sum). This introduces minor scaling
    differences. See Stage 6 findings — LR was ultimately excluded from
    test-set threshold analysis due to probability compression.

    Args:
        X: raw DataFrame with 19 base columns

    Returns:
        DataFrame with all columns the LR ColumnTransformer expects
    """
    X = X.copy()

    X['high_risk_attempts'] = (X['failed_attempts'] >= 2).astype(int)

    p95 = X['transaction_amount'].quantile(0.95)
    X['high_value_transaction'] = (X['transaction_amount'] >= p95).astype(int)

    X['night_international'] = (
        X['is_night_transaction'] * X['is_international']
    )

    X['high_risk_merchant'] = X['merchant_category'].isin(
        {'ATM Withdrawal', 'Crypto Exchange', 'Jewelry'}
    ).astype(int)

    X['compound_risk_score'] = (
        X['is_night_transaction'] + X['is_international'] + X['high_risk_attempts']
    ) / 3.0

    return X


# ── Model evaluation ───────────────────────────────────────────────────────

def evaluate_model(name, y_true, probs, flagging_rate=0.10, val_auc_pr=None, val_fraud_pct=None):
    """
    Evaluate a model on a labelled dataset. Prints a formatted summary and
    returns a results dict for building comparison tables.

    Args:
        name         : display name for the model
        y_true       : ground-truth labels (pandas Series)
        probs        : fraud probability scores (numpy array)
        flagging_rate: fraction of dataset to flag for North Star lift (default 0.10)
        val_auc_pr   : validation AUC-PR for overfitting check (optional)
        val_fraud_pct: validation fraud capture % for comparison (optional)

    Returns:
        dict with keys: Model, Precision, Recall, F1, AUC_ROC, AUC_PR,
                        Lift_10pct, Fraud_10pct, FP_per_TP
    """
    preds = (probs >= 0.5).astype(int)
    tn, fp, fn, tp = confusion_matrix(y_true, preds).ravel()

    precision = precision_score(y_true, preds, zero_division=0)
    recall    = recall_score(y_true, preds, zero_division=0)
    f1        = f1_score(y_true, preds, zero_division=0)
    auc_roc   = roc_auc_score(y_true, probs)
    auc_pr    = average_precision_score(y_true, probs)

    sorted_idx    = np.argsort(probs)[::-1]
    top_n         = int(len(y_true) * flagging_rate)
    fraud_captured = y_true.iloc[sorted_idx[:top_n]].sum()
    lift          = (fraud_captured / top_n) / (y_true.sum() / len(y_true))
    fraud_pct     = fraud_captured / y_true.sum() * 100
    fp_per_tp     = round(fp / tp, 1) if tp > 0 else float('inf')

    print(f"\n── {name} {'─' * max(1, 55 - len(name))}")
    print(f"  Precision  : {precision:.4f}")
    print(f"  Recall     : {recall:.4f}")
    print(f"  F1         : {f1:.4f}")
    print(f"  AUC-ROC    : {auc_roc:.4f}")

    if val_auc_pr is not None:
        diff = auc_pr - val_auc_pr
        flag = '✅' if abs(diff) <= 0.01 else '⚠️  INVESTIGATE'
        print(f"  AUC-PR     : {auc_pr:.4f}  (val: {val_auc_pr:.4f}  diff: {diff:+.4f})  {flag}")
    else:
        print(f"  AUC-PR     : {auc_pr:.4f}")

    print(f"  Lift@{flagging_rate*100:.0f}%  : {lift:.2f}x")

    if val_fraud_pct is not None:
        print(f"  Fraud@{flagging_rate*100:.0f}% : {fraud_pct:.2f}%  (val: {val_fraud_pct:.2f}%)")
    else:
        print(f"  Fraud@{flagging_rate*100:.0f}% : {fraud_pct:.2f}%")

    print(f"  Legit/Fraud: {fp_per_tp:.1f}x  ({fp:,} legitimate disrupted per {tp:,} fraud caught)")

    return {
        'Model'      : name,
        'Precision'  : precision,
        'Recall'     : recall,
        'F1'         : f1,
        'AUC_ROC'    : auc_roc,
        'AUC_PR'     : auc_pr,
        'Lift_10pct' : lift,
        'Fraud_10pct': fraud_pct,
        'FP_per_TP'  : fp_per_tp
    }
