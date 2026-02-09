-- ============================================================================
-- Finance Analytics Database - Seed Data
-- ============================================================================
-- Description: Populates database with realistic sample data
-- Author: Your Name
-- Date: 2024
-- ============================================================================

-- ============================================================================
-- INSERT USERS
-- ============================================================================

INSERT INTO users (email, first_name, last_name) VALUES
('adamfarahx@email.com', 'Adam', 'Farah'),
('jane.smith@email.com', 'Jane', 'Smith'),
('mike.johnson@email.com', 'Mike', 'Johnson');

-- ============================================================================
-- INSERT CATEGORIES
-- ============================================================================

-- Main categories
INSERT INTO categories (category_name, category_type, description) VALUES
-- Income categories
('Salary', 'income', 'Regular employment income'),
('Freelance', 'income', 'Freelance or contract work'),
('Investment Income', 'income', 'Dividends, interest, capital gains'),
('Other Income', 'income', 'Miscellaneous income'),

-- Expense categories - Housing
('Housing', 'expense', 'Housing-related expenses'),
('Utilities', 'expense', 'Utilities and services'),
('Internet & Phone', 'expense', 'Communication services'),

-- Expense categories - Food
('Food & Dining', 'expense', 'Food-related expenses'),
('Transportation', 'expense', 'Transportation costs'),
('Healthcare', 'expense', 'Medical and health expenses'),
('Entertainment', 'expense', 'Entertainment and leisure'),
('Shopping', 'expense', 'General shopping'),
('Personal Care', 'expense', 'Personal care and grooming'),
('Education', 'expense', 'Educational expenses'),
('Insurance', 'expense', 'Insurance premiums'),
('Savings & Investments', 'expense', 'Savings and investment contributions'),
('Debt Payments', 'expense', 'Loan and credit card payments'),
('Miscellaneous', 'expense', 'Other expenses');

-- Subcategories (using parent_category_id)
INSERT INTO categories (category_name, category_type, parent_category_id, description)
SELECT 'Rent', 'expense', category_id, 'Monthly rent payments'
FROM categories WHERE category_name = 'Housing';

INSERT INTO categories (category_name, category_type, parent_category_id, description)
SELECT 'Mortgage', 'expense', category_id, 'Mortgage payments'
FROM categories WHERE category_name = 'Housing';

INSERT INTO categories (category_name, category_type, parent_category_id, description)
SELECT 'Groceries', 'expense', category_id, 'Grocery shopping'
FROM categories WHERE category_name = 'Food & Dining';

INSERT INTO categories (category_name, category_type, parent_category_id, description)
SELECT 'Restaurants', 'expense', category_id, 'Dining out'
FROM categories WHERE category_name = 'Food & Dining';

INSERT INTO categories (category_name, category_type, parent_category_id, description)
SELECT 'Gas', 'expense', category_id, 'Vehicle fuel'
FROM categories WHERE category_name = 'Transportation';

INSERT INTO categories (category_name, category_type, parent_category_id, description)
SELECT 'Public Transit', 'expense', category_id, 'Bus, train, subway'
FROM categories WHERE category_name = 'Transportation';

-- ============================================================================
-- INSERT ACCOUNTS
-- ============================================================================

-- Accounts for Adam Farah
INSERT INTO accounts (user_id, account_name, account_type, balance, institution_name, account_number_last4)
SELECT user_id, 'Barclays Current Account', 'checking', 5430.25, 'Barclays', '4892'
FROM users WHERE email = 'adamfarahx@email.com';

INSERT INTO accounts (user_id, account_name, account_type, balance, institution_name, account_number_last4)
SELECT user_id, 'Barclays Saving Account', 'savings', 15000.00, 'Barclays', '7731'
FROM users WHERE email = 'adamfarahx@email.com';

INSERT INTO accounts (user_id, account_name, account_type, balance, institution_name, account_number_last4)
SELECT user_id, 'Natwest Credit Card', 'credit_card', -1250.80, 'NatWest', '3421'
FROM users WHERE email = 'mike.johnson@email.com';

-- Accounts for Jane Smith
INSERT INTO accounts (user_id, account_name, account_type, balance, institution_name, account_number_last4)
SELECT user_id, 'Llyods Current Account', 'checking', 8920.50, 'Lloyds', '5566'
FROM users WHERE email = 'jane.smith@email.com';

INSERT INTO accounts (user_id, account_name, account_type, balance, institution_name, account_number_last4)
SELECT user_id, 'Santander Investment', 'investment', 45000.00, 'Santander', '8899'
FROM users WHERE email = 'jane.smith@email.com';

