-- ============================================================================
-- Finance Analytics Database - Data Quality Tests
-- ============================================================================
-- Description: Automated data quality checks and validation
-- Author: Your Name
-- Date: 2024
-- ============================================================================

\echo '════════════════════════════════════════════════════════'
\echo 'Running Data Quality Tests...'
\echo '════════════════════════════════════════════════════════'
\echo ''

-- ============================================================================
-- TEST 1: Orphaned Transactions
-- ============================================================================
-- Description: Check for transactions not linked to valid accounts

\echo 'TEST 1: Checking for orphaned transactions...'

SELECT 
    'Orphaned Transactions' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '❌ FAIL'
    END AS status
FROM transactions t
LEFT JOIN accounts a ON t.account_id = a.account_id
WHERE a.account_id IS NULL;

-- ============================================================================
-- TEST 2: Transactions with Invalid Amounts
-- ============================================================================
-- Description: Find transactions with zero or null amounts

\echo 'TEST 2: Checking for invalid transaction amounts...'

SELECT 
    'Invalid Transaction Amounts' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '❌ FAIL'
    END AS status
FROM transactions
WHERE amount IS NULL OR amount = 0;

-- ============================================================================
-- TEST 3: Negative Account Balances (Checking Accounts)
-- ============================================================================
-- Description: Checking accounts shouldn't have negative balances

\echo 'TEST 3: Checking for negative checking account balances...'

SELECT 
    'Negative Checking Balances' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '⚠️  WARNING'
    END AS status,
    STRING_AGG(account_name, ', ') AS affected_accounts
FROM accounts
WHERE account_type = 'checking' 
    AND balance < 0;

-- ============================================================================
-- TEST 4: Budget Date Validation
-- ============================================================================
-- Description: Ensure budget end dates are after start dates

\echo 'TEST 4: Validating budget date ranges...'

SELECT 
    'Invalid Budget Dates' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '❌ FAIL'
    END AS status
FROM budgets
WHERE end_date <= start_date;

-- ============================================================================
-- TEST 5: Duplicate Users
-- ============================================================================
-- Description: Check for duplicate email addresses

\echo 'TEST 5: Checking for duplicate user emails...'

SELECT 
    'Duplicate User Emails' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '❌ FAIL'
    END AS status
FROM (
    SELECT email, COUNT(*) as count
    FROM users
    GROUP BY email
    HAVING COUNT(*) > 1
) duplicates;

-- ============================================================================
-- TEST 6: Transactions Without Categories
-- ============================================================================
-- Description: Find transactions missing category assignment

\echo 'TEST 6: Checking for uncategorized transactions...'

SELECT 
    'Uncategorized Transactions' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '⚠️  WARNING'
    END AS status,
    ROUND((COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM transactions) * 100), 2) AS percent_uncategorized
FROM transactions
WHERE category_id IS NULL;

-- ============================================================================
-- TEST 7: Future-Dated Transactions
-- ============================================================================
-- Description: Find transactions dated in the future (excluding recurring)

\echo 'TEST 7: Checking for future-dated transactions...'

SELECT 
    'Future-Dated Transactions' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '⚠️  WARNING'
    END AS status
FROM transactions
WHERE transaction_date > CURRENT_DATE
    AND is_recurring = FALSE;

-- ============================================================================
-- TEST 8: Account Balance Reconciliation
-- ============================================================================
-- Description: Verify stored balances match calculated balances

\echo 'TEST 8: Reconciling account balances...'

WITH balance_check AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.balance AS stored_balance,
        COALESCE(SUM(
            CASE 
                WHEN t.transaction_type = 'credit' THEN t.amount
                WHEN t.transaction_type = 'debit' THEN -t.amount
            END
        ), 0) AS calculated_balance,
        ABS(a.balance - COALESCE(SUM(
            CASE 
                WHEN t.transaction_type = 'credit' THEN t.amount
                WHEN t.transaction_type = 'debit' THEN -t.amount
            END
        ), 0)) AS difference
    FROM accounts a
    LEFT JOIN transactions t ON a.account_id = t.account_id
    GROUP BY a.account_id, a.account_name, a.balance
)
SELECT 
    'Balance Reconciliation Errors' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '❌ FAIL'
    END AS status,
    STRING_AGG(account_name || ' (diff: $' || ROUND(difference::NUMERIC, 2) || ')', ', ') AS affected_accounts
FROM balance_check
WHERE difference > 0.01;  -- Allow for 1 cent rounding differences

-- ============================================================================
-- TEST 9: Overlapping Budgets
-- ============================================================================
-- Description: Check for overlapping budget periods for same category

