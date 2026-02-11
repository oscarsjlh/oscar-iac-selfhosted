# Renovate Bot Setup - GitHub App Permissions Required

## 🚨 CRITICAL: GitHub App Permissions Must Be Updated

Your Renovate bot is currently failing to create PRs due to insufficient GitHub App permissions.

## Required Permissions

Your GitHub App (`oscar-renovate[bot]`) needs the following **Repository permissions**:

| Permission | Access Level | Required For |
|------------|--------------|--------------|
| **Contents** | **Read and write** | Push branches and create commits |
| **Pull requests** | **Read and write** | Create and update pull requests |
| **Metadata** | **Read** | Repository metadata (auto-granted) |
| **Workflows** | **Read and write** | If docker-compose changes affect workflows (optional) |

## How to Update Permissions

### Step 1: Update GitHub App Settings

1. Go to your GitHub App settings:
   - **URL**: https://github.com/settings/apps/oscar-renovate
   - Or navigate to: Settings → Developer settings → GitHub Apps → Your App

2. Click on **"Permissions & events"** in the left sidebar

3. Scroll to **"Repository permissions"** section

4. Update the following permissions:
   - **Contents**: Change to "Read and write"
   - **Pull requests**: Change to "Read and write"
   - **Workflows**: Change to "Read and write" (recommended)

5. Click **"Save changes"** at the bottom

### Step 2: Accept Updated Permissions in Repository

After updating the app permissions, you need to accept them:

1. Go to your repository installation settings:
   - **URL**: https://github.com/oscarsjlh/oscar-iac-selfhosted/settings/installations
   - Or navigate to: Repository → Settings → Integrations → GitHub Apps

2. Find your `oscar-renovate` app

3. Click **"Configure"**

4. You should see a banner asking you to **review and accept** the new permissions

5. Click **"Review"** and then **"Accept new permissions"**

### Step 3: Verify Setup

After updating permissions, test the setup:

```bash
# Trigger a manual Renovate run
gh workflow run renovate.yaml --repo oscarsjlh/oscar-iac-selfhosted

# Watch the run
gh run watch --repo oscarsjlh/oscar-iac-selfhosted

# Check for PRs (should see PRs created within a few minutes)
gh pr list --repo oscarsjlh/oscar-iac-selfhosted
```

## What Changed in Configuration

### `renovate/renovate.json`
- ✅ Added JSON schema for IDE validation
- ✅ Fixed `managerFilePatterns` placement (moved to `docker-compose` manager)
- ✅ Enabled automerge for non-major updates
- ✅ Grouped all Docker updates into single PR ("Docker images")
- ✅ Separated major version updates for manual review
- ✅ Improved file matching pattern for all docker-compose files
- ✅ Fixed `force` configuration structure

### `.github/workflows/renovate.yaml`
- ✅ Removed invalid `RENOVATE_GITHUB_APP_ID` input
- ✅ Changed schedule from every 15 minutes to **daily at 3 AM UTC**
- ✅ Added `workflow_dispatch` for manual triggers
- ✅ Added branch filter to only run on `main` branch pushes

## Expected Behavior After Fix

Once permissions are updated and configuration is committed:

1. **Renovate will run daily at 3 AM UTC**
2. **Creates grouped PRs**:
   - One PR with all non-major Docker image updates
   - Separate PRs for major version updates (requires manual review)
3. **Auto-merges** non-major updates automatically (after checks pass)
4. **Tracks all 12 docker-compose files**:
   - atuin, immich, jellyfin, linkding, mealie, monitoring
   - ntfy, openwebui, picard, qbitorrent, technitium, traefik

## Troubleshooting

### If PRs still don't appear:

1. Check workflow run logs:
   ```bash
   gh run list --repo oscarsjlh/oscar-iac-selfhosted --workflow=renovate.yaml
   gh run view <run-id> --log --repo oscarsjlh/oscar-iac-selfhosted
   ```

2. Look for errors like:
   - `Platform-native commit: unknown error` → Permissions not updated
   - `external-host-error` → GitHub App token issue
   - `403 Forbidden` → Insufficient permissions

3. Verify GitHub App token has correct scopes:
   ```bash
   # In workflow logs, look for:
   DEBUG: Using platform gitAuthor: oscar-renovate[bot]
   ```

### If automerge doesn't work:

1. Ensure your repository allows auto-merge:
   - Go to: Repository → Settings → General
   - Scroll to "Pull Requests"
   - Enable "Allow auto-merge"

2. Ensure branch protection rules don't block auto-merge

## Testing

After committing these changes and updating GitHub App permissions:

```bash
# Manual trigger to test immediately
gh workflow run renovate.yaml --repo oscarsjlh/oscar-iac-selfhosted

# Monitor progress
gh run watch --repo oscarsjlh/oscar-iac-selfhosted

# Check for created PRs (should appear within 2-3 minutes)
gh pr list --repo oscarsjlh/oscar-iac-selfhosted --author "app/oscar-renovate"
```

## Support

If you continue to experience issues after following these steps:
1. Check the workflow logs with `LOG_LEVEL: debug` enabled
2. Verify GitHub App installation is active
3. Confirm token generation is working in the "Get token" step
4. Review Renovate documentation: https://docs.renovatebot.com/

---

**Last Updated**: 2026-02-11
**Configuration Version**: 2.0
