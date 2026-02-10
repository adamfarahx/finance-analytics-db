-- ============================================================================
-- Finance Analytics Database - Quick Reference Guide
-- ============================================================================
-- Handy commands and queries for daily use
-- ============================================================================

-- ============================================================================
-- DATABASE SETUP & CONNECTION
-- ============================================================================

-- Create database (run in terminal)
-- createdb finance_analytics_db

-- Connect to database (run in terminal)
-- psql -d finance_analytics_db

-- Run setup (run in terminal)
-- psql -d finance_analytics_db -f 00_master_setup.sql

-- List all tables
\dt

-- Describe a table
\d transactions

-- List all views
\dv

-- List materialized views
\dm

-- List all functions
\df

-- ============================================================================
-- QUICK DATA INSERTION
-- ============================================================================

-- Add a new user
INSERT INTO users (email, first_name, last_name) 
VALUES ('new.user@email.com', 'New', 'User');

-- Add a new account
INSERT INTO accounts (user_id, account_name, account_type, balance)
SELECT user_id, 'New Account', 'checking', 1000.00
FROM users WHERE email = 'new.user@email.com';

-- Add a transaction (balance updates automatically via trigger)
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, merchant_name, description)
SELECT 
    a.account_id,
    c.category_id,
    CURRENT_DATE,
    75.50,
    'debit',
    'Target',
    'Shopping'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'New Account'
    AND c.category_name = 'Shopping'
LIMIT 1;

-- Add a budget for current month
INSERT INTO budgets (user_id, category_id, amount, start_date, end_date)
SELECT 
    u.user_id,
    c.category_id,
    500.00,
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
FROM users u
CROSS JOIN categories c
WHERE u.email = 'new.user@email.com'
    AND c.category_name = 'Groceries';

-- Add a recurring transaction
INSERT INTO recurring_transactions (account_id, category_id, amount, description, frequency, start_date, next_occurrence, merchant_name)
SELECT 
    account_id,
    c.category_id,
    15.99,
    'Netflix subscription',
    'monthly',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '1 month',
    'Netflix'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'New Account'
    AND c.category_name = 'Entertainment'
LIMIT 1;


-- ============================================================================
-- USEFUL UPDATES
-- ============================================================================

-- Categorize an uncategorized transaction
UPDATE transactions
SET category_id = (SELECT category_id FROM categories WHERE category_name = 'Groceries')
WHERE transaction_id = 'your-transaction-uuid-here';

-- Mark account as inactive (soft delete)
UPDATE accounts
SET is_active = FALSE
WHERE account_name = 'Old Account';

-- Update user email
UPDATE users
SET email = 'new.email@example.com'
WHERE email = 'old.email@example.com';

-- Deactivate a recurring transaction
UPDATE recurring_transactions
SET is_active = FALSE
WHERE description = 'Cancelled subscription';

-- ============================================================================
-- DATA ANALYSIS SHORTCUTS
-- ============================================================================

-- Total spending this month
SELECT SUM(amount) AS total_spent
FROM transactions
WHERE transaction_type = 'debit'
    AND transaction_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE;

-- Total income this month
SELECT SUM(amount) AS total_income
FROM transactions
WHERE transaction_type = 'credit'
    AND transaction_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE;

-- Net cash flow this month
SELECT 
    SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END) AS net_cash_flow
FROM transactions
WHERE transaction_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE;

-- Account with highest spending
SELECT 
    a.account_name,
    SUM(t.amount) AS total_spent
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
WHERE t.transaction_type = 'debit'
    AND t.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY a.account_name
ORDER BY total_spent DESC
LIMIT 1;

-- Most expensive purchase this month
SELECT 
    transaction_date,
    merchant_name,
    amount,
    description
FROM transactions
WHERE transaction_type = 'debit'
    AND transaction_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE
ORDER BY amount DESC
LIMIT 1;

-- ============================================================================
-- SEARCH OPERATIONS
-- ============================================================================

-- Find transactions by merchant (partial match)
SELECT 
    transaction_date,
    merchant_name,
    amount,
    description
FROM transactions
WHERE merchant_name ILIKE '%amazon%'
ORDER BY transaction_date DESC;

-- Find transactions by amount range
SELECT 
    transaction_date,
    merchant_name,
    amount,
    c.category_name
FROM transactions t
LEFT JOIN categories c ON t.category_id = c.category_id
WHERE amount BETWEEN 50 AND 100
ORDER BY transaction_date DESC;

-- Find transactions without category
SELECT 
    transaction_date,
    merchant_name,
    amount,
    description
FROM transactions
WHERE category_id IS NULL
ORDER BY transaction_date DESC;

-- ============================================================================
-- BACKUP & EXPORT
-- ============================================================================

-- Export transactions to CSV (run in psql)
-- \copy (SELECT * FROM transactions ORDER BY transaction_date) TO 'transactions.csv' CSV HEADER

-- Export monthly spending report (run in psql)
-- \copy (SELECT * FROM v_monthly_spending) TO 'monthly_spending.csv' CSV HEADER

-- Backup database (run in terminal)
-- pg_dump finance_analytics_db > backup_$(date +%Y%m%d).sql

-- Restore database (run in terminal)
-- psql -d finance_analytics_db < backup_20240101.sql

-- ============================================================================
-- HELPFUL PSQL COMMANDS
-- ============================================================================

-- Show query execution time
-- \timing

-- Expanded display (better for wide results)
-- \x

-- Save query results to file
-- \o output.txt
-- [run your query]
-- \o

-- Show current database
-- SELECT current_database();

-- Show current user
-- SELECT current_user;

-- List all databases
-- \l

-- Quit psql
-- \q

-- Get help on SQL commands
-- \h SELECT

-- Get help on psql commands
-- \?

-- ============================================================================
-- END OF QUICK REFERENCE
-- ============================================================================