-- Accounts for Mike Johnson
INSERT INTO accounts (user_id, account_name, account_type, balance, institution_name, account_number_last4)
SELECT user_id, 'Halifax Current Account', 'checking', 3250.75, 'Halifax', '1122'
FROM users WHERE email = 'mike.johnson@email.com';

-- ============================================================================
-- INSERT TRANSACTIONS (Last 90 days of data)
-- ============================================================================

-- John's salary (monthly income)
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    DATE '2024-01-01',
    5500.00,
    'credit',
    'Monthly salary deposit',
    'Amazon'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Salary';

INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    DATE '2024-02-01',
    5500.00,
    'credit',
    'Monthly salary deposit',
    'Amazon'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Salary';

-- John's rent payments
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    DATE '2024-01-01',
    1800.00,
    'debit',
    'Monthly rent payment',
    'Quintain Living Ltd'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Rent';

INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    DATE '2024-02-01',
    1800.00,
    'debit',
    'Monthly rent payment',
    'Quintain Living Ltd'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Rent';

-- Groceries (multiple transactions)
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    CURRENT_DATE - (random() * 90)::INTEGER,
    (random() * 150 + 30)::DECIMAL(12,2),
    'debit',
    'Grocery shopping',
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN 'Waitrose'
        WHEN 1 THEN 'Tesco'
        ELSE 'Sainsburys'
    END
FROM accounts a
CROSS JOIN categories c
CROSS JOIN generate_series(1, 20)
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Groceries';

-- Restaurant dining
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    CURRENT_DATE - (random() * 90)::INTEGER,
    (random() * 80 + 15)::DECIMAL(12,2),
    'debit',
    'Dining out',
    CASE (random() * 5)::INTEGER
        WHEN 0 THEN 'Subway'
        WHEN 1 THEN 'Olive Garden'
        WHEN 2 THEN 'Starbucks'
        WHEN 3 THEN 'Swiss Butter'
        ELSE 'Pizza Hut'
    END
FROM accounts a
CROSS JOIN categories c
CROSS JOIN generate_series(1, 15)
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Restaurants';

-- Gas/Transportation
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    CURRENT_DATE - (random() * 90)::INTEGER,
    (random() * 60 + 30)::DECIMAL(12,2),
    'debit',
    'Fuel purchase',
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN 'Shell Gas Station'
        WHEN 1 THEN 'Esso'
        ELSE 'BP Gas'
    END
FROM accounts a
CROSS JOIN categories c
CROSS JOIN generate_series(1, 12)
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Gas';

-- Utilities
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    DATE '2024-01-15',
    125.50,
    'debit',
    'Electric bill',
    'British Gas Ltd'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Utilities';

INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    DATE '2024-01-15',
    89.99,
    'debit',
    'Internet service',
    'Virgin Media Ltd'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Internet & Phone';

-- Entertainment/Shopping
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    CURRENT_DATE - (random() * 90)::INTEGER,
    (random() * 100 + 10)::DECIMAL(12,2),
    'debit',
    'Online purchase',
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'Argos'
        WHEN 1 THEN 'H&M'
        WHEN 2 THEN 'Currys'
        ELSE 'Apple Store'
    END
FROM accounts a
CROSS JOIN categories c
CROSS JOIN generate_series(1, 10)
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Shopping';

-- Credit card transactions for John
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    CURRENT_DATE - (random() * 60)::INTEGER,
    (random() * 200 + 20)::DECIMAL(12,2),
    'debit',
    'Credit card purchase',
    'Various Merchants'
FROM accounts a
CROSS JOIN categories c
CROSS JOIN generate_series(1, 8)
WHERE a.account_name = 'Natwest Credit Card'
    AND c.category_name = 'Shopping';

-- Jane's transactions
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    DATE '2024-02-01',
    7200.00,
    'credit',
    'Monthly salary',
    'JP Morgan'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Llyods Current Account'
    AND c.category_name = 'Salary';

INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type, description, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    CURRENT_DATE - (random() * 90)::INTEGER,
    (random() * 120 + 40)::DECIMAL(12,2),
    'debit',
    'Grocery shopping',
    'Waitrose'
FROM accounts a
CROSS JOIN categories c
CROSS JOIN generate_series(1, 15)
WHERE a.account_name = 'Llyods Current Account'
    AND c.category_name = 'Groceries';

-- ============================================================================
-- INSERT BUDGETS
-- ============================================================================

-- John's budgets for current month
INSERT INTO budgets (user_id, category_id, amount, start_date, end_date)
SELECT 
    u.user_id,
    c.category_id,
    600.00,
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
FROM users u
CROSS JOIN categories c
WHERE u.email = 'adamfarahx@email.com'
    AND c.category_name = 'Groceries';

