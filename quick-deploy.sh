#!/bin/bash
# Quick Deploy Script for MOMIT
# Uses pre-built build-web.zip for immediate deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build/web"
ZIP_FILE="$PROJECT_DIR/build-web.zip"

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  MOMIT Quick Deployment Script${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# Step 1: Verify zip file exists
echo -e "${YELLOW}Step 1: Verifying build-web.zip...${NC}"
if [ ! -f "$ZIP_FILE" ]; then
    echo -e "${RED}✗ build-web.zip not found at $ZIP_FILE${NC}"
    exit 1
fi

# Check if zip is valid
if ! unzip -t "$ZIP_FILE" > /dev/null 2>&1; then
    echo -e "${RED}✗ build-web.zip is corrupted or invalid${NC}"
    exit 1
fi

ZIP_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
echo -e "${GREEN}✓ build-web.zip found ($ZIP_SIZE)${NC}"

# Step 2: Clean and extract
echo ""
echo -e "${YELLOW}Step 2: Extracting build files...${NC}"

# Remove existing build/web if exists
if [ -d "$BUILD_DIR" ]; then
    echo "  Removing existing build/web directory..."
    rm -rf "$BUILD_DIR"
fi

# Extract the zip
cd "$PROJECT_DIR"
unzip -q "$ZIP_FILE"

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}✗ Extraction failed - build/web directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Extracted to build/web/${NC}"

# Step 3: Verify extracted files
echo ""
echo -e "${YELLOW}Step 3: Verifying extracted files...${NC}"

REQUIRED_FILES=("index.html" "main.dart.js" "flutter.js" "manifest.json")
ALL_PRESENT=true

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$BUILD_DIR/$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file MISSING"
        ALL_PRESENT=false
    fi
done

# Check required directories
REQUIRED_DIRS=("assets" "icons")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$BUILD_DIR/$dir" ]; then
        echo -e "  ${GREEN}✓${NC} $dir/"
    else
        echo -e "  ${RED}✗${NC} $dir/ MISSING"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo -e "${RED}✗ File verification failed${NC}"
    exit 1
fi

FILE_COUNT=$(find "$BUILD_DIR" -type f | wc -l)
BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
echo -e "${GREEN}✓ All files present ($FILE_COUNT files, $BUILD_SIZE)${NC}"

# Step 4: Check wrangler configuration
echo ""
echo -e "${YELLOW}Step 4: Checking wrangler configuration...${NC}"

if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}✗ wrangler not found. Install with: npm install -g wrangler${NC}"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/wrangler.toml" ]; then
    echo -e "${RED}✗ wrangler.toml not found${NC}"
    exit 1
fi

# Verify wrangler is authenticated
if ! wrangler whoami > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ wrangler not authenticated. Run: wrangler login${NC}"
    echo ""
    read -p "Would you like to login now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        wrangler login
    else
        echo -e "${RED}✗ Authentication required for deployment${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ wrangler ready${NC}"

# Step 5: Confirm deployment
echo ""
echo -e "${YELLOW}Step 5: Deployment Confirmation${NC}"
echo "  Project: momit"
echo "  Source: $BUILD_DIR"
echo "  Size: $BUILD_SIZE"
echo "  Files: $FILE_COUNT"
echo ""
read -p "Deploy to Cloudflare Pages? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Step 6: Deploy
echo ""
echo -e "${YELLOW}Step 6: Deploying to Cloudflare Pages...${NC}"
echo "  Running: wrangler pages deploy build/web --project-name=momit"
echo ""

cd "$PROJECT_DIR"
if wrangler pages deploy build/web --project-name=momit; then
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}  ✓ Deployment Successful!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Your site should be live at:"
    echo "  https://momit.pages.dev"
    echo ""
    echo "To check deployment status:"
    echo "  wrangler pages deployment list --project-name=momit"
else
    echo ""
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}  ✗ Deployment Failed${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
    echo "Check the error messages above for details."
    echo "Common issues:"
    echo "  - Authentication: Run 'wrangler login'"
    echo "  - Project doesn't exist: Check wrangler.toml configuration"
    exit 1
fi

echo ""
echo -e "${GREEN}Quick deployment complete!${NC}"
