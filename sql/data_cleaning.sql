-- Remove invalid balances
DELETE FROM accounts
WHERE balance < 0;

-- Normalize transaction type
UPDATE transactions
SET transaction_type = LOWER(transaction_type);

-- Remove null merchant rows
DELETE FROM transactions
WHERE merchant_id IS NULL;