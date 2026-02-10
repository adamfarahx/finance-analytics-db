-- ============================================================================
-- Finance Analytics Database - Master Setup Script
-- ============================================================================
-- Description: Runs all setup scripts in the correct order


\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'Creating Tables...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/01_create_tables.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'Creating Indexes...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/02_create_indexes.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'Creating Views...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/03_create_views.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'Creating Triggers & Functions...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/04_create_triggers.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo 'Loading Sample Data...'
\echo '════════════════════════════════════════════════════════'
\i /Users/adamfarahx/Downloads/finance_project1/05_seed_data.sql

\echo ''
\echo '════════════════════════════════════════════════════════'
\echo '✓ DATABASE SETUP COMPLETE!'
\echo '════════════════════════════════════════════════════════'
