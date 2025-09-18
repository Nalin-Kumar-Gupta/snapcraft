#!/bin/bash
# Setup script for Snapcraft development on Apple Silicon
set -euo pipefail

echo "🐶 Setting up Snapcraft for Apple Silicon development..."

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script is for macOS only"
    exit 1
fi

# Check if we're on Apple Silicon
if [[ "$(uname -m)" != "arm64" ]]; then
    echo "⚠️  This script is optimized for Apple Silicon (ARM64)"
fi

# Install dependencies via Homebrew
echo "📦 Installing dependencies via Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install it first: https://brew.sh"
    exit 1
fi

# Install required tools
brew_packages=(
    "uv"           # Python package manager
    "node"         # For prettier and other tools
    "shellcheck"   # Shell script linting
    "multipass"    # For Linux VMs (used by snapcraft)
    "docker"       # For containerized testing
)

for package in "${brew_packages[@]}"; do
    if ! brew list "$package" &> /dev/null; then
        echo "Installing $package..."
        brew install "$package"
    else
        echo "✅ $package already installed"
    fi
done

# Install Python development environment
echo "🐍 Setting up Python environment..."
make setup

# Install pre-commit hooks
echo "🪝 Setting up pre-commit hooks..."
make setup-precommit

echo "✅ Setup complete!"
echo ""
echo "🎯 Quick start:"
echo "  make test-fast          # Run fast unit tests"
echo "  make lint              # Run all linters"
echo "  make format            # Auto-format code"
echo "  ./scripts/ci-local.sh  # Run full local CI"
echo ""
echo "🔧 For integration tests, use:"
echo "  ./scripts/test-integration-docker.sh  # Docker-based integration tests"