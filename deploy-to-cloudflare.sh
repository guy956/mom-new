#!/bin/bash
# Deploy MOM to Cloudflare Pages - Quick Script

echo "🚀 Deploying MOM to Cloudflare Pages..."
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ wrangler CLI not found. Installing..."
    npm install -g wrangler
fi

# Set environment variables
export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:?Error: Set CLOUDFLARE_API_TOKEN env var}"
export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:?Error: Set CLOUDFLARE_ACCOUNT_ID env var}"

echo "📦 Deploying build/web to momit.pages.dev..."
echo ""

# Deploy
wrangler pages deploy build/web \
  --project-name=momit \
  --branch=main \
  --commit-dirty=true

echo ""
echo "✅ Deployment complete!"
echo "🌐 Visit: https://momit.pages.dev"
