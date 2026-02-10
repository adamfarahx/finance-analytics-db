-- ============================================================================
-- Finance Analytics Database - Analytical Queries
-- ============================================================================
-- Description: Complex SQL queries for financial analysis and insights


-- ============================================================================
-- QUERY 1: Monthly Spending Trends with Year-over-Year Comparison
-- ============================================================================
-- Business Question: How does monthly spending compare to previous months?
-- Demonstrates: Window functions (LAG), aggregation, percent change calculation

SELECT 
    TO_CHAR(transaction_date, 'YYYY-MM') AS month,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_spent,
    AVG(amount) AS avg_transaction,
    ROUND(AVG(amount)::NUMERIC, 2) AS avg_transaction_rounded,
    -- Previous month comparison
    LAG(SUM(amount)) OVER (ORDER BY TO_CHAR(transaction_date, 'YYYY-MM')) AS previous_month_spending,
    -- Percent change from previous month
    ROUND(
        ((SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY TO_CHAR(transaction_date, 'YYYY-MM'))) 
        / NULLIF(LAG(SUM(amount)) OVER (ORDER BY TO_CHAR(transaction_date, 'YYYY-MM')), 0) * 100)::NUMERIC, 
        2
    ) AS percent_change
FROM transactions
WHERE transaction_type = 'debit'
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY month DESC
LIMIT 12;

-- ============================================================================
-- QUERY 2: Budget vs Actual Spending Analysis
-- ============================================================================
-- Business Question: Are we staying within budget? Which categories are overspent?
-- Demonstrates: JOINs, COALESCE, CASE statements, aggregate functions

SELECT 
    u.first_name || ' ' || u.last_name AS user_name,
    c.category_name,
    b.amount AS budgeted_amount,
    COALESCE(SUM(t.amount), 0) AS actual_spending,
    b.amount - COALESCE(SUM(t.amount), 0) AS remaining_budget,
    ROUND((COALESCE(SUM(t.amount), 0) / b.amount * 100)::NUMERIC, 2) AS percent_used,
    CASE 
        WHEN COALESCE(SUM(t.amount), 0) > b.amount THEN 'OVER BUDGET'
        WHEN COALESCE(SUM(t.amount), 0) > b.amount * 0.9 THEN 'WARNING (>90%)'
        WHEN COALESCE(SUM(t.amount), 0) > b.amount * 0.75 THEN 'On Track (75-90%)'
        ELSE '✓ Well Under Budget'
    END AS status
FROM budgets b
JOIN users u ON b.user_id = u.user_id
JOIN categories c ON b.category_id = c.category_id
LEFT JOIN transactions t ON 
    t.category_id = b.category_id 
    AND t.transaction_date BETWEEN b.start_date AND b.end_date
    AND t.transaction_type = 'debit'
WHERE b.start_date <= CURRENT_DATE 
    AND b.end_date >= CURRENT_DATE
GROUP BY u.user_id, u.first_name, u.last_name, c.category_name, b.amount
ORDER BY percent_used DESC;

-- ============================================================================
-- QUERY 3: Top Merchants by Spending
-- ============================================================================
-- Business Question: Where am I spending the most money?
-- Demonstrates: Aggregation, HAVING clause, date functions

SELECT 
    merchant_name,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_spent,
    ROUND(AVG(amount)::NUMERIC, 2) AS avg_transaction,
    MIN(transaction_date) AS first_transaction,
    MAX(transaction_date) AS last_transaction,
    MAX(transaction_date) - MIN(transaction_date) AS days_as_customer,
    -- Frequency of purchases
    ROUND(
        COUNT(*)::NUMERIC / 
        NULLIF(EXTRACT(DAY FROM (MAX(transaction_date) - MIN(transaction_date))), 0),
        2
    ) AS avg_transactions_per_day
FROM transactions
WHERE merchant_name IS NOT NULL
    AND transaction_type = 'debit'
    AND transaction_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY merchant_name
HAVING COUNT(*) > 1  -- Only show merchants with multiple transactions
ORDER BY total_spent DESC
LIMIT 20;

