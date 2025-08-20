# Supabase Backend Deployment

This document explains how to deploy the Supabase backend for the Swivo app.

## GitHub Actions Setup

The repository includes a GitHub Actions workflow that automatically deploys changes to your Supabase project when code is pushed to the main branch.

### Required Secrets and Variables

To set up the GitHub Actions workflow, you need to add the following to your GitHub repository:

#### Secrets (Repository > Settings > Secrets and variables > Actions > Secrets)

1. **SUPABASE_ACCESS_TOKEN**: Your Supabase access token
   - Get this from: https://supabase.com/dashboard/account/tokens

#### Variables (Repository > Settings > Secrets and variables > Actions > Variables)

1. **SUPABASE_PROJECT_ID**: Your Supabase project reference ID
   - Find this in your project URL: https://app.supabase.com/project/[project-id]
   - Or in the project settings page

### Adding Secrets and Variables to GitHub

1. Go to your GitHub repository
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. For secrets:
   - Select the "Secrets" tab
   - Click "New repository secret"
   - Add the secrets listed above
4. For variables:
   - Select the "Variables" tab
   - Click "New repository variable"
   - Add the variables listed above

## Manual Deployment

If you prefer to deploy manually, you can use the following commands:

### Prerequisites

1. Install the Supabase CLI:
   - macOS/Linux with Homebrew:
   ```bash
   brew install supabase/tap/supabase
   ```
   - Windows with Scoop:
   ```bash
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   ```
   - With other methods, see: https://supabase.com/docs/guides/cli

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
