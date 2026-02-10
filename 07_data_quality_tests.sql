-- ============================================================================
-- Finance Analytics Database - Data Quality Tests
-- ============================================================================
-- Description: Automated data quality checks and validation


\echo 'TEST 1: Checking for orphaned transactions...'

SELECT 
    'Orphaned Transactions' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM transactions t
LEFT JOIN accounts a ON t.account_id = a.account_id
WHERE a.account_id IS NULL;



\echo 'TEST 2: Checking for invalid transaction amounts...'

SELECT 
    'Invalid Transaction Amounts' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'FAIL'
    END AS status
FROM transactions
WHERE amount IS NULL OR amount = 0;



\echo 'TEST 3: Checking for negative checking account balances...'

SELECT 
    'Negative Checking Balances' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'WARNING'
    END AS status,
    STRING_AGG(account_name, ', ') AS affected_accounts
FROM accounts
WHERE account_type = 'checking' 
    AND balance < 0;



\echo 'TEST 4: Validating budget date ranges...'

SELECT 
    'Invalid Budget Dates' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'FAIL'
    END AS status
FROM budgets
WHERE end_date <= start_date;



\echo 'TEST 5: Checking for duplicate user emails...'

SELECT 
    'Duplicate User Emails' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT email, COUNT(*) as count
    FROM users
    GROUP BY email
    HAVING COUNT(*) > 1
) duplicates;



\echo 'TEST 6: Checking for uncategorized transactions...'

SELECT 
    'Uncategorized Transactions' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'WARNING'
    END AS status,
    ROUND((COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM transactions) * 100), 2) AS percent_uncategorized
FROM transactions
WHERE category_id IS NULL;



\echo 'TEST 7: Checking for future-dated transactions...'

SELECT 
    'Future-Dated Transactions' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'WARNING'
    END AS status
FROM transactions
WHERE transaction_date > CURRENT_DATE
    AND is_recurring = FALSE;



\echo 'TEST 8: Checking for overlapping budgets...'

SELECT 
    'Overlapping Budgets' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'FAIL'
    END AS status
FROM budgets b1
WHERE EXISTS (
    SELECT 1
    FROM budgets b2
    WHERE b1.budget_id != b2.budget_id
        AND b1.user_id = b2.user_id
        AND b1.category_id = b2.category_id
        AND b1.start_date <= b2.end_date
        AND b1.end_date >= b2.start_date
);



\echo 'TEST 9: Checking for inactive recurring transactions...'

SELECT 
    'Inactive Recurring with Future Dates' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'WARNING'
    END AS status
FROM recurring_transactions
WHERE is_active = FALSE
    AND next_occurrence > CURRENT_DATE;



\echo 'TEST 10: Checking for potential merchant name duplicates...'

WITH merchant_similarity AS (
    SELECT 
        m1.merchant_name AS name1,
        m2.merchant_name AS name2,
        SIMILARITY(LOWER(m1.merchant_name), LOWER(m2.merchant_name)) AS similarity_score
    FROM (SELECT DISTINCT merchant_name FROM transactions WHERE merchant_name IS NOT NULL) m1
    CROSS JOIN (SELECT DISTINCT merchant_name FROM transactions WHERE merchant_name IS NOT NULL) m2
    WHERE m1.merchant_name < m2.merchant_name
        AND SIMILARITY(LOWER(m1.merchant_name), LOWER(m2.merchant_name)) > 0.7
)
SELECT 
    'Potential Merchant Duplicates' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE 'INFO'
    END AS status,
    ARRAY_AGG(name1 || ' ≈ ' || name2) AS examples
FROM merchant_similarity;



\echo 'TEST 11: Validating required fields...'

SELECT 
    'NULL Values in Required Fields' AS test_name,
    (
        (SELECT COUNT(*) FROM users WHERE email IS NULL OR first_name IS NULL OR last_name IS NULL) +
        (SELECT COUNT(*) FROM accounts WHERE account_name IS NULL OR account_type IS NULL) +
        (SELECT COUNT(*) FROM transactions WHERE transaction_date IS NULL OR amount IS NULL OR transaction_type IS NULL) +
        (SELECT COUNT(*) FROM categories WHERE category_name IS NULL OR category_type IS NULL)
    ) AS issues_found,
    CASE 
        WHEN (
            (SELECT COUNT(*) FROM users WHERE email IS NULL OR first_name IS NULL OR last_name IS NULL) +
            (SELECT COUNT(*) FROM accounts WHERE account_name IS NULL OR account_type IS NULL) +
            (SELECT COUNT(*) FROM transactions WHERE transaction_date IS NULL OR amount IS NULL OR transaction_type IS NULL) +
            (SELECT COUNT(*) FROM categories WHERE category_name IS NULL OR category_type IS NULL)
        ) = 0 THEN '✓ PASS'
        ELSE 'FAIL'
    END AS status;



\echo 'TEST 12: Checking data freshness...'

SELECT 
    'Data Freshness' AS test_name,
    CASE 
        WHEN MAX(transaction_date) >= CURRENT_DATE - INTERVAL '7 days' THEN 0
        ELSE 1
    END AS issues_found,
    CASE 
        WHEN MAX(transaction_date) >= CURRENT_DATE - INTERVAL '7 days' THEN '✓ PASS'
        ELSE 'WARNING'
    END AS status,
    MAX(transaction_date) AS last_transaction_date,
    CURRENT_DATE - MAX(transaction_date) AS days_since_last_transaction
FROM transactions;

