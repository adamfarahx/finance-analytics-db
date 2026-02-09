-- ============================================================================
-- Finance Analytics Database - Views and Materialized Views
-- ============================================================================
-- Description: Creates views for common analytical queries
-- Author: Your Name
-- Date: 2024
-- ============================================================================

-- ============================================================================
-- REGULAR VIEWS (Dynamic - always current data)
-- ============================================================================

-- Monthly spending summary by category
CREATE OR REPLACE VIEW v_monthly_spending AS
SELECT 
    DATE_TRUNC('month', transaction_date)::DATE AS month,
    c.category_name,
    c.category_type,
    COUNT(*) AS transaction_count,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS avg_amount,
    MIN(t.amount) AS min_amount,
    MAX(t.amount) AS max_amount
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_type = 'debit'
GROUP BY DATE_TRUNC('month', transaction_date)::DATE, c.category_name, c.category_type
ORDER BY month DESC, total_amount DESC;

COMMENT ON VIEW v_monthly_spending IS 'Monthly spending breakdown by category';

-- Account overview with transaction counts
CREATE OR REPLACE VIEW v_account_overview AS
SELECT 
    u.email,
    u.first_name,
    u.last_name,
    a.account_name,
    a.account_type,
    a.balance,
    a.currency,
    COUNT(t.transaction_id) AS total_transactions,
    MAX(t.transaction_date) AS last_transaction_date,
    a.is_active
FROM accounts a
JOIN users u ON a.user_id = u.user_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY u.email, u.first_name, u.last_name, a.account_name, 
         a.account_type, a.balance, a.currency, a.is_active
ORDER BY u.email, a.account_name;

COMMENT ON VIEW v_account_overview IS 'Complete account overview with transaction summary';

-- Current month budget status
CREATE OR REPLACE VIEW v_current_budget_status AS
SELECT 
    u.email,
    c.category_name,
    b.amount AS budget_amount,
    COALESCE(SUM(t.amount), 0) AS spent_amount,
    b.amount - COALESCE(SUM(t.amount), 0) AS remaining_amount,
    ROUND((COALESCE(SUM(t.amount), 0) / b.amount * 100)::NUMERIC, 2) AS percent_used,
    CASE 
        WHEN COALESCE(SUM(t.amount), 0) > b.amount THEN 'OVER_BUDGET'
        WHEN COALESCE(SUM(t.amount), 0) > b.amount * 0.9 THEN 'WARNING'
        ELSE 'ON_TRACK'
    END AS status,
    b.start_date,
    b.end_date
FROM budgets b
JOIN users u ON b.user_id = u.user_id
JOIN categories c ON b.category_id = c.category_id
LEFT JOIN transactions t ON 
    t.category_id = b.category_id 
    AND t.transaction_date BETWEEN b.start_date AND b.end_date
    AND t.transaction_type = 'debit'
WHERE b.start_date <= CURRENT_DATE 
    AND b.end_date >= CURRENT_DATE
GROUP BY u.email, c.category_name, b.amount, b.start_date, b.end_date
ORDER BY percent_used DESC;

COMMENT ON VIEW v_current_budget_status IS 'Real-time budget tracking for current period';

-- Upcoming recurring transactions (next 30 days)
CREATE OR REPLACE VIEW v_upcoming_bills AS
SELECT 
    a.account_name,
    rt.description,
    rt.merchant_name,
    rt.amount,
    rt.frequency,
    rt.next_occurrence,
    c.category_name,
    CURRENT_DATE - rt.next_occurrence AS days_until_due
FROM recurring_transactions rt
JOIN accounts a ON rt.account_id = a.account_id
LEFT JOIN categories c ON rt.category_id = c.category_id
WHERE rt.is_active = TRUE
    AND rt.next_occurrence BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY rt.next_occurrence;

COMMENT ON VIEW v_upcoming_bills IS 'Upcoming recurring transactions in next 30 days';

