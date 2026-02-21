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
export CLOUDFLARE_API_TOKEN="gUp2ZPURMWzfA2NCC-fiQZvk8JcEgj5K3RCClHO_"
export CLOUDFLARE_ACCOUNT_ID="c3da1f83e98070eb27dc17680e183bb3"

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
