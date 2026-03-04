-- High-frequency transaction accounts
SELECT
    account_id,
    COUNT(*) AS txn_count
FROM transactions
GROUP BY account_id
HAVING COUNT(*) > 50
ORDER BY txn_count DESC;

-- Spending spike detection
WITH txn_lag AS (
    SELECT
        account_id,
        transaction_date,
        amount,
        LAG(amount) OVER (
            PARTITION BY account_id
            ORDER BY transaction_date
        ) AS prev_amount
    FROM transactions
)
SELECT *
FROM txn_lag
WHERE amount > prev_amount * 5;

-- Rolling average anomaly detection
SELECT
    account_id,
    transaction_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY account_id
        ORDER BY transaction_date
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ) AS rolling_avg
FROM transactions;

-- Customer Lifetime Value
SELECT
    c.customer_id,
    SUM(t.amount) AS lifetime_value
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id
ORDER BY lifetime_value DESC;

-- Revenue Growth Rate (MoM % Change)
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', transaction_date) AS month,
        SUM(amount) AS revenue
    FROM transactions
    GROUP BY month
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) 
        / LAG(revenue) OVER (ORDER BY month) * 100, 2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

-- Customer Revenue Concentration (Top 20% Contribution)
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        SUM(t.amount) AS total_spent
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    JOIN transactions t ON a.account_id = t.account_id
    GROUP BY c.customer_id
),
ranked AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY total_spent DESC) AS quintile
    FROM customer_revenue
)
SELECT 
    quintile,
    COUNT(*) AS customer_count,
    SUM(total_spent) AS revenue
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- Fraud Pattern: Rapid Merchant Switching
SELECT 
    account_id,
    COUNT(DISTINCT merchant_id) AS unique_merchants,
    COUNT(*) AS txn_count
FROM transactions
WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY account_id
HAVING COUNT(DISTINCT merchant_id) > 10;

-- Customer Lifetime (Tenure Calculation)
SELECT 
    a.customer_id,
    MIN(t.transaction_date) AS first_txn,
    MAX(t.transaction_date) AS last_txn,
    EXTRACT(DAY FROM MAX(t.transaction_date) - MIN(t.transaction_date)) AS active_days
FROM accounts a
JOIN transactions t ON a.account_id = t.account_id
GROUP BY a.customer_id;

-- Weighted Moving Average
SELECT 
    account_id,
    transaction_date,
    amount,
    SUM(amount * 1.0) OVER (
        PARTITION BY account_id
        ORDER BY transaction_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) /
    SUM(1.0) OVER (
        PARTITION BY account_id
        ORDER BY transaction_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS weighted_avg
FROM transactions;

-- Gap Analysis Between Transactions
SELECT 
    account_id,
    transaction_date,
    transaction_date - LAG(transaction_date) 
        OVER (PARTITION BY account_id ORDER BY transaction_date) 
        AS gap_between_txns
FROM transactions;

-- Z-Score Based Fraud Detection
WITH stats AS (
    SELECT 
        account_id,
        AVG(amount) AS mean_amt,
        STDDEV(amount) AS std_amt
    FROM transactions
    GROUP BY account_id
)
SELECT 
    t.account_id,
    t.transaction_id,
    t.amount,
    (t.amount - s.mean_amt) / NULLIF(s.std_amt, 0) AS z_score
FROM transactions t
JOIN stats s ON t.account_id = s.account_id
WHERE ABS((t.amount - s.mean_amt) / NULLIF(s.std_amt, 0)) > 3
ORDER BY z_score DESC;

