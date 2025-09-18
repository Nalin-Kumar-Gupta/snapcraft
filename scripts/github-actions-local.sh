#!/bin/bash
# Run GitHub Actions workflows locally using act
set -euo pipefail

COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_NC='\033[0m'

echo -e "${COLOR_BLUE}🎬 Running GitHub Actions workflows locally${COLOR_NC}"
echo -e "${COLOR_BLUE}Using 'act' to simulate GitHub runners${COLOR_NC}"
echo ""

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${COLOR_YELLOW}📦 Installing 'act' (GitHub Actions local runner)...${COLOR_NC}"
    if command -v brew &> /dev/null; then
        brew install act
    else
        echo -e "${COLOR_RED}❌ Please install 'act' first:${COLOR_NC}"
        echo "  brew install act"
        echo "  Or visit: https://github.com/nektos/act"
        exit 1
    fi
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${COLOR_RED}❌ Docker not found. 'act' requires Docker to run.${COLOR_NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${COLOR_RED}❌ Docker daemon not running. Please start Docker Desktop.${COLOR_NC}"
    exit 1
fi

# Configuration
WORKFLOW=${1:-"qa"}
PLATFORM="--platform ubuntu-24.04=catthehacker/ubuntu:act-24.04"
EVENT="--eventpath .github/workflows/test-event.json"

# Create a test event file for pull requests
cat > .github/workflows/test-event.json << 'EOF'
{
  "action": "opened",
  "pull_request": {
    "id": 1,
    "number": 1,
    "head": {
      "ref": "test-branch",
      "sha": "abc123",
      "repo": {
        "fork": false
      }
    },
    "base": {
      "ref": "main"
    }
  }
}
EOF

# Function to run specific workflow
run_workflow() {
    local workflow_name="$1"
    local workflow_file=".github/workflows/${workflow_name}.yaml"
    
    if [[ ! -f "$workflow_file" ]] && [[ ! -f ".github/workflows/${workflow_name}.yml" ]]; then
        echo -e "${COLOR_RED}❌ Workflow file not found: $workflow_file${COLOR_NC}"
        return 1
    fi
    
    echo -e "${COLOR_BLUE}🎯 Running workflow: $workflow_name${COLOR_NC}"
    echo ""
    
    # Use x86_64 platform to match GitHub runners
    act pull_request \n        --container-architecture linux/amd64 \n        $PLATFORM \n        $EVENT \n        --workflows "$workflow_file" \n        --verbose
}

# Handle different workflow options
case "$WORKFLOW" in
    "qa")
        echo -e "${COLOR_BLUE}🔍 Running QA workflow (lint + test)...${COLOR_NC}"
        run_workflow "qa"
        ;;
    "spread")
        echo -e "${COLOR_BLUE}🎯 Running Spread test workflow...${COLOR_NC}"
        echo -e "${COLOR_YELLOW}⚠️  Note: Spread tests require cloud credentials and may not work locally${COLOR_NC}"
        run_workflow "spread"
        ;;
    "publish")
        echo -e "${COLOR_BLUE}📦 Running publish workflow...${COLOR_NC}"
        run_workflow "publish"
        ;;
    "all")
        echo -e "${COLOR_BLUE}🏃 Running all workflows...${COLOR_NC}"
        for workflow in qa spread publish; do
            echo -e "${COLOR_BLUE}Running $workflow...${COLOR_NC}"
            run_workflow "$workflow" || echo -e "${COLOR_YELLOW}⚠️  $workflow failed, continuing...${COLOR_NC}"
            echo ""
        done
        ;;
    "list")
        echo -e "${COLOR_BLUE}📋 Available workflows:${COLOR_NC}"
        find .github/workflows -name "*.y*ml" -exec basename {} \; | sed 's/\.[^.]*$//' | sort
        exit 0
        ;;
    *)
        echo -e "${COLOR_RED}❌ Unknown workflow: $WORKFLOW${COLOR_NC}"
        echo ""
        echo "Usage: $0 [workflow_name]"
        echo ""
        echo "Available workflows:"
        echo "  qa       - Run QA workflow (lint + test)"
        echo "  spread   - Run spread integration tests"
        echo "  publish  - Run publish workflow"
        echo "  all      - Run all workflows"
        echo "  list     - List all available workflows"
        echo ""
        echo "Examples:"
        echo "  $0 qa              # Run QA checks"
        echo "  $0 spread          # Run integration tests"
        echo "  $0 all             # Run everything"
        exit 1
        ;;
esac

# Cleanup
rm -f .github/workflows/test-event.json

if [ $? -eq 0 ]; then
    echo -e "${COLOR_GREEN}✅ GitHub Actions simulation completed successfully!${COLOR_NC}"
else
    echo -e "${COLOR_RED}❌ GitHub Actions simulation failed!${COLOR_NC}"
    exit 1
fi