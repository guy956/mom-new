#!/bin/bash
# MOMIT Test Runner Script
# Usage: ./run_tests.sh [options]

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║              MOMIT Test Runner                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter not found in PATH${NC}"
    echo "Please ensure Flutter is installed and added to your PATH"
    exit 1
fi

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Parse arguments
RUN_ALL=true
COVERAGE=false
SPECIFIC_TEST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage|-c)
            COVERAGE=true
            shift
            ;;
        --test|-t)
            SPECIFIC_TEST="$2"
            RUN_ALL=false
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./run_tests.sh [options]"
            echo ""
            echo "Options:"
            echo "  --coverage, -c       Generate coverage report"
            echo "  --test, -t <file>    Run specific test file"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./run_tests.sh                              # Run all tests"
            echo "  ./run_tests.sh --coverage                   # Run with coverage"
            echo "  ./run_tests.sh --test auth_service_test.dart # Run specific test"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Run tests
if [ "$RUN_ALL" = true ]; then
    echo ""
    echo "🧪 Running all tests..."
    echo "════════════════════════════════════════════════════════════"
    
    if [ "$COVERAGE" = true ]; then
        flutter test --coverage
        
        # Generate HTML report if lcov is available
        if command -v genhtml &> /dev/null; then
            echo ""
            echo "📊 Generating coverage report..."
            genhtml coverage/lcov.info -o coverage/html --quiet
            echo -e "${GREEN}✓ Coverage report generated at coverage/html/index.html${NC}"
        else
            echo -e "${YELLOW}⚠ lcov not found. Install with: brew install lcov${NC}"
        fi
        
        # Show coverage summary
        if [ -f coverage/lcov.info ]; then
            echo ""
            echo "📈 Coverage Summary:"
            grep -E "LF|LH" coverage/lcov.info | tail -1
        fi
    else
        flutter test
    fi
else
    echo ""
    echo "🧪 Running $SPECIFIC_TEST..."
    echo "════════════════════════════════════════════════════════════"
    flutter test "test/$SPECIFIC_TEST"
fi

echo ""
echo -e "${GREEN}✓ Tests completed successfully!${NC}"
echo "════════════════════════════════════════════════════════════"