-- ============================================================================
-- QUERY 4: Daily Cash Flow Analysis
-- ============================================================================
-- Business Question: What's my daily cash flow pattern?
-- Demonstrates: Window functions, OVER clause, running totals

SELECT 
    transaction_date,
    SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE 0 END) AS daily_income,
    SUM(CASE WHEN transaction_type = 'debit' THEN amount ELSE 0 END) AS daily_expenses,
    SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END) AS daily_net,
    -- Running total (cumulative net cash flow)
    SUM(SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END)) 
        OVER (ORDER BY transaction_date) AS cumulative_cash_flow,
    COUNT(*) AS transaction_count
FROM transactions
WHERE transaction_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY transaction_date
ORDER BY transaction_date DESC;

-- ============================================================================
-- QUERY 5: Category Spending Breakdown with Percentages
-- ============================================================================
-- Business Question: What percentage of my spending goes to each category?
-- Demonstrates: Subqueries, window functions for percentage calculation

WITH total_spending AS (
    SELECT SUM(amount) AS total
    FROM transactions
    WHERE transaction_type = 'debit'
        AND transaction_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT 
    c.category_name,
    COUNT(*) AS transaction_count,
    SUM(t.amount) AS category_total,
    ROUND(AVG(t.amount)::NUMERIC, 2) AS avg_per_transaction,
    -- Percentage of total spending
    ROUND((SUM(t.amount) / ts.total * 100)::NUMERIC, 2) AS percent_of_total,
    -- Cumulative percentage (running total)
    ROUND(
        (SUM(SUM(t.amount)) OVER (ORDER BY SUM(t.amount) DESC) / ts.total * 100)::NUMERIC,
        2
    ) AS cumulative_percent
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
CROSS JOIN total_spending ts
WHERE t.transaction_type = 'debit'
    AND t.transaction_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY c.category_name, ts.total
ORDER BY category_total DESC;

-- ============================================================================
-- QUERY 6: Detect Potential Duplicate Transactions
-- ============================================================================
-- Business Question: Are there any duplicate transactions that might need review?
-- Demonstrates: Self-join, EXISTS, window functions

SELECT 
    t1.transaction_date,
    t1.merchant_name,
    t1.amount,
    t1.description,
    a.account_name,
    COUNT(*) OVER (
        PARTITION BY t1.account_id, t1.transaction_date, t1.amount, t1.merchant_name
    ) AS duplicate_count,
    -- Show all matching transaction IDs
    ARRAY_AGG(t2.transaction_id) OVER (
        PARTITION BY t1.account_id, t1.transaction_date, t1.amount, t1.merchant_name
    ) AS matching_transaction_ids
FROM transactions t1
JOIN accounts a ON t1.account_id = a.account_id
JOIN transactions t2 ON 
    t1.account_id = t2.account_id
    AND t1.transaction_date = t2.transaction_date
    AND t1.amount = t2.amount
    AND COALESCE(t1.merchant_name, '') = COALESCE(t2.merchant_name, '')
WHERE EXISTS (
    SELECT 1
    FROM transactions t3
    WHERE t3.account_id = t1.account_id
        AND t3.transaction_date = t1.transaction_date
        AND t3.amount = t1.amount
        AND COALESCE(t3.merchant_name, '') = COALESCE(t1.merchant_name, '')
        AND t3.transaction_id != t1.transaction_id
)
ORDER BY t1.transaction_date DESC, duplicate_count DESC;

-- ============================================================================
-- QUERY 7: Account Balance Reconciliation
-- ============================================================================
-- Business Question: Do stored balances match calculated balances from transactions?
-- Demonstrates: Aggregation, CASE, mathematical operations

SELECT 
    a.account_name,
    a.account_type,
    a.balance AS stored_balance,
    COALESCE(SUM(
        CASE 
            WHEN t.transaction_type = 'credit' THEN t.amount
            WHEN t.transaction_type = 'debit' THEN -t.amount
        END
    ), 0) AS calculated_balance,
    a.balance - COALESCE(SUM(
        CASE 
            WHEN t.transaction_type = 'credit' THEN t.amount
            WHEN t.transaction_type = 'debit' THEN -t.amount
        END
    ), 0) AS difference,
    CASE 
        WHEN ABS(a.balance - COALESCE(SUM(
            CASE 
                WHEN t.transaction_type = 'credit' THEN t.amount
                WHEN t.transaction_type = 'debit' THEN -t.amount
            END
        ), 0)) < 0.01 THEN '✓ Reconciled'
        ELSE 'Mismatch'
    END AS reconciliation_status
FROM accounts a
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY a.account_id, a.account_name, a.account_type, a.balance
ORDER BY a.account_name;

-- ============================================================================
-- QUERY 8: Week-over-Week Spending Comparison
-- ============================================================================
-- Business Question: How does this week's spending compare to previous weeks?
-- Demonstrates: DATE_TRUNC, complex window functions

SELECT 
    DATE_TRUNC('week', transaction_date)::DATE AS week_start,
    COUNT(*) AS transactions,
    SUM(amount) AS total_spent,
    ROUND(AVG(amount)::NUMERIC, 2) AS avg_transaction,
    -- Compare to previous week
    LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('week', transaction_date)) AS prev_week_spent,
    SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('week', transaction_date)) AS week_over_week_change,
    ROUND(
        ((SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('week', transaction_date))) 
        / NULLIF(LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('week', transaction_date)), 0) * 100)::NUMERIC,
        2
    ) AS percent_change
