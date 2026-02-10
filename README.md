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

```

---

## SQL Skills Demonstrated

  **Database Design**
- Normalized schema with 6 related tables
- Foreign key constraints for data integrity
- CHECK constraints for validation
- UNIQUE constraints to prevent duplicates

  **Performance Optimization**
- Strategic indexing on frequently queried columns
- Composite indexes for multi-column queries
- Understanding of query execution plans

  **Advanced Queries**
- JOINs across multiple tables
- Aggregate functions (COUNT, SUM, AVG)
- Subqueries and filtering with WHERE
- Date functions and calculations
- GROUP BY for analytical summaries

  **Data Quality**
- Constraint-based validation
- Duplicate detection
- Balance reconciliation
- Automated testing scripts

  **Automation**
- Triggers for automatic balance updates
- Functions for recurring transaction processing
- Timestamp tracking for audit trails

### Performance Optimization

- Indexes on frequently queried columns (dates, foreign keys)
- Filtered indexes for active records only
- Using EXPLAIN ANALYZE for optimization
- Efficient data retrieval for reporting

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
├── 04_create_triggers.sql        # Triggers and functions
├── 05_seed_data.sql              # Realistic sample data
├── 06_analytical_queries.sql     # 12+ analytical queries
├── 07_data_quality_tests.sql     # 15+ validation tests
└── README.md                     # This file for documentation
```
*Note: File 03 (views) was removed to simplify project scope and focus on core database fundamentals.*


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

**Q: Why UUIDs instead of regular IDs?**
- Enables distributed systems without ID conflicts
- Better security (non-sequential, harder to guess)
- Better for systems that scale or merge data from multiple sources
- Industry standard in modern applications

**Q: Why DECIMAL for money instead of FLOAT?**
- Exact precision - no floating-point rounding errors
- Example: 0.1 + 0.2 = 0.30000000004 in FLOAT, exactly 0.30 in DECIMAL
- Financial regulations require penny-perfect accuracy
- Prevents compounding errors over millions of transactions

**Q: How would you scale this to billions of transactions?**
- Table partitioning by date ranges (monthly/yearly)
- Time-series database (TimescaleDB) for transaction table
- Archive old transactions to cold storage
- Implement caching layer (Redis) for frequent queries

**Q: Why separate transaction_date from created_at?**
- Audit requirement: when transaction occurred vs when recorded
- Supports importing historical transactions
- Enables detecting delayed transaction reporting

**Q: How I prevented duplicate transactions?**
- I used a UNIQUE constraint on the combination of account_id, transaction_date, amount, and merchant_name. 
   This way, if I tried to import the same transaction twice, the database will reject it automatically.

**Q: What was the hardest part of this project?**
- I mainly struggled with optimising sql queries and the performance aspect of this project such as indexing and explain plans. I overcame this by practising optimisation on my personal test database i created for employees of a company. Additionally, chapter 14 of the official postgres documentation was very insightful.

**Q: How would you improve this if you had more time?**
 - I'd add features like:
   multi-currency support, 
   simple web interface to visualize the data, 
   sophisticated analytics like spending predictions based on historical patterns.

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
 [adamfarahx@gmail.com]  
 [GitHub](https://github.com/adamfarahx)

---

## 📄 License

This is my personal project for educational and portfolio purposes.

---

**If you found this project helpful, please give it a star!**
