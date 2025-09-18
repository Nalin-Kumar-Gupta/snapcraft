#!/bin/bash
# Local CI script that mimics GitHub workflows for Apple Silicon
set -euo pipefail

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

# Configuration
RUN_FAST_TESTS=${RUN_FAST_TESTS:-true}
RUN_SLOW_TESTS=${RUN_SLOW_TESTS:-false}
RUN_LINT=${RUN_LINT:-true}
RUN_INTEGRATION=${RUN_INTEGRATION:-false}
DOCKER_PLATFORM=${DOCKER_PLATFORM:-linux/amd64}  # Force x86_64 for compatibility

echo -e "${COLOR_BLUE}🚀 Running local CI for Snapcraft on Apple Silicon${COLOR_NC}"
echo -e "${COLOR_BLUE}================================================================${COLOR_NC}"
echo ""

# Function to run a step and track success/failure
run_step() {
    local step_name="$1"
    local command="$2"
    
    echo -e "${COLOR_BLUE}📋 Running: $step_name${COLOR_NC}"
    echo "Command: $command"
    echo ""
    
    if eval "$command"; then
        echo -e "${COLOR_GREEN}✅ $step_name: PASSED${COLOR_NC}"
        echo ""
        return 0
    else
        echo -e "${COLOR_RED}❌ $step_name: FAILED${COLOR_NC}"
        echo ""
        return 1
    fi
}

# Track overall success
overall_success=true

# Setup environment
echo -e "${COLOR_YELLOW}🔧 Setting up environment...${COLOR_NC}"
if ! make setup-tests; then
    echo -e "${COLOR_RED}❌ Failed to setup test environment${COLOR_NC}"
    exit 1
fi
echo ""

# Linting checks (mimics qa.yaml workflow)
if [[ "$RUN_LINT" == "true" ]]; then
    echo -e "${COLOR_BLUE}🔍 Running linting checks...${COLOR_NC}"
    
    run_step "Ruff Linting" "make lint-ruff" || overall_success=false
    run_step "Code Spelling" "make lint-codespell" || overall_success=false
    run_step "MyPy Type Checking" "make lint-mypy" || overall_success=false
    run_step "Prettier Formatting" "make lint-prettier" || overall_success=false
    run_step "Shell Script Linting" "make lint-shellcheck" || overall_success=false
    
    # Skip pyright on Apple Silicon if it causes issues
    if command -v pyright &> /dev/null; then
        run_step "PyRight Type Checking" "make lint-pyright" || overall_success=false
    else
        echo -e "${COLOR_YELLOW}⚠️  PyRight not available, skipping...${COLOR_NC}"
    fi
    
    run_step "UV Lock File Check" "make lint-uv-lockfile" || overall_success=false
fi

# Fast unit tests (Python 3.12 equivalent)
if [[ "$RUN_FAST_TESTS" == "true" ]]; then
    echo -e "${COLOR_BLUE}🧪 Running fast unit tests...${COLOR_NC}"
    run_step "Fast Unit Tests" "make test-fast" || overall_success=false
fi

# Slow tests (if requested)
if [[ "$RUN_SLOW_TESTS" == "true" ]]; then
    echo -e "${COLOR_BLUE}🐌 Running slow tests...${COLOR_NC}"
    run_step "Slow Tests" "make test-slow" || overall_success=false
fi

# Documentation checks
echo -e "${COLOR_BLUE}📚 Checking documentation...${COLOR_NC}"
if make setup-docs &> /dev/null; then
    run_step "Documentation Linting" "make lint-docs" || overall_success=false
else
    echo -e "${COLOR_YELLOW}⚠️  Could not setup docs environment, skipping doc checks${COLOR_NC}"
fi

# Package building
echo -e "${COLOR_BLUE}📦 Testing package building...${COLOR_NC}"
run_step "Build Python Package" "make pack-pip" || overall_success=false
run_step "Twine Package Check" "make lint-twine" || overall_success=false

# Integration tests with Docker (if requested)
if [[ "$RUN_INTEGRATION" == "true" ]]; then
    echo -e "${COLOR_BLUE}🐳 Running integration tests via Docker...${COLOR_NC}"
    if command -v docker &> /dev/null; then
        run_step "Docker Integration Tests" "./scripts/test-integration-docker.sh" || overall_success=false
    else
        echo -e "${COLOR_YELLOW}⚠️  Docker not available, skipping integration tests${COLOR_NC}"
    fi
fi

# Summary
echo -e "${COLOR_BLUE}================================================================${COLOR_NC}"
if [[ "$overall_success" == "true" ]]; then
    echo -e "${COLOR_GREEN}🎉 All local CI checks PASSED!${COLOR_NC}"
    echo -e "${COLOR_GREEN}Your code is ready for PR submission.${COLOR_NC}"
    exit 0
else
    echo -e "${COLOR_RED}💥 Some local CI checks FAILED!${COLOR_NC}"
    echo -e "${COLOR_RED}Please fix the issues before submitting a PR.${COLOR_NC}"
    exit 1
fi