FROM transactions
WHERE transaction_type = 'debit'
    AND transaction_date >= CURRENT_DATE - INTERVAL '8 weeks'
GROUP BY DATE_TRUNC('week', transaction_date)
ORDER BY week_start DESC;


-- ============================================================================
-- QUERY 9: Income vs Expense Summary by Account
-- ============================================================================
-- Business Question: What's the financial summary for each account?
-- Demonstrates: Multiple aggregations, CASE statements

SELECT 
    u.first_name || ' ' || u.last_name AS account_holder,
    a.account_name,
    a.account_type,
    a.balance AS current_balance,
    -- Income summary
    COUNT(CASE WHEN t.transaction_type = 'credit' THEN 1 END) AS income_count,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount END), 0) AS total_income,
    -- Expense summary
    COUNT(CASE WHEN t.transaction_type = 'debit' THEN 1 END) AS expense_count,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount END), 0) AS total_expenses,
    -- Net summary
    COALESCE(
        SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE -t.amount END),
        0
    ) AS net_change,
    -- Date range
    MIN(t.transaction_date) AS first_transaction,
    MAX(t.transaction_date) AS last_transaction,
    COUNT(DISTINCT DATE_TRUNC('month', t.transaction_date)) AS months_active
FROM accounts a
JOIN users u ON a.user_id = u.user_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY u.user_id, u.first_name, u.last_name, a.account_id, a.account_name, a.account_type, a.balance
ORDER BY account_holder, a.account_name;


-- ============================================================================
-- QUERY 10: Savings Rate Calculation
-- ============================================================================
-- Business Question: What percentage of income am I saving?
-- Demonstrates: CTEs, complex calculations

WITH monthly_summary AS (
    SELECT 
        DATE_TRUNC('month', transaction_date)::DATE AS month,
        SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE 0 END) AS income,
        SUM(CASE WHEN transaction_type = 'debit' THEN amount ELSE 0 END) AS expenses
    FROM transactions
    WHERE transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', transaction_date)::DATE
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS month,
    income,
    expenses,
    income - expenses AS net_savings,
    ROUND(((income - expenses) / NULLIF(income, 0) * 100)::NUMERIC, 2) AS savings_rate_percent,
    CASE 
        WHEN ((income - expenses) / NULLIF(income, 0) * 100) >= 20 THEN 'Excellent'
        WHEN ((income - expenses) / NULLIF(income, 0) * 100) >= 10 THEN 'Good'
        WHEN ((income - expenses) / NULLIF(income, 0) * 100) >= 0 THEN 'Low'
        ELSE 'Deficit'
    END AS savings_rating
FROM monthly_summary
ORDER BY month DESC;

