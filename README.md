# Finance Analytics Database

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-blue?style=for-the-badge)

> Production-ready PostgreSQL database demonstrating advanced SQL for financial data engineering roles

## Project Overview

A comprehensive financial transaction analytics system built with PostgreSQL, showcasing database design, performance optimization, and advanced SQL techniques relevant to financial data engineering at firms like JPMorgan, Goldman Sachs, and fintech companies.

**Built to demonstrate:**
- Complex schema design with proper normalization
- Performance optimization through strategic indexing
- Advanced SQL (window functions, CTEs, recursive queries)
- Data quality frameworks and automated validation
- Financial domain expertise (transaction processing, reconciliation)

**Key Metrics:**
- 6 normalized tables with foreign key relationships
- 12+ strategic indexes for query optimization
- 15+ analytical queries demonstrating advanced SQL
- 15+ automated data quality tests
- 100K+ sample transaction records

---

## Database Schema

### Core Tables

**users** - User account management
- UUID-based primary keys for distributed system scalability
- Email uniqueness constraint
- Audit timestamps

**accounts** - Financial accounts (checking, savings, credit cards, investments)
- Multi-account support per user
- DECIMAL precision for monetary values (never FLOAT!)
- Soft deletes for historical data preservation

**transactions** *Star Schema Fact Table*
- Complete audit trail with created_at vs transaction_date
- Unique constraint prevents duplicate imports
- Automated balance updates via triggers
- Transaction types: debit/credit

**categories** - Hierarchical expense/income categorization
- Self-referencing foreign key for subcategories
- Supports unlimited nesting levels

**budgets** - Monthly budget allocations
- Date range validation via CHECK constraints
- Budget vs actual variance tracking

**recurring_transactions** - Subscription and bill management
- Automated transaction generation
- Multiple frequencies: daily, weekly, monthly, quarterly, yearly

---

## Quick Start

### Prerequisites
- PostgreSQL 14+
- Command line access

### Installation
```bash
# 1. Create database
createdb finance_analytics_db

# 2. Clone repository
git clone https://github.com/adamfarahx/finance-analytics-db.git
cd finance-analytics-db

# 3. Run master setup (sets up everything automatically)
psql -d finance_analytics_db -f 00_master_setup.sql
```

### Verify Installation
```bash
psql -d finance_analytics_db

# Check tables
\dt

# View sample data
SELECT * FROM v_account_overview;
SELECT * FROM v_monthly_spending LIMIT 10;
```

---

## Features & SQL Skills Demonstrated

### Advanced SQL Techniques

  **Window Functions**
  
  Definiton: _window functions_ perform a calculation across a set of table rows that are related to the current row. This is comparable to the type of calculation that can be done with an aggregate function.
  
```sql
-- Month-over-month spending comparison with LAG
SELECT 
    month,
    total_spent,
    LAG(total_spent) OVER (ORDER BY month) AS previous_month,
    ROUND(((total_spent - LAG(total_spent) OVER (ORDER BY month)) 
        / LAG(total_spent) OVER (ORDER BY month) * 100)::NUMERIC, 2) AS percent_change
FROM monthly_summary;
```

  **Common Table Expressions (CTEs)**

  Definition: A CTE (Common Table Expression) is a named temporary result set that exists only for the duration of a single query.
  
```sql
-- Budget variance analysis with multiple CTEs
WITH budget_summary AS (...),
     actual_spending AS (...)
SELECT * FROM budget_summary JOIN actual_spending ...
```

  **Recursive Queries**

  Definition: A recursive query is a SQL query that repeatedly runs itself to process data with hierarchical or sequential relationships, stopping only when a condition is met. In SQL, recursive queries are written using a recursive CTE.
  
```sql
-- Hierarchical category navigation
WITH RECURSIVE category_tree AS (
    SELECT * FROM categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.* FROM categories c 
    JOIN category_tree ct ON c.parent_id = ct.category_id
)
SELECT * FROM category_tree;
```

### Performance Optimization

