# Supabase Backend Deployment

This document explains how to deploy the Supabase backend for the Swivo app.

## GitHub Actions Setup

The repository includes a GitHub Actions workflow that automatically deploys changes to your Supabase project when code is pushed to the main branch.

### Required Secrets

To set up the GitHub Actions workflow, you need to add the following secrets to your GitHub repository:

1. **SUPABASE_ACCESS_TOKEN**: Your Supabase access token
   - Get this from: https://supabase.com/dashboard/account/tokens

2. **SUPABASE_PROJECT_ID**: Your Supabase project reference ID
   - Find this in your project URL: https://app.supabase.com/project/[project-id]
   - Or in the project settings page

3. **SUPABASE_DB_PASSWORD**: Your database password
   - This is the password you set when creating your project

### Adding Secrets to GitHub

1. Go to your GitHub repository
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Add each of the secrets listed above

## Manual Deployment

If you prefer to deploy manually, you can use the following commands:

### Prerequisites

1. Install the Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

### Deploy Database Changes

```bash
cd backend/supabase
supabase link --project-ref your-project-ref
supabase db push
```

### Deploy Edge Functions

```bash
cd backend/supabase
supabase functions deploy
```

## Environment Variables

Make sure your production Supabase project has the following environment variables set for your Edge Functions:

1. APNS_KEY_ID
2. APNS_TEAM_ID
3. APNS_KEY_PATH (or use a secret to store the actual key content)
4. APNS_BUNDLE_ID

You can set these in the Supabase dashboard under Project Settings > API > Edge Functions.
