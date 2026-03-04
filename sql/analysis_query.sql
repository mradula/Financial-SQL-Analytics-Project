-- Monthly transaction trends
SELECT
    DATE_TRUNC('month', transaction_date) AS month,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_value
FROM transactions
GROUP BY month
ORDER BY month;

-- Top spending customers
SELECT
    c.customer_id,
    SUM(t.amount) AS total_spent
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Merchant category revenue
SELECT
    m.category,
    COUNT(*) AS txn_count,
    SUM(t.amount) AS revenue
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.category
ORDER BY revenue DESC;