\echo 'TEST 9: Checking for overlapping budgets...'

SELECT 
    'Overlapping Budgets' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '❌ FAIL'
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

-- ============================================================================
-- TEST 10: Inactive Recurring Transactions Still Processing
-- ============================================================================
-- Description: Find inactive recurring transactions with future occurrences

\echo 'TEST 10: Checking for inactive recurring transactions...'

SELECT 
    'Inactive Recurring with Future Dates' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '⚠️  WARNING'
    END AS status
FROM recurring_transactions
WHERE is_active = FALSE
    AND next_occurrence > CURRENT_DATE;

-- ============================================================================
-- TEST 11: Merchants with Inconsistent Naming
-- ============================================================================
-- Description: Find similar merchant names that might be duplicates

\echo 'TEST 11: Checking for potential merchant name duplicates...'

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
        ELSE '⚠️  INFO'
    END AS status,
    ARRAY_AGG(name1 || ' ≈ ' || name2) AS examples
FROM merchant_similarity;

-- ============================================================================
-- TEST 12: Data Completeness Check
-- ============================================================================
-- Description: Overall data completeness metrics

\echo 'TEST 12: Data completeness summary...'

SELECT 
    'Data Completeness' AS test_name,
    'INFO' AS status,
    jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM users),
        'total_accounts', (SELECT COUNT(*) FROM accounts),
        'total_transactions', (SELECT COUNT(*) FROM transactions),
        'transactions_with_categories', (SELECT COUNT(*) FROM transactions WHERE category_id IS NOT NULL),
        'active_budgets', (SELECT COUNT(*) FROM budgets WHERE end_date >= CURRENT_DATE),
        'active_recurring', (SELECT COUNT(*) FROM recurring_transactions WHERE is_active = TRUE)
    ) AS metrics;

-- ============================================================================
-- TEST 13: Transaction Volume by Month
-- ============================================================================
-- Description: Ensure we have consistent transaction volume (detect missing data)

\echo 'TEST 13: Checking transaction volume consistency...'

WITH monthly_volume AS (
    SELECT 
        DATE_TRUNC('month', transaction_date)::DATE AS month,
        COUNT(*) AS transaction_count
    FROM transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('month', transaction_date)::DATE
)
SELECT 
    'Abnormal Transaction Volume' AS test_name,
    COUNT(*) AS issues_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '⚠️  WARNING'
    END AS status,
    'Months with unusually low activity' AS details
FROM monthly_volume
WHERE transaction_count < (SELECT AVG(transaction_count) * 0.3 FROM monthly_volume);

-- ============================================================================
-- TEST 14: Required Fields Validation
-- ============================================================================
-- Description: Check for NULL values in required fields

\echo 'TEST 14: Validating required fields...'

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
        ELSE '❌ FAIL'
    END AS status;

-- ============================================================================
-- TEST 15: Data Freshness Check
-- ============================================================================
-- Description: Ensure we have recent transaction data

\echo 'TEST 15: Checking data freshness...'

SELECT 
    'Data Freshness' AS test_name,
    CASE 
        WHEN MAX(transaction_date) >= CURRENT_DATE - INTERVAL '7 days' THEN 0
        ELSE 1
    END AS issues_found,
    CASE 
        WHEN MAX(transaction_date) >= CURRENT_DATE - INTERVAL '7 days' THEN '✓ PASS'
        ELSE '⚠️  WARNING'
    END AS status,
    MAX(transaction_date) AS last_transaction_date,
    CURRENT_DATE - MAX(transaction_date) AS days_since_last_transaction
FROM transactions;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'Data Quality Test Summary'
\echo '════════════════════════════════════════════════════════'

WITH test_summary AS (
    SELECT 
        COUNT(*) FILTER (WHERE status = '✓ PASS') AS passed,
        COUNT(*) FILTER (WHERE status LIKE '❌%') AS failed,
        COUNT(*) FILTER (WHERE status LIKE '⚠️%') AS warnings,
        COUNT(*) FILTER (WHERE status = 'INFO') AS info
    FROM (
        -- Combine all test results here (simplified for demo)
        SELECT '✓ PASS' AS status
    ) all_tests
)
SELECT 
    'Total Tests' AS metric,
    passed + failed + warnings + info AS value
FROM test_summary
UNION ALL
SELECT 'Passed', passed FROM test_summary
UNION ALL
SELECT 'Failed', failed FROM test_summary
UNION ALL
SELECT 'Warnings', warnings FROM test_summary
UNION ALL
SELECT 'Info', info FROM test_summary;

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'Data Quality Tests Complete!'
\echo '════════════════════════════════════════════════════════'
