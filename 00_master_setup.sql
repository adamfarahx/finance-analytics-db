-- ============================================================================
-- Finance Analytics Database - Master Setup Script
-- ============================================================================
-- Description: Runs all setup scripts in the correct order
-- Author: Your Name
-- Date: 2024
-- 
-- Usage: psql -d your_database_name -f 00_master_setup.sql
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo '   FINANCE ANALYTICS DATABASE - SETUP WIZARD'
\echo '════════════════════════════════════════════════════════'
\echo ''
\echo 'This script will:'
\echo '  1. Create all database tables'
\echo '  2. Add performance indexes'
\echo '  3. Create views for analytics'
\echo '  4. Set up triggers and functions'
\echo '  5. Load sample data'
\echo ''
\echo 'Press Ctrl+C to cancel, or press Enter to continue...'
\echo ''
\prompt 'Ready to begin? (Press Enter)' dummy

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'STEP 1/5: Creating Tables...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/01_create_tables.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'STEP 2/5: Creating Indexes...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/02_create_indexes.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'STEP 3/5: Creating Views...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/03_create_views.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'STEP 4/5: Creating Triggers & Functions...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/04_create_triggers.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'STEP 5/5: Loading Sample Data...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/05_seed_data.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo '✓ DATABASE SETUP COMPLETE!'
\echo '════════════════════════════════════════════════════════'
\echo ''
\echo 'Your finance analytics database is ready!'
\echo ''
\echo 'Try these commands to get started:'
\echo ''
\echo '  -- View all accounts with transaction summary'
\echo '  SELECT * FROM v_account_overview;'
\echo ''
\echo '  -- Check monthly spending'
\echo '  SELECT * FROM v_monthly_spending LIMIT 10;'
\echo ''
\echo '  -- See budget status'
\echo '  SELECT * FROM v_current_budget_status;'
\echo ''
\echo '  -- Run analytical queries'
\echo '  \i 06_analytical_queries.sql'
\echo ''
\echo '  -- Run data quality tests'
\echo '  \i 07_data_quality_tests.sql'
\echo ''
\echo 'For more information, see README.md'
\echo '════════════════════════════════════════════════════════'
\echo ''