- **Strategic Indexing**: Composite indexes on `(account_id, transaction_date)` for common query patterns
- **Materialized Views**: Pre-computed aggregations for expensive analytics
- **Partial Indexes**: Filtered indexes for active records only
- **Query Analysis**: Using EXPLAIN ANALYZE for optimization

### Data Quality Framework

- Constraint-based validation (CHECK, UNIQUE, FOREIGN KEY)
- Duplicate transaction detection
- Balance reconciliation (stored vs calculated)
- Automated data quality tests (15+ validations)
- NULL value detection in required fields

### Financial Domain Knowledge

- DECIMAL precision for penny-perfect accuracy
- Transaction type handling (debit/credit)
- Audit trails (transaction_date vs created_at)
- Soft deletes for regulatory compliance
- Balance reconciliation processes

---

## 📁 Project Structure
```
finance-analytics-db/
├── 00_master_setup.sql          # Master setup (runs all scripts)
├── 01_create_tables.sql          # Table definitions with constraints
├── 02_create_indexes.sql         # Performance indexes
├── 03_create_views.sql           # Views and materialized views
├── 04_create_triggers.sql        # Triggers and functions
├── 05_seed_data.sql              # Realistic sample data
├── 06_analytical_queries.sql     # 12+ analytical queries
├── 07_data_quality_tests.sql     # 15+ validation tests
└── README.md                     # This file
```

---

## Sample Queries

### Monthly Spending Trends
```sql
SELECT * FROM v_monthly_spending 
WHERE month >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY month DESC;
```

### Budget vs Actual Analysis
```sql
SELECT 
    category_name,
    budget_amount,
    actual_spending,
    ROUND((actual_spending / budget_amount * 100)::NUMERIC, 2) AS percent_used
FROM v_current_budget_status
WHERE percent_used > 90;
```

### Top Merchants by Spending
```sql
SELECT * FROM mv_top_merchants LIMIT 10;
```

### Duplicate Transaction Detection
```sql
-- See queries/06_analytical_queries.sql for full implementation
```

---

## Testing & Validation

Run comprehensive data quality tests:
```bash
psql -d finance_analytics_db -f 07_data_quality_tests.sql
```

**Tests include:**
- Orphaned records detection
- Balance reconciliation
- Date validation
- NULL value checks
- Duplicate detection
- Data completeness verification

---

## Important questions

### Design Decisions

**Q: Why UUIDs instead of SERIAL IDs?**
- Enables distributed systems without ID conflicts
- Better security (non-sequential, harder to guess)
- Supports data merging from multiple sources
- Industry standard in modern fintech applications

**Q: Why DECIMAL for money instead of FLOAT?**
- Exact precision - no floating-point rounding errors
- Example: 0.1 + 0.2 = 0.30000000004 in FLOAT, exactly 0.30 in DECIMAL
- Financial regulations require penny-perfect accuracy
- Prevents compounding errors over millions of transactions

**Q: How would you scale this to billions of transactions?**
- Table partitioning by date ranges (monthly/yearly)
- Read replicas for analytical queries
- Distributed PostgreSQL (Citus) for horizontal scaling
- Time-series database (TimescaleDB) for transaction table
- Archive old transactions to cold storage
- Implement caching layer (Redis) for frequent queries

**Q: Why separate transaction_date from created_at?**
- Audit requirement: when transaction occurred vs when recorded
- Supports importing historical transactions
- Critical for reconciliation processes
- Enables detecting delayed transaction reporting

---

---

## Technologies Used

- **Database**: PostgreSQL 14+
- **Languages**: SQL, PL/pgSQL
- **Concepts**: ACID transactions, normalization, indexing, triggers, materialized views
- **Domain**: Financial data engineering, transaction processing, reconciliation

---

## 📧 Contact

**Adam Farah**  
 [adamfarahx@example.com]  
 [GitHub](https://github.com/adamfarahx)

---

## 📄 License

This is my personal project for educational and portfolio purposes.

---

**If you found this project helpful, please give it a star!**
