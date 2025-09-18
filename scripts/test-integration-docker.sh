#!/bin/bash
# Docker-based integration testing for Apple Silicon
set -euo pipefail

COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_NC='\033[0m'

echo -e "${COLOR_BLUE}🐳 Running Snapcraft integration tests via Docker${COLOR_NC}"
echo -e "${COLOR_BLUE}Platform: linux/amd64 (x86_64 emulation on Apple Silicon)${COLOR_NC}"
echo ""

# Configuration
UBUNTU_VERSION=${UBUNTU_VERSION:-22.04}
DOCKER_IMAGE="ubuntu:${UBUNTU_VERSION}"
CONTAINER_NAME="snapcraft-test-$(date +%s)"
TEST_SUITE=${TEST_SUITE:-"core22"}  # core20, core22, core24, general

# Check if Docker is available and running
if ! command -v docker &> /dev/null; then
    echo -e "${COLOR_RED}❌ Docker not found. Please install Docker Desktop.${COLOR_NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${COLOR_RED}❌ Docker daemon not running. Please start Docker Desktop.${COLOR_NC}"
    exit 1
fi

# Clean up function
cleanup() {
    echo -e "${COLOR_YELLOW}🧹 Cleaning up container...${COLOR_NC}"
    docker rm -f "$CONTAINER_NAME" &> /dev/null || true
}
trap cleanup EXIT

# Build test container with x86_64 emulation
echo -e "${COLOR_BLUE}🏗️  Building test container (linux/amd64)...${COLOR_NC}"

# Create a temporary Dockerfile for testing
cat > Dockerfile.test << 'EOF'
ARG UBUNTU_VERSION=22.04
FROM --platform=linux/amd64 ubuntu:${UBUNTU_VERSION}

# Install system dependencies
RUN apt-get update && apt-get install -y \n    python3 \n    python3-pip \n    python3-venv \n    python3-dev \n    build-essential \n    git \n    curl \n    libxml2-dev \n    libxslt1-dev \n    libapt-pkg-dev \n    libgit2-dev \n    libffi-dev \n    pkg-config \n    libssl-dev \n    libyaml-dev \n    xdelta3 \n    patchelf \n    snapd \n    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

# Create working directory
WORKDIR /snapcraft

# Copy source code
COPY . .

# Setup Python environment
RUN uv sync --group=dev

# Set environment variables for testing
ENV SNAPCRAFT_BUILD_ENVIRONMENT="host"
ENV SNAPCRAFT_MANAGED_HOST="yes"
ENV SNAPCRAFT_ENABLE_ERROR_REPORTING="no"
ENV SNAPCRAFT_ENABLE_DEVELOPER_DEBUG="yes"
ENV DEBIAN_FRONTEND="noninteractive"
ENV DEBIAN_PRIORITY="critical"
EOF

echo -e "${COLOR_BLUE}🔨 Building Docker image...${COLOR_NC}"
if ! docker build --platform linux/amd64 -t snapcraft-test:latest -f Dockerfile.test --build-arg UBUNTU_VERSION="$UBUNTU_VERSION" .; then
    echo -e "${COLOR_RED}❌ Failed to build Docker image${COLOR_NC}"
    rm -f Dockerfile.test
    exit 1
fi

# Run the container
echo -e "${COLOR_BLUE}🚀 Starting test container...${COLOR_NC}"
if ! docker run --platform linux/amd64 -d --name "$CONTAINER_NAME" \n    --privileged \n    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \n    snapcraft-test:latest \n    /bin/bash -c "sleep infinity"; then
    echo -e "${COLOR_RED}❌ Failed to start container${COLOR_NC}"
    rm -f Dockerfile.test
    exit 1
fi

# Wait for container to be ready
echo -e "${COLOR_BLUE}⏳ Waiting for container to be ready...${COLOR_NC}"
sleep 5

# Function to run commands in container
run_in_container() {
    docker exec "$CONTAINER_NAME" /bin/bash -c "cd /snapcraft && $1"
}

# Run different test suites based on selection
case "$TEST_SUITE" in
    "unit")
        echo -e "${COLOR_BLUE}🧪 Running unit tests in container...${COLOR_NC}"
        run_in_container "uv run pytest tests/unit -v"
        ;;
    "lint")
        echo -e "${COLOR_BLUE}🔍 Running linting in container...${COLOR_NC}"
        run_in_container "make lint"
        ;;
    "core20"|"core22"|"core24"|"general")
        echo -e "${COLOR_BLUE}🔧 Running $TEST_SUITE integration tests...${COLOR_NC}"
        echo -e "${COLOR_YELLOW}Note: Full spread tests require cloud setup${COLOR_NC}"
        
        # Run basic smoke tests that don't require full spread
        run_in_container "uv run pytest tests/unit -k 'not slow' -v"
        run_in_container "make lint-ruff lint-codespell"
        
        # Try to run snapcraft commands to verify basic functionality
        run_in_container "uv run python -m snapcraft --help"
        run_in_container "uv run python -m snapcraft list-plugins"
        ;;
    "all")
        echo -e "${COLOR_BLUE}🏃 Running all available tests...${COLOR_NC}"
        run_in_container "make test"
        run_in_container "make lint"
        ;;
    *)
        echo -e "${COLOR_RED}❌ Unknown test suite: $TEST_SUITE${COLOR_NC}"
        echo "Available options: unit, lint, core20, core22, core24, general, all"
        rm -f Dockerfile.test
        exit 1
        ;;
esac

# Check exit code
if [ $? -eq 0 ]; then
    echo -e "${COLOR_GREEN}✅ Integration tests completed successfully!${COLOR_NC}"
else
    echo -e "${COLOR_RED}❌ Integration tests failed!${COLOR_NC}"
    exit 1
fi

# Cleanup
rm -f Dockerfile.test
echo -e "${COLOR_GREEN}🎉 Docker-based testing completed!${COLOR_NC}"