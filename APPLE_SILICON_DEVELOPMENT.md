# 🍎 Snapcraft Development on Apple Silicon

This guide provides comprehensive solutions for developing and testing Snapcraft on Apple Silicon Macs, including running GitHub workflows and integration tests locally.

## 🚀 Quick Start

```bash
# 1. Setup development environment
chmod +x scripts/*.sh
./scripts/setup-apple-silicon.sh

# 2. Run local CI (mimics GitHub workflows)
./scripts/ci-local.sh

# 3. Run integration tests via Docker
./scripts/test-integration-docker.sh unit
```

## 📋 Overview

**Snapcraft** is a Python tool for building Ubuntu Snap packages. The main challenges on Apple Silicon:

- **x86_64 CI**: GitHub workflows run on Ubuntu x86_64 runners
- **Linux-specific tests**: Integration tests require Linux environments
- **Snap ecosystem**: Snap packages are Linux-only

## 🛠️ Setup Requirements

### Prerequisites

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install uv node shellcheck multipass docker
```

### Auto Setup

```bash
# Run the automated setup script
./scripts/setup-apple-silicon.sh
```

This script will:
- ✅ Install development dependencies
- ✅ Setup Python environment with `uv`
- ✅ Configure pre-commit hooks
- ✅ Verify Apple Silicon compatibility

## 🧪 Testing Approaches

### 1. 🏃‍♂️ Fast Local Development

**Best for**: Daily development, code review preparation

```bash
# Run the comprehensive local CI
./scripts/ci-local.sh

# Or run individual checks
make test-fast           # Fast unit tests
make lint               # All linting
make format             # Auto-format code
make pack-pip           # Build packages
```

**What this covers**:
- ✅ Unit tests (Python 3.12)
- ✅ Linting (ruff, mypy, codespell, etc.)
- ✅ Type checking (pyright, mypy)
- ✅ Documentation checks
- ✅ Package building
- ❌ Linux integration tests (use Docker approach)

### 2. 🐳 Docker-based Integration Tests

**Best for**: Testing x86_64 compatibility, Linux-specific features

```bash
# Run different test suites
./scripts/test-integration-docker.sh unit        # Unit tests in x86_64 container
./scripts/test-integration-docker.sh lint       # Linting in container
./scripts/test-integration-docker.sh core22     # Core22 integration tests
./scripts/test-integration-docker.sh all        # Everything

# Use different Ubuntu versions
UBUNTU_VERSION=24.04 ./scripts/test-integration-docker.sh unit
```

**What this covers**:
- ✅ x86_64 Linux environment
- ✅ Full dependency installation
- ✅ Architecture-specific testing
- ✅ Ubuntu 20.04, 22.04, 24.04 support
- ❌ Full spread testing (requires cloud setup)

### 3. ☁️ Multipass VM Testing

**Best for**: Real Linux VM testing, closest to CI environment

```bash
# Run tests in real Ubuntu VMs
./scripts/test-multipass.sh unit            # Unit tests
./scripts/test-multipass.sh lint           # Linting
./scripts/test-multipass.sh smoke          # Smoke tests
./scripts/test-multipass.sh spread-local   # Local spread tests

# Use different VM configurations
VM_MEMORY=8G VM_CPUS=4 ./scripts/test-multipass.sh unit
UBUNTU_VERSION=24.04 ./scripts/test-multipass.sh smoke
```

**What this covers**:
- ✅ Real Ubuntu VMs
- ✅ Full Linux environment
- ✅ Native snapd support
- ✅ Configurable resources
- ⚠️ Slower than Docker

### 4. 🎬 GitHub Actions Simulation

**Best for**: Exact workflow reproduction, debugging CI issues

```bash
# Install act (GitHub Actions runner)
brew install act

# Run specific workflows
./scripts/github-actions-local.sh qa       # QA workflow
./scripts/github-actions-local.sh spread   # Spread tests
./scripts/github-actions-local.sh all      # All workflows
./scripts/github-actions-local.sh list     # List available
```

**What this covers**:
- ✅ Exact GitHub workflow reproduction
- ✅ Same container images as CI
- ✅ Environment variable handling
- ❌ Requires secrets for some workflows

## 🎯 Recommended Workflow

### Daily Development

```bash
# 1. Quick local checks (30 seconds)
make test-fast lint-ruff

# 2. Full local CI before committing (2-5 minutes)
./scripts/ci-local.sh

# 3. Integration test for critical changes (5-10 minutes)
./scripts/test-integration-docker.sh core22
```

### Pre-PR Checklist

```bash
# 1. Full local CI
./scripts/ci-local.sh

# 2. Docker integration tests
./scripts/test-integration-docker.sh all

# 3. VM testing for major changes
./scripts/test-multipass.sh smoke

