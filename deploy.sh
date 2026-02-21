#!/bin/bash

# MOMIT Flutter - Cloudflare Pages Deployment Script
# Usage: ./deploy.sh [environment]
#   environment: production (default) | preview | staging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="${CLOUDFLARE_PAGES_PROJECT_NAME:-momit}"
ENVIRONMENT="${1:-production}"
BUILD_DIR="build/web"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    # Check Wrangler
    if ! command -v wrangler &> /dev/null; then
        log_warning "Wrangler CLI not found. Installing..."
        npm install -g wrangler@latest
    fi
    
    # Check if logged in to Cloudflare
    if ! wrangler whoami &> /dev/null; then
        log_warning "Not logged in to Cloudflare. Running login..."
        wrangler login
    fi
    
    log_success "Prerequisites check passed"
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    flutter clean
    rm -rf "$BUILD_DIR"
    log_success "Clean complete"
}

# Get dependencies
get_dependencies() {
    log_info "Getting Flutter dependencies..."
    flutter pub get
    log_success "Dependencies installed"
}

# Run tests
run_tests() {
    log_info "Running tests..."
    if flutter test; then
        log_success "All tests passed"
    else
        log_warning "Some tests failed, but continuing with deployment"
    fi
}

# Build Flutter web
build_web() {
    log_info "Building Flutter Web for $ENVIRONMENT..."
    
    local build_args="--release --web-renderer html --no-tree-shake-icons"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        build_args="$build_args --dart-define=ENV=production"
    else
        build_args="$build_args --dart-define=ENV=development"
    fi
    
    flutter build web $build_args
    
    log_success "Build complete"
    
    # Show build info
    log_info "Build output:"
    ls -la "$BUILD_DIR"
    echo ""
    log_info "Build size:"
    du -sh "$BUILD_DIR"
}

# Deploy to Cloudflare Pages
deploy() {
    log_info "Deploying to Cloudflare Pages ($ENVIRONMENT)..."
    
    local branch_flag=""
    if [ "$ENVIRONMENT" != "production" ]; then
        branch_flag="--branch=$ENVIRONMENT"
    fi
    
    wrangler pages deploy "$BUILD_DIR" \
        --project-name="$PROJECT_NAME" \
        $branch_flag \
        --commit-dirty=true
    
    log_success "Deployment complete!"
}

# Main execution
main() {
    echo "========================================"
    echo "  MOMIT Flutter Deployment Script"
    echo "  Environment: $ENVIRONMENT"
    echo "========================================"
    echo ""
    
    # Validate environment
    case "$ENVIRONMENT" in
        production|preview|staging)
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT"
            echo "Usage: $0 [production|preview|staging]"
            exit 1
            ;;
    esac
    
    # Run deployment steps
    check_prerequisites
    clean_build
    get_dependencies
    run_tests
    build_web
    deploy
    
    echo ""
    echo "========================================"
    log_success "Deployment successful! 🎉"
    echo "========================================"
    echo ""
    log_info "Your app is now live on Cloudflare Pages"
    log_info "Project: $PROJECT_NAME"
    log_info "Environment: $ENVIRONMENT"
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main
