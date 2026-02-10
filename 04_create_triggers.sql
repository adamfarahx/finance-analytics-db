-- ============================================================================
-- Finance Analytics Database - Triggers and Functions
-- ============================================================================
-- Description: Automated business logic and data maintenance

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_budgets_updated_at
    BEFORE UPDATE ON budgets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_recurring_updated_at
    BEFORE UPDATE ON recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();



CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT: Add transaction to balance
    IF TG_OP = 'INSERT' THEN
        UPDATE accounts
        SET balance = balance + 
            CASE 
                WHEN NEW.transaction_type = 'credit' THEN NEW.amount
                WHEN NEW.transaction_type = 'debit' THEN -NEW.amount
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE account_id = NEW.account_id;
        
        RAISE NOTICE 'Account % balance updated: % %', 
            NEW.account_id, 
            NEW.transaction_type, 
            NEW.amount;
        
        RETURN NEW;
    
    -- Handle UPDATE: Adjust for old and new amounts
    ELSIF TG_OP = 'UPDATE' THEN
        -- Reverse old transaction
        UPDATE accounts
        SET balance = balance - 
            CASE 
                WHEN OLD.transaction_type = 'credit' THEN OLD.amount
                WHEN OLD.transaction_type = 'debit' THEN -OLD.amount
            END
        WHERE account_id = OLD.account_id;
        
        -- Apply new transaction
        UPDATE accounts
        SET balance = balance + 
            CASE 
                WHEN NEW.transaction_type = 'credit' THEN NEW.amount
                WHEN NEW.transaction_type = 'debit' THEN -NEW.amount
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE account_id = NEW.account_id;
        
        RETURN NEW;
    
    -- Handle DELETE: Remove transaction from balance
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE accounts
        SET balance = balance - 
            CASE 
                WHEN OLD.transaction_type = 'credit' THEN OLD.amount
                WHEN OLD.transaction_type = 'debit' THEN -OLD.amount
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE account_id = OLD.account_id;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_update_balance_insert
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance();

CREATE TRIGGER trg_update_balance_update
    AFTER UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance();

CREATE TRIGGER trg_update_balance_delete
    AFTER DELETE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance();



CREATE OR REPLACE FUNCTION validate_transaction_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.amount = 0 THEN
        RAISE EXCEPTION 'Transaction amount cannot be zero';
    END IF;
    
    IF NEW.amount < 0 THEN
        RAISE EXCEPTION 'Transaction amount must be positive. Use transaction_type to indicate direction.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_validate_amount
    BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION validate_transaction_amount();



CREATE OR REPLACE FUNCTION calculate_next_occurrence(
    current_date DATE,
    frequency VARCHAR
)
RETURNS DATE AS $$
BEGIN
    RETURN CASE frequency
        WHEN 'daily' THEN current_date + INTERVAL '1 day'
        WHEN 'weekly' THEN current_date + INTERVAL '1 week'
        WHEN 'biweekly' THEN current_date + INTERVAL '2 weeks'
        WHEN 'monthly' THEN current_date + INTERVAL '1 month'
        WHEN 'quarterly' THEN current_date + INTERVAL '3 months'
        WHEN 'yearly' THEN current_date + INTERVAL '1 year'
        ELSE current_date
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION process_recurring_transactions()
RETURNS TABLE(processed_count INTEGER) AS $$
DECLARE
    rec_record RECORD;
    new_transaction_id UUID;
    count INTEGER := 0;
BEGIN
    -- Loop through all active recurring transactions due today or earlier
    FOR rec_record IN 
        SELECT * FROM recurring_transactions
        WHERE is_active = TRUE
        AND next_occurrence <= CURRENT_DATE
        AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    LOOP
        -- Insert the transaction
        INSERT INTO transactions (
            account_id,
            category_id,
            transaction_date,
            amount,
            description,
            transaction_type,
            merchant_name,
            is_recurring,
            notes
        ) VALUES (
            rec_record.account_id,
            rec_record.category_id,
            rec_record.next_occurrence,
            rec_record.amount,
            rec_record.description,
            'debit',  -- Recurring transactions are typically expenses
            rec_record.merchant_name,
            TRUE,
            'Auto-generated from recurring transaction'
        )
        RETURNING transaction_id INTO new_transaction_id;
        
        -- Update next occurrence
        UPDATE recurring_transactions
        SET next_occurrence = calculate_next_occurrence(next_occurrence, frequency),
            updated_at = CURRENT_TIMESTAMP
        WHERE recurring_id = rec_record.recurring_id;
        
        count := count + 1;
        
        RAISE NOTICE 'Processed recurring transaction: % (ID: %)', 
            rec_record.description, 
            new_transaction_id;
    END LOOP;
    
    RETURN QUERY SELECT count;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION reconcile_account_balance(acc_id UUID)
RETURNS TABLE(
    account_id UUID,
    stored_balance DECIMAL(12,2),
    calculated_balance DECIMAL(12,2),
    difference DECIMAL(12,2),
    is_reconciled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.account_id,
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
        ABS(a.balance - COALESCE(SUM(
            CASE 
                WHEN t.transaction_type = 'credit' THEN t.amount
                WHEN t.transaction_type = 'debit' THEN -t.amount
            END
        ), 0)) < 0.01 AS is_reconciled
    FROM accounts a
    LEFT JOIN transactions t ON a.account_id = t.account_id
    WHERE a.account_id = acc_id
    GROUP BY a.account_id, a.balance;
END;
$$ LANGUAGE plpgsql;


DO $$
BEGIN
    RAISE NOTICE '✓ All triggers and functions created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Automated Functions:';
    RAISE NOTICE '  - update_updated_at_column() - Auto-updates timestamps';
    RAISE NOTICE '  - update_account_balance() - Maintains account balances';
    RAISE NOTICE '  - validate_transaction_amount() - Validates amounts';
    RAISE NOTICE '';
    RAISE NOTICE 'Utility Functions:';
    RAISE NOTICE '  - process_recurring_transactions() - Call daily to process bills';
    RAISE NOTICE '  - reconcile_account_balance(uuid) - Verify account balance accuracy';
    RAISE NOTICE '  - calculate_next_occurrence(date, frequency) - Calculate next bill date';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage Examples:';
    RAISE NOTICE '  SELECT process_recurring_transactions();';
    RAISE NOTICE '  SELECT * FROM reconcile_account_balance(''account-uuid-here'');';
END $$;
