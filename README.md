# Personal Finance Analytics Database

A comprehensive PostgreSQL database system for tracking and analyzing personal financial transactions, demonstrating intermediate to advanced SQL concepts for financial data engineering.

##  Project Overview

This project showcases professional database design and SQL skills relevant to financial data engineering roles, including:

- **Complex schema design** with proper normalization and constraints
- **Performance optimization** through strategic indexing
- **Advanced SQL queries** using window functions, CTEs, and recursive queries
- **Data quality frameworks** with automated validation
- **Financial domain expertise** in transaction processing and reconciliation

##  Key Features

### Database Design
- UUID-based primary keys for distributed system scalability
- Foreign key constraints maintaining referential integrity
- CHECK constraints for data validation
- Unique constraints preventing duplicate transactions
- Audit trails with timestamp tracking
- Soft deletes preserving historical data

### Performance Optimization
- Strategic indexes on high-cardinality columns
- Composite indexes for common query patterns
- Materialized views for expensive aggregations
- Partial indexes for filtered queries

### Analytical Capabilities
- Monthly spending trends with year-over-year comparison
- Budget vs actual variance analysis
- Merchant spending patterns
- Category breakdown with percentages
- Cash flow analysis
- Duplicate transaction detection
- Balance reconciliation

## Database Schema

### Core Tables

**users**
- Stores user account information
- Fields: user_id (UUID), email, first_name, last_name, timestamps

**accounts**
- Financial accounts (checking, savings, credit cards, investments)
- Fields: account_id (UUID), user_id (FK), account_type, balance, currency
- Supports multiple accounts per user

**transactions** *Star Schema Fact Table*
- All financial transactions with full audit trail
- Fields: transaction_id (UUID), account_id (FK), category_id (FK), date, amount, type
- Unique constraint prevents duplicate imports
- Separate transaction_date and created_at for audit purposes

**categories**
- Hierarchical expense/income categorization
- Self-referencing foreign key for subcategories
- Fields: category_id (UUID), category_name, parent_category_id (FK)

**budgets**
- Monthly budget allocations by category
- Fields: budget_id (UUID), user_id (FK), category_id (FK), amount, date range
- Constraint ensures end_date > start_date

**recurring_transactions**
- Subscription and bill management
- Fields: recurring_id (UUID), account_id (FK), frequency, next_occurrence
- Supports automated transaction generation

### Common Queries

**View Account Overview**
```sql
SELECT * FROM v_account_overview;
```

**Check Monthly Spending**
```sql
SELECT * FROM v_monthly_spending 
ORDER BY month DESC 
LIMIT 6;
```

**Budget Status**
```sql
SELECT * FROM v_current_budget_status;
```

**Top Spending Merchants**
```sql
SELECT * FROM mv_top_merchants LIMIT 10;
```

### Data Quality Testing

```bash
psql -d finance_analytics_db -f 07_data_quality_tests.sql
```

Tests include:
- Orphaned records detection
- Balance reconciliation
- Duplicate transaction identification
- Data completeness checks
- Date validation
- NULL value detection

## Advanced Features

### Automated Balance Updates

Triggers automatically maintain account balances when transactions are added:

```sql
INSERT INTO transactions (account_id, category_id, transaction_date, amount, transaction_type)
VALUES ('account-uuid', 'category-uuid', CURRENT_DATE, 100.00, 'debit');
-- Account balance automatically decreases by $100
```

### Duplicate Prevention with UPSERT

```sql
INSERT INTO transactions (account_id, transaction_date, amount, merchant_name)
VALUES ('account-uuid', '2024-01-15', 50.00, 'Coffee Shop')
ON CONFLICT (account_id, transaction_date, amount, merchant_name)
DO UPDATE SET updated_at = CURRENT_TIMESTAMP;
-- Prevents duplicate import, updates timestamp instead
```

### Processing Recurring Transactions

```sql
-- Call this function daily to auto-generate bills
SELECT process_recurring_transactions();
```

### Refreshing Materialized Views

```sql
-- Refresh all at once
SELECT refresh_all_materialized_views();

-- Or refresh individually
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_account_summary;
```

## Project Structure

```
finance-analytics-db/
├── 00_master_setup.sql          # Master setup script (runs all)
├── 01_create_tables.sql          # Table definitions with constraints
├── 02_create_indexes.sql         # Performance indexes
├── 03_create_views.sql           # Views and materialized views
├── 04_create_triggers.sql        # Triggers and functions
├── 05_seed_data.sql              # Sample data
├── 06_analytical_queries.sql     # 12+ analytical queries
├── 07_data_quality_tests.sql     # 15+ data quality tests
└── README.md                     # This file
```

## SQL Skills Demonstrated

### Core SQL
-  CREATE TABLE with constraints (PRIMARY KEY, FOREIGN KEY, CHECK, UNIQUE)
-  INSERT, UPDATE, DELETE, SELECT
-  WHERE clauses with complex conditions
-  JOINs (INNER, LEFT, CROSS)
-  Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
-  GROUP BY and HAVING
-  ORDER BY with multiple columns

### Intermediate SQL
-  Subqueries and derived tables
-  CASE statements
-  COALESCE and NULLIF
-  String functions and date arithmetic
-  CREATE INDEX with various strategies
-  CREATE VIEW
-  UUID generation (gen_random_uuid)

### Advanced SQL
-  Window functions (ROW_NUMBER, RANK, LAG, LEAD)
-  Common Table Expressions (CTEs)
-  Recursive CTEs for hierarchical data
-  Materialized views with refresh
-  Triggers and functions (PL/pgSQL)
-  ON CONFLICT (UPSERT)
-  Partial indexes
-  Self-referencing foreign keys
-  Array aggregation

### Financial Domain Knowledge
- DECIMAL precision for monetary values (never FLOAT!)
-  Transaction types (debit/credit)
-  Balance reconciliation
-  Duplicate transaction detection
-  Audit trails (created_at vs transaction_date)
-  Soft deletes for compliance
-  Budget variance analysis

## Contact

[Adam Farah]
[adamfarahx@gmail.com]
[adamfarahx]

---

**Built with PostgreSQL** 

**Project completed**: [9/2/2026]  
**Time invested**: [70 hours]  
**Skills demonstrated**: Database Design, SQL, Financial Data Engineering, Data Quality

---

## License
This is a portfolio project for educational and demonstration purposes.

---

## finance-analytics-db
PostgreSQL database for financial transaction analytics with advanced SQL queries.
>>>>>>> 049b19d19cc304a71a6120a401193903f977b3b6

