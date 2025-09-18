#!/bin/bash
# Multipass-based testing for Apple Silicon
set -euo pipefail

COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_NC='\033[0m'

echo -e "${COLOR_BLUE}☁️  Running Snapcraft tests via Multipass VMs${COLOR_NC}"
echo -e "${COLOR_BLUE}This creates real Ubuntu VMs for testing${COLOR_NC}"
echo ""

# Configuration
UBUNTU_VERSION=${UBUNTU_VERSION:-22.04}
VM_NAME="snapcraft-test-$(date +%s)"
VM_MEMORY=${VM_MEMORY:-4G}
VM_DISK=${VM_DISK:-20G}
VM_CPUS=${VM_CPUS:-2}

# Check if Multipass is available
if ! command -v multipass &> /dev/null; then
    echo -e "${COLOR_RED}❌ Multipass not found.${COLOR_NC}"
    echo "Install with: brew install multipass"
    exit 1
fi

# Clean up function
cleanup() {
    echo -e "${COLOR_YELLOW}🧹 Cleaning up VM...${COLOR_NC}"
    multipass delete --purge "$VM_NAME" &> /dev/null || true
}
trap cleanup EXIT

# Launch Ubuntu VM
echo -e "${COLOR_BLUE}🚀 Launching Ubuntu $UBUNTU_VERSION VM...${COLOR_NC}"
echo "VM Name: $VM_NAME"
echo "Memory: $VM_MEMORY, Disk: $VM_DISK, CPUs: $VM_CPUS"
echo ""

if ! multipass launch "$UBUNTU_VERSION" \n    --name "$VM_NAME" \n    --memory "$VM_MEMORY" \n    --disk "$VM_DISK" \n    --cpus "$VM_CPUS"; then
    echo -e "${COLOR_RED}❌ Failed to launch VM${COLOR_NC}"
    exit 1
fi

# Wait for VM to be ready
echo -e "${COLOR_BLUE}⏳ Waiting for VM to be ready...${COLOR_NC}"
sleep 10

# Function to run commands in VM
run_in_vm() {
    multipass exec "$VM_NAME" -- bash -c "$1"
}

# Setup VM environment
echo -e "${COLOR_BLUE}🔧 Setting up VM environment...${COLOR_NC}"
run_in_vm "sudo apt-get update"
run_in_vm "sudo apt-get install -y \n    python3 \n    python3-pip \n    python3-venv \n    python3-dev \n    build-essential \n    git \n    curl \n    libxml2-dev \n    libxslt1-dev \n    libapt-pkg-dev \n    libgit2-dev \n    libffi-dev \n    pkg-config \n    libssl-dev \n    libyaml-dev \n    xdelta3 \n    patchelf \n    snapd"

# Install uv
echo -e "${COLOR_BLUE}📦 Installing uv package manager...${COLOR_NC}"
run_in_vm "curl -LsSf https://astral.sh/uv/install.sh | sh"
run_in_vm "echo 'export PATH=\$HOME/.cargo/bin:\$PATH' >> ~/.bashrc"

# Copy source code to VM
echo -e "${COLOR_BLUE}📁 Copying source code to VM...${COLOR_NC}"
multipass mount . "$VM_NAME:/home/ubuntu/snapcraft"

# Setup Python environment in VM
echo -e "${COLOR_BLUE}🐍 Setting up Python environment in VM...${COLOR_NC}"
run_in_vm "cd /home/ubuntu/snapcraft && /home/ubuntu/.cargo/bin/uv sync --group=dev"

# Run tests based on command line argument
TEST_TYPE=${1:-"unit"}

case "$TEST_TYPE" in
    "unit")
        echo -e "${COLOR_BLUE}🧪 Running unit tests in VM...${COLOR_NC}"
        run_in_vm "cd /home/ubuntu/snapcraft && /home/ubuntu/.cargo/bin/uv run pytest tests/unit -v"
        ;;
    "lint")
        echo -e "${COLOR_BLUE}🔍 Running linting in VM...${COLOR_NC}"
        run_in_vm "cd /home/ubuntu/snapcraft && make lint"
        ;;
    "smoke")
        echo -e "${COLOR_BLUE}💨 Running smoke tests...${COLOR_NC}"
        run_in_vm "cd /home/ubuntu/snapcraft && /home/ubuntu/.cargo/bin/uv run python -m snapcraft --help"
        run_in_vm "cd /home/ubuntu/snapcraft && /home/ubuntu/.cargo/bin/uv run python -m snapcraft list-plugins"
        run_in_vm "cd /home/ubuntu/snapcraft && /home/ubuntu/.cargo/bin/uv run pytest tests/unit -k 'not slow' --maxfail=5"
        ;;
    "spread-local")
        echo -e "${COLOR_BLUE}🎯 Running local spread tests...${COLOR_NC}"
        echo -e "${COLOR_YELLOW}Note: This requires spread to be installed and configured${COLOR_NC}"
        
        # Install spread (this is a simplified version)
        run_in_vm "sudo snap install --classic go"
        run_in_vm "cd /home/ubuntu && git clone https://github.com/snapcore/spread.git"
        run_in_vm "cd /home/ubuntu/spread && /snap/bin/go build -o spread cmd/spread/*.go"
        run_in_vm "sudo cp /home/ubuntu/spread/spread /usr/local/bin/"
        
        # Try to run a simple spread test locally
        run_in_vm "cd /home/ubuntu/snapcraft && spread -v multipass:ubuntu-$UBUNTU_VERSION-64:tests/spread/general/build-aux/"
        ;;
    *)
        echo -e "${COLOR_RED}❌ Unknown test type: $TEST_TYPE${COLOR_NC}"
        echo "Available options: unit, lint, smoke, spread-local"
        exit 1
        ;;
esac

# Check exit code
if [ $? -eq 0 ]; then
    echo -e "${COLOR_GREEN}✅ VM tests completed successfully!${COLOR_NC}"
else
    echo -e "${COLOR_RED}❌ VM tests failed!${COLOR_NC}"
    exit 1
fi

echo -e "${COLOR_GREEN}🎉 Multipass-based testing completed!${COLOR_NC}"
echo -e "${COLOR_BLUE}VM will be cleaned up automatically${COLOR_NC}"