# Swivo Supabase Backend

This directory contains the Supabase configuration for the Swivo app.

## Setup Instructions

1. **Install Supabase CLI** (if not already installed):
   ```bash
   brew install supabase/tap/supabase
   ```

2. **Start Local Development Server**:
   ```bash
   supabase start
   ```

3. **Make Database Changes**:
   - Create SQL files in the `sql/` directory
   - Apply changes with `supabase db push`

4. **Edge Functions**:
   - Create new functions in the `functions/` directory
   - Deploy functions with `supabase functions deploy`

5. **Manage Database Migrations**:
   - Run `supabase db diff -f [migration_name]` to create a new migration
   - Migrations are stored in the `migrations/` directory

6. **Seed Data**:
   - Add seed data in the `seed/` directory
   - Use `supabase db reset` to apply seed data

## Directory Structure

- `migrations/`: Database migration files
- `sql/`: SQL schema definitions
- `functions/`: Supabase Edge Functions
- `seed/`: Database seed data