# 4. GitHub Actions simulation
./scripts/github-actions-local.sh qa
```

## 🔧 Configuration Options

### Environment Variables

```bash
# Local CI configuration
export RUN_FAST_TESTS=true        # Run fast unit tests
export RUN_SLOW_TESTS=false       # Skip slow tests
export RUN_LINT=true              # Run linting
export RUN_INTEGRATION=false      # Skip integration tests

# Docker configuration
export UBUNTU_VERSION=22.04       # Ubuntu version
export DOCKER_PLATFORM=linux/amd64 # Force x86_64

# Multipass configuration
export VM_MEMORY=4G               # VM memory
export VM_DISK=20G                # VM disk space
export VM_CPUS=2                  # VM CPU cores
```

### Custom Test Selection

```bash
# Run specific test categories
make test-fast                    # Fast tests only
make test-slow                    # Slow tests only
RUN_SLOW_TESTS=true ./scripts/ci-local.sh  # Include slow tests

# Run specific Docker test suites
./scripts/test-integration-docker.sh unit
./scripts/test-integration-docker.sh lint
./scripts/test-integration-docker.sh core20
./scripts/test-integration-docker.sh core22
./scripts/test-integration-docker.sh core24
./scripts/test-integration-docker.sh general
```

## 🐛 Troubleshooting

### Common Issues

#### 1. **"Architecture not supported" errors**

```bash
# Force x86_64 platform for Docker
export DOCKER_DEFAULT_PLATFORM=linux/amd64
docker run --platform linux/amd64 ubuntu:22.04 uname -m
```

#### 2. **UV/Python dependency issues**

```bash
# Reset Python environment
make clean
uv cache clean
./scripts/setup-apple-silicon.sh
```

#### 3. **Docker permission issues**

```bash
# Ensure Docker Desktop is running
open -a Docker

# Check Docker status
docker info
```

#### 4. **Multipass VM issues**

```bash
# List running VMs
multipass list

# Clean up stuck VMs
multipass delete --purge --all

# Restart Multipass service
sudo launchctl unload /Library/LaunchDaemons/com.canonical.multipassd.plist
sudo launchctl load /Library/LaunchDaemons/com.canonical.multipassd.plist
```

### Performance Tips

```bash
# Speed up Docker builds
export DOCKER_BUILDKIT=1

# Use more VM resources for faster tests
VM_MEMORY=8G VM_CPUS=4 ./scripts/test-multipass.sh

# Run tests in parallel
make test-fast -j4
```

## 📊 Test Coverage Comparison

| Approach | Speed | Coverage | x86_64 | Linux | Snap Support | Setup |
|----------|-------|----------|--------|-------|--------------|-------|
| Local CI | ⚡⚡⚡ | 🔵🔵🔵⚪⚪ | ❌ | ❌ | ❌ | ⚡ |
| Docker | ⚡⚡⚪ | 🔵🔵🔵🔵⚪ | ✅ | ✅ | ⚠️ | ⚡⚡ |
| Multipass | ⚡⚪⚪ | 🔵🔵🔵🔵🔵 | ✅ | ✅ | ✅ | ⚡⚡⚡ |
| GitHub Actions | ⚡⚪⚪ | 🔵🔵🔵🔵🔵 | ✅ | ✅ | ✅ | ⚡⚡⚡ |

## 🎉 Success Indicators

When your local testing is working correctly, you should see:

```bash
# ✅ Local CI passes
./scripts/ci-local.sh
# Output: "🎉 All local CI checks PASSED!"

# ✅ Docker tests pass
./scripts/test-integration-docker.sh unit
# Output: "✅ Integration tests completed successfully!"

# ✅ VM tests pass  
./scripts/test-multipass.sh smoke
# Output: "✅ VM tests completed successfully!"

# ✅ GitHub Actions simulation passes
./scripts/github-actions-local.sh qa
# Output: "✅ GitHub Actions simulation completed successfully!"
```

## 🤝 Contributing

When submitting PRs:

1. ✅ Run `./scripts/ci-local.sh` locally
2. ✅ Test with `./scripts/test-integration-docker.sh all`
3. ✅ Verify no Apple Silicon specific issues
4. ✅ Document any new Apple Silicon considerations

## 📚 Additional Resources

- [Snapcraft Documentation](https://snapcraft.io/docs)
- [Spread Testing Framework](https://github.com/snapcore/spread)
- [Multipass Documentation](https://multipass.run/docs)
- [Docker Desktop for Mac](https://docs.docker.com/desktop/mac/)
- [GitHub Actions with act](https://github.com/nektos/act)

---

🐶 **Happy coding on Apple Silicon!** These scripts should give you a comprehensive testing environment that catches issues before they hit CI.