-- ============================================================================
-- MATERIALIZED VIEWS (Pre-computed - need manual refresh)
-- ============================================================================

-- Account summary statistics (expensive to calculate on-the-fly)
CREATE MATERIALIZED VIEW mv_account_summary AS
SELECT 
    a.account_id,
    a.user_id,
    a.account_name,
    a.account_type,
    a.balance AS current_balance,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE 0 END), 0) AS total_credits,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount ELSE 0 END), 0) AS total_debits,
    COALESCE(AVG(CASE WHEN t.transaction_type = 'debit' THEN t.amount END), 0) AS avg_debit,
    MIN(t.transaction_date) AS first_transaction,
    MAX(t.transaction_date) AS last_transaction
FROM accounts a
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY a.account_id, a.user_id, a.account_name, a.account_type, a.balance;

COMMENT ON MATERIALIZED VIEW mv_account_summary IS 'Pre-computed account statistics - refresh daily';

-- Create index on materialized view for fast lookups
CREATE UNIQUE INDEX idx_mv_account_summary_id ON mv_account_summary(account_id);
CREATE INDEX idx_mv_account_summary_user ON mv_account_summary(user_id);

-- Top merchants by spending (expensive aggregation)
CREATE MATERIALIZED VIEW mv_top_merchants AS
SELECT 
    merchant_name,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_spent,
    AVG(amount) AS avg_transaction,
    MIN(transaction_date) AS first_transaction,
    MAX(transaction_date) AS last_transaction,
    COUNT(DISTINCT account_id) AS accounts_used
FROM transactions
WHERE merchant_name IS NOT NULL
    AND transaction_type = 'debit'
GROUP BY merchant_name
HAVING COUNT(*) > 1
ORDER BY total_spent DESC
LIMIT 100;

COMMENT ON MATERIALIZED VIEW mv_top_merchants IS 'Top 100 merchants by total spending';

-- Category spending trends (last 12 months)
CREATE MATERIALIZED VIEW mv_category_trends AS
SELECT 
    c.category_name,
    c.category_type,
    DATE_TRUNC('month', t.transaction_date)::DATE AS month,
    COUNT(*) AS transaction_count,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS avg_amount
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '12 months'
    AND t.transaction_type = 'debit'
GROUP BY c.category_name, c.category_type, DATE_TRUNC('month', t.transaction_date)::DATE
ORDER BY month DESC, total_amount DESC;

COMMENT ON MATERIALIZED VIEW mv_category_trends IS '12-month category spending trends';

CREATE INDEX idx_mv_category_trends_month ON mv_category_trends(month DESC);
CREATE INDEX idx_mv_category_trends_category ON mv_category_trends(category_name);

-- ============================================================================
-- MATERIALIZED VIEW REFRESH FUNCTION
-- ============================================================================
-- Helper function to refresh all materialized views at once

CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_account_summary;
    REFRESH MATERIALIZED VIEW mv_top_merchants;
    REFRESH MATERIALIZED VIEW mv_category_trends;
    RAISE NOTICE 'All materialized views refreshed successfully';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_all_materialized_views() IS 'Refreshes all materialized views - run daily';

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✓ All views created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Regular Views (always current):';
    RAISE NOTICE '  - v_monthly_spending';
    RAISE NOTICE '  - v_account_overview';
    RAISE NOTICE '  - v_current_budget_status';
    RAISE NOTICE '  - v_upcoming_bills';
    RAISE NOTICE '';
    RAISE NOTICE 'Materialized Views (refresh required):';
    RAISE NOTICE '  - mv_account_summary';
    RAISE NOTICE '  - mv_top_merchants';
    RAISE NOTICE '  - mv_category_trends';
    RAISE NOTICE '';
    RAISE NOTICE 'To refresh materialized views, run:';
    RAISE NOTICE '  SELECT refresh_all_materialized_views();';
END $$;
