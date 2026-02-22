# GitHub Actions Setup Guide for MOM

## Setup Steps

### 1. Repository Secrets

Go to: `https://github.com/guy956/mom/settings/secrets/actions`

Add these secrets:

#### Required for Deployment:
- **Name:** `CLOUDFLARE_API_TOKEN`
  - **Value:** *(your Cloudflare API token)*
  - Get from: Cloudflare Dashboard → My Profile → API Tokens

- **Name:** `CLOUDFLARE_ACCOUNT_ID`
  - **Value:** *(your Cloudflare account ID)*
  - Get from: Cloudflare Dashboard → right sidebar

- **Name:** `GITHUB_TOKEN`
  - This is automatically provided by GitHub

### 2. Cloudflare Pages Project

1. Go to: https://dash.cloudflare.com
2. Navigate to: Pages → Create a project
3. Project name: `momit`
4. Framework preset: None (Direct Upload)

### 3. Workflow Triggers

The workflow runs on:
- ✅ Push to `main` branch
- ✅ Pull requests to `main`
- ✅ Manual trigger (workflow_dispatch)

### 4. What the Workflow Does

1. **Setup Environment**
   - Flutter SDK 3.24.0
   - Node.js 18
   - Firebase CLI

2. **Build**
   - Get dependencies
   - Analyze code
   - Build web release
   - Verify output

3. **Deploy**
   - Upload to Cloudflare Pages
   - Verify deployment

4. **Test**
   - Run Flutter tests
   - Report results

### 5. Monitoring

Check workflow status:
- Go to: https://github.com/guy956/mom/actions
- View build logs
- Download artifacts if failed

### 6. Troubleshooting

If build fails:
1. Check the Actions log
2. Download "failed-build" artifact
3. Check Flutter version compatibility
4. Verify all secrets are set

## Deployment URL

After successful deployment:
- **Production:** https://momit.pages.dev
- **Preview:** https://[branch-name].momit.pages.dev
