-- ============================================================================
-- Finance Analytics Database - Index Creation Script
-- ============================================================================
-- Description: Creates indexes for query performance optimization
-- Author: Your Name
-- Date: 2024
-- ============================================================================

-- ============================================================================
-- TRANSACTIONS TABLE INDEXES
-- ============================================================================
-- Most queried table - needs comprehensive indexing strategy

-- Date-based queries (most common pattern)
CREATE INDEX idx_transactions_date 
ON transactions(transaction_date DESC);

COMMENT ON INDEX idx_transactions_date IS 'Optimizes date range queries and ORDER BY date';

-- Foreign key indexes (critical for JOIN performance)
CREATE INDEX idx_transactions_account 
ON transactions(account_id);

CREATE INDEX idx_transactions_category 
ON transactions(category_id);

-- Composite index for common query pattern: filter by account and date
CREATE INDEX idx_transactions_account_date 
ON transactions(account_id, transaction_date DESC);

COMMENT ON INDEX idx_transactions_account_date IS 'Optimizes queries filtering by both account and date';

-- Index for merchant analysis queries
CREATE INDEX idx_transactions_merchant 
ON transactions(merchant_name) 
WHERE merchant_name IS NOT NULL;

COMMENT ON INDEX idx_transactions_merchant IS 'Partial index - only for non-null merchants';

-- Index for transaction type filtering
CREATE INDEX idx_transactions_type_date 
ON transactions(transaction_type, transaction_date DESC);

-- ============================================================================
-- ACCOUNTS TABLE INDEXES
-- ============================================================================

-- Foreign key to users
CREATE INDEX idx_accounts_user 
ON accounts(user_id);

-- Filter active accounts
CREATE INDEX idx_accounts_active 
ON accounts(user_id, is_active) 
WHERE is_active = TRUE;

COMMENT ON INDEX idx_accounts_active IS 'Partial index for active accounts only';

-- ============================================================================
-- BUDGETS TABLE INDEXES
-- ============================================================================

-- Composite index for budget lookups
CREATE INDEX idx_budgets_user_dates 
ON budgets(user_id, start_date, end_date);

COMMENT ON INDEX idx_budgets_user_dates IS 'Optimizes budget period queries';

-- Category-based budget queries
CREATE INDEX idx_budgets_category 
ON budgets(category_id);

-- ============================================================================
-- RECURRING_TRANSACTIONS TABLE INDEXES
-- ============================================================================

-- Find upcoming recurring transactions
CREATE INDEX idx_recurring_next_occurrence 
ON recurring_transactions(next_occurrence) 
WHERE is_active = TRUE;

COMMENT ON INDEX idx_recurring_next_occurrence IS 'Optimizes queries for upcoming bills/subscriptions';

-- Account-based recurring transaction queries
CREATE INDEX idx_recurring_account 
ON recurring_transactions(account_id);

-- ============================================================================
-- CATEGORIES TABLE INDEXES
-- ============================================================================

-- Self-referencing foreign key
CREATE INDEX idx_categories_parent 
ON categories(parent_category_id) 
WHERE parent_category_id IS NOT NULL;

-- Category type filtering
CREATE INDEX idx_categories_type 
ON categories(category_type);

-- ============================================================================
-- ANALYZE TABLES
-- ============================================================================
-- Update statistics for query planner
ANALYZE users;
ANALYZE categories;
ANALYZE accounts;
ANALYZE transactions;
ANALYZE budgets;
ANALYZE recurring_transactions;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
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
