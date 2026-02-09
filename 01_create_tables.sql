-- ============================================================================
-- Finance Analytics Database - Table Creation Script
-- ============================================================================
-- Description: Creates all core tables for personal finance analytics
-- Author: Your Name
-- Date: 2024
-- ============================================================================

-- Drop existing tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS recurring_transactions CASCADE;
DROP TABLE IF EXISTS budgets CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- USERS TABLE
-- ============================================================================
-- Stores user account information
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE users IS 'Stores user account information';
COMMENT ON COLUMN users.user_id IS 'Unique identifier for each user using UUID';
COMMENT ON COLUMN users.email IS 'User email address - must be unique';

-- ============================================================================
-- CATEGORIES TABLE
-- ============================================================================
-- Stores transaction categories with hierarchical support
CREATE TABLE categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name VARCHAR(100) UNIQUE NOT NULL,
    category_type VARCHAR(20) NOT NULL CHECK (category_type IN ('income', 'expense')),
    parent_category_id UUID REFERENCES categories(category_id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE categories IS 'Transaction categories with hierarchical structure support';
COMMENT ON COLUMN categories.parent_category_id IS 'Self-referencing FK for subcategories';
COMMENT ON COLUMN categories.category_type IS 'Distinguishes between income and expense categories';

-- ============================================================================
-- ACCOUNTS TABLE
-- ============================================================================
-- Stores financial accounts (checking, savings, credit cards, etc.)
CREATE TABLE accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN ('checking', 'savings', 'credit_card', 'investment', 'cash')),
    balance DECIMAL(12, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'GBP',
    institution_name VARCHAR(100),
    account_number_last4 VARCHAR(4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE accounts IS 'Financial accounts belonging to users';
COMMENT ON COLUMN accounts.balance IS 'Current account balance - updated via triggers';
COMMENT ON COLUMN accounts.account_number_last4 IS 'Last 4 digits for identification (PCI compliance)';
COMMENT ON COLUMN accounts.is_active IS 'Soft delete flag - preserves historical data';

-- ============================================================================
-- TRANSACTIONS TABLE
-- ============================================================================
-- Core fact table storing all financial transactions
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(category_id) ON DELETE SET NULL,
    transaction_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount != 0),
    description VARCHAR(255),
    transaction_type VARCHAR(10) NOT NULL CHECK (transaction_type IN ('debit', 'credit')),
    merchant_name VARCHAR(100),
    is_recurring BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Prevent duplicate transactions from imports
    CONSTRAINT unique_transaction UNIQUE(account_id, transaction_date, amount, merchant_name)
);

COMMENT ON TABLE transactions IS 'Core fact table - all financial transactions';
COMMENT ON COLUMN transactions.transaction_date IS 'Date transaction occurred (not when recorded)';
COMMENT ON COLUMN transactions.amount IS 'Transaction amount - always positive, type determines direction';
COMMENT ON COLUMN transactions.transaction_type IS 'debit = money out, credit = money in';
COMMENT ON CONSTRAINT unique_transaction ON transactions IS 'Prevents duplicate transaction imports';

-- ============================================================================
-- BUDGETS TABLE
-- ============================================================================
-- Stores budget allocations by category and time period
CREATE TABLE budgets (
    budget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_category_period UNIQUE(user_id, category_id, start_date),
    CONSTRAINT valid_date_range CHECK (end_date > start_date)
);

COMMENT ON TABLE budgets IS 'Budget allocations by category and time period';
COMMENT ON CONSTRAINT valid_date_range ON budgets IS 'Ensures end date is after start date';

-- ============================================================================
-- RECURRING_TRANSACTIONS TABLE
-- ============================================================================
-- Manages recurring transactions like subscriptions and bills
CREATE TABLE recurring_transactions (
    recurring_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(category_id) ON DELETE SET NULL,
    amount DECIMAL(12, 2) NOT NULL,
    description VARCHAR(255) NOT NULL,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    next_occurrence DATE NOT NULL,
    merchant_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE recurring_transactions IS 'Manages recurring transactions and subscriptions';
COMMENT ON COLUMN recurring_transactions.next_occurrence IS 'Next expected transaction date';
COMMENT ON COLUMN recurring_transactions.end_date IS 'NULL for ongoing subscriptions';

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✓ All tables created successfully!';
    RAISE NOTICE '  - users';
    RAISE NOTICE '  - categories';
    RAISE NOTICE '  - accounts';
    RAISE NOTICE '  - transactions';
    RAISE NOTICE '  - budgets';
    RAISE NOTICE '  - recurring_transactions';
END $$;
