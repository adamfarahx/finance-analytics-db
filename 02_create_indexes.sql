-- ============================================================================
-- Finance Analytics Database - Index Creation Script
-- ============================================================================
-- Description: Creates indexes for query performance optimization
-- Definition: An index speeds up reads and slows down writes
-- Note: Every index used is critical since indexing every column
-- is counter intuitive for performance optimisation.


CREATE INDEX idx_transactions_date 
ON transactions(transaction_date DESC);

-- Foreign key indexes (critical for JOIN performance)
CREATE INDEX idx_transactions_account 
ON transactions(account_id);

CREATE INDEX idx_transactions_category 
ON transactions(category_id);

-- Composite index for common query pattern: filter by account and date
CREATE INDEX idx_transactions_account_date 
ON transactions(account_id, transaction_date DESC);

-- Index for merchant analysis queries
CREATE INDEX idx_transactions_merchant 
ON transactions(merchant_name) 
WHERE merchant_name IS NOT NULL;

-- Index for transaction type filtering
CREATE INDEX idx_transactions_type_date 
ON transactions(transaction_type, transaction_date DESC);

-- Foreign key to users
CREATE INDEX idx_accounts_user 
ON accounts(user_id);

-- Filter active accounts
CREATE INDEX idx_accounts_active 
ON accounts(user_id, is_active) 
WHERE is_active = TRUE;

-- Composite index for budget lookups
CREATE INDEX idx_budgets_user_dates 
ON budgets(user_id, start_date, end_date);

-- Category-based budget queries
CREATE INDEX idx_budgets_category 
ON budgets(category_id);

-- Find upcoming recurring transactions
CREATE INDEX idx_recurring_next_occurrence 
ON recurring_transactions(next_occurrence) 
WHERE is_active = TRUE;

-- Account-based recurring transaction queries
CREATE INDEX idx_recurring_account 
ON recurring_transactions(account_id);

-- Self-referencing foreign key
CREATE INDEX idx_categories_parent 
ON categories(parent_category_id) 
WHERE parent_category_id IS NOT NULL;

-- Category type filtering
CREATE INDEX idx_categories_type 
ON categories(category_type);


ANALYZE users;
ANALYZE categories;
ANALYZE accounts;
ANALYZE transactions;
ANALYZE budgets;
ANALYZE recurring_transactions;


DO $$
BEGIN
    RAISE NOTICE '✓ All indexes created successfully!';
    RAISE NOTICE '  - Transaction table: 6 indexes';
    RAISE NOTICE '  - Account table: 2 indexes';
    RAISE NOTICE '  - Budget table: 2 indexes';
    RAISE NOTICE '  - Recurring transactions: 2 indexes';
    RAISE NOTICE '  - Categories: 2 indexes';
    RAISE NOTICE '';
    RAISE NOTICE '✓ Statistics updated for query optimizer';
END $$;
