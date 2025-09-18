#!/bin/bash
# One-stop testing script for Apple Silicon development
set -euo pipefail

COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_NC='\033[0m'

echo -e "${COLOR_BLUE}🍎 Snapcraft Apple Silicon Test Runner${COLOR_NC}"
echo -e "${COLOR_BLUE}======================================${COLOR_NC}"
echo ""

# Show usage if no arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <test_type> [options]"
    echo ""
    echo "Test types:"
    echo "  quick      - Fast local tests (unit + lint) [~2 min]"
    echo "  full       - Full local CI suite [~5 min]"
    echo "  docker     - Docker-based integration tests [~10 min]"
    echo "  vm         - Multipass VM tests [~15 min]"
    echo "  github     - GitHub Actions simulation [~10 min]"
    echo "  all        - Everything (use with caution!) [~30 min]"
    echo ""
    echo "Examples:"
    echo "  $0 quick                    # Fast development cycle"
    echo "  $0 full                     # Pre-commit checks"
    echo "  $0 docker                   # Integration testing"
    echo "  $0 vm smoke                 # VM smoke test"
    echo "  $0 github qa                # Simulate GitHub QA workflow"
    echo ""
    exit 0
fi

TEST_TYPE="$1"
shift || true  # Remove first argument, ignore if no more args

case "$TEST_TYPE" in
    "quick")
        echo -e "${COLOR_BLUE}⚡ Running quick tests (unit + basic lint)...${COLOR_NC}"
        echo "This should complete in ~2 minutes"
        echo ""
        
        # Fast unit tests
        echo -e "${COLOR_BLUE}🧪 Running fast unit tests...${COLOR_NC}"
        make test-fast
        
        # Basic linting
        echo -e "${COLOR_BLUE}🔍 Running basic linting...${COLOR_NC}"
        make lint-ruff lint-codespell
        
        echo -e "${COLOR_GREEN}✅ Quick tests completed successfully!${COLOR_NC}"
        ;;
        
    "full")
        echo -e "${COLOR_BLUE}🏃 Running full local CI...${COLOR_NC}"
        echo "This should complete in ~5 minutes"
        echo ""
        
        ./scripts/ci-local.sh
        ;;
        
    "docker")
        echo -e "${COLOR_BLUE}🐳 Running Docker-based integration tests...${COLOR_NC}"
        echo "This should complete in ~10 minutes"
        echo ""
        
        # Default to core22 if no specific test provided
        DOCKER_TEST=${1:-"core22"}
        ./scripts/test-integration-docker.sh "$DOCKER_TEST"
        ;;
        
    "vm")
        echo -e "${COLOR_BLUE}☁️  Running Multipass VM tests...${COLOR_NC}"
        echo "This should complete in ~15 minutes"
        echo ""
        
        # Default to smoke test if no specific test provided
        VM_TEST=${1:-"smoke"}
        ./scripts/test-multipass.sh "$VM_TEST"
        ;;
        
    "github")
        echo -e "${COLOR_BLUE}🎬 Running GitHub Actions simulation...${COLOR_NC}"
        echo "This should complete in ~10 minutes"
        echo ""
        
        # Default to qa workflow if no specific workflow provided
        GITHUB_WORKFLOW=${1:-"qa"}
        ./scripts/github-actions-local.sh "$GITHUB_WORKFLOW"
        ;;
        
    "all")
        echo -e "${COLOR_YELLOW}⚠️  Running ALL tests - this will take ~30 minutes!${COLOR_NC}"
        echo "Press Ctrl+C in the next 5 seconds to cancel..."
        sleep 5
        echo ""
        
        echo -e "${COLOR_BLUE}Phase 1: Local CI${COLOR_NC}"
        ./scripts/ci-local.sh
        echo ""
        
        echo -e "${COLOR_BLUE}Phase 2: Docker Integration${COLOR_NC}"
        ./scripts/test-integration-docker.sh all
        echo ""
        
        echo -e "${COLOR_BLUE}Phase 3: VM Smoke Test${COLOR_NC}"
        ./scripts/test-multipass.sh smoke
        echo ""
        
        echo -e "${COLOR_BLUE}Phase 4: GitHub Actions${COLOR_NC}"
        ./scripts/github-actions-local.sh qa
        
        echo -e "${COLOR_GREEN}🎉 All tests completed successfully!${COLOR_NC}"
        echo -e "${COLOR_GREEN}Your code is ready for production!${COLOR_NC}"
        ;;
        
    *)
        echo -e "${COLOR_RED}❌ Unknown test type: $TEST_TYPE${COLOR_NC}"
        echo ""
        echo "Run '$0' without arguments to see usage."
        exit 1
        ;;
esac

echo -e "${COLOR_GREEN}🎉 Test run completed successfully!${COLOR_NC}"