INSERT INTO budgets (user_id, category_id, amount, start_date, end_date)
SELECT 
    u.user_id,
    c.category_id,
    300.00,
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
FROM users u
CROSS JOIN categories c
WHERE u.email = 'adamfarahx@email.com'
    AND c.category_name = 'Restaurants';

INSERT INTO budgets (user_id, category_id, amount, start_date, end_date)
SELECT 
    u.user_id,
    c.category_id,
    200.00,
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
FROM users u
CROSS JOIN categories c
WHERE u.email = 'adamfarahx@email.com'
    AND c.category_name = 'Gas';

INSERT INTO budgets (user_id, category_id, amount, start_date, end_date)
SELECT 
    u.user_id,
    c.category_id,
    250.00,
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
FROM users u
CROSS JOIN categories c
WHERE u.email = 'adamfarahx@email.com'
    AND c.category_name = 'Entertainment';

-- Jane's budgets
INSERT INTO budgets (user_id, category_id, amount, start_date, end_date)
SELECT 
    u.user_id,
    c.category_id,
    800.00,
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE
FROM users u
CROSS JOIN categories c
WHERE u.email = 'jane.smith@email.com'
    AND c.category_name = 'Groceries';

-- ============================================================================
-- INSERT RECURRING TRANSACTIONS
-- ============================================================================

-- John's recurring bills
INSERT INTO recurring_transactions (account_id, category_id, amount, description, frequency, start_date, next_occurrence, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    1800.00,
    'Monthly rent payment',
    'monthly',
    DATE '2024-01-01',
    DATE_TRUNC('month', CURRENT_DATE)::DATE + INTERVAL '1 month',
    'Quintain Living Ltd'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Rent';

INSERT INTO recurring_transactions (account_id, category_id, amount, description, frequency, start_date, next_occurrence, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    89.99,
    'Internet service',
    'monthly',
    DATE '2024-01-01',
    DATE_TRUNC('month', CURRENT_DATE)::DATE + INTERVAL '1 month',
    'Virgin Media Ltd'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Internet & Phone';

INSERT INTO recurring_transactions (account_id, category_id, amount, description, frequency, start_date, next_occurrence, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    14.99,
    'Netflix subscription',
    'monthly',
    DATE '2024-01-01',
    DATE_TRUNC('month', CURRENT_DATE)::DATE + INTERVAL '1 month',
    'Netflix'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Entertainment';

INSERT INTO recurring_transactions (account_id, category_id, amount, description, frequency, start_date, next_occurrence, merchant_name)
SELECT 
    a.account_id,
    c.category_id,
    9.99,
    'Spotify Premium',
    'monthly',
    DATE '2024-01-01',
    DATE_TRUNC('month', CURRENT_DATE)::DATE + INTERVAL '1 month',
    'Spotify'
FROM accounts a
CROSS JOIN categories c
WHERE a.account_name = 'Barclays Current Account'
    AND c.category_name = 'Entertainment';

-- ============================================================================
-- REFRESH MATERIALIZED VIEWS
-- ============================================================================

SELECT refresh_all_materialized_views();

-- ============================================================================
-- SUCCESS MESSAGE & SUMMARY
-- ============================================================================

DO $$
DECLARE
    user_count INTEGER;
    category_count INTEGER;
    account_count INTEGER;
    transaction_count INTEGER;
    budget_count INTEGER;
    recurring_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO category_count FROM categories;
    SELECT COUNT(*) INTO account_count FROM accounts;
    SELECT COUNT(*) INTO transaction_count FROM transactions;
    SELECT COUNT(*) INTO budget_count FROM budgets;
    SELECT COUNT(*) INTO recurring_count FROM recurring_transactions;
    
    RAISE NOTICE '════════════════════════════════════════════════════════';
    RAISE NOTICE '✓ Sample data loaded successfully!';
    RAISE NOTICE '════════════════════════════════════════════════════════';
    RAISE NOTICE 'Data Summary:';
    RAISE NOTICE '  • Users: %', user_count;
    RAISE NOTICE '  • Categories: %', category_count;
    RAISE NOTICE '  • Accounts: %', account_count;
    RAISE NOTICE '  • Transactions: %', transaction_count;
    RAISE NOTICE '  • Budgets: %', budget_count;
    RAISE NOTICE '  • Recurring Transactions: %', recurring_count;
    RAISE NOTICE '════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'Try these queries:';
    RAISE NOTICE '  SELECT * FROM v_account_overview;';
    RAISE NOTICE '  SELECT * FROM v_monthly_spending LIMIT 10;';
    RAISE NOTICE '  SELECT * FROM v_current_budget_status;';
    RAISE NOTICE '  SELECT * FROM v_upcoming_bills;';
END $$;
