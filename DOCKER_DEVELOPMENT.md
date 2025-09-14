# Snapcraft Docker Development Environment

This repository includes a complete Docker-based development environment for Snapcraft, making it easy to contribute to the project without complex local setup.

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (2.0+)
- Git

### One-Command Setup

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/canonical/snapcraft.git
cd snapcraft

# Set up the entire development environment
./docker-dev.sh setup
```

### Start Developing

```bash
# Start an interactive development shell
./docker-dev.sh shell

# Inside the container, you can now:
make lint     # Run linting
make test     # Run tests
make format   # Format code
python -m snapcraft --help  # Use snapcraft
```

## 📋 Available Commands

The `docker-dev.sh` script provides convenient commands for development:

| Command | Description | Usage |
|---------|-------------|-------|
| `setup` | Full environment setup | `./docker-dev.sh setup` |
| `shell` | Interactive development shell | `./docker-dev.sh shell` |
| `build` | Build the Docker image | `./docker-dev.sh build` |
| `test` | Run the test suite | `./docker-dev.sh test` |
| `lint` | Run linting checks | `./docker-dev.sh lint` |
| `format` | Run code formatting | `./docker-dev.sh format` |
| `docs` | Start documentation server | `./docker-dev.sh docs` |
| `clean` | Clean up containers/images | `./docker-dev.sh clean` |
| `help` | Show help message | `./docker-dev.sh help` |

## 🛠️ Development Workflow

### 1. Setup Your Environment

```bash
# Initial setup (only needed once)
./docker-dev.sh setup
```

### 2. Start Development Session

```bash
# Start interactive shell
./docker-dev.sh shell

# You're now inside the container with all dependencies ready!
```

### 3. Make Your Changes

Edit files on your host machine using your favorite editor. The container automatically sees your changes via volume mounts.

### 4. Test Your Changes

```bash
# Inside the container (from shell command)
make lint      # Check code style
make test      # Run tests
make format    # Auto-format code

# Or run these from outside the container
./docker-dev.sh lint
./docker-dev.sh test
./docker-dev.sh format
```

### 5. Test Snapcraft Commands

```bash
# Inside the container
python -m snapcraft --help
python -m snapcraft init
python -m snapcraft list-plugins
```

## 📚 Documentation Development

### Start Documentation Server

```bash
# Start docs server (available at http://localhost:8000)
./docker-dev.sh docs
```

### Build Documentation

```bash
# Inside the container
make docs

# Or from outside
docker-compose run --rm snapcraft-dev make docs
```

## 🧪 Testing

### Run All Tests

```bash
./docker-dev.sh test
```

### Run Specific Tests

```bash
# Start shell and run specific tests
./docker-dev.sh shell

# Inside container:
pytest tests/unit/test_specific.py
pytest tests/unit/ -k "test_pattern"
pytest tests/legacy/unit/
```

### Run Integration Tests

```bash
# Inside container
make test-spread-unstable  # If available
```

## 🔧 Advanced Usage

### Direct Docker Compose Commands

```bash
# Build image
docker-compose build

# Run one-off commands
docker-compose run --rm snapcraft-dev make lint
docker-compose run --rm snapcraft-dev python -c "import snapcraft; print('OK')"

# Start persistent container
docker-compose up -d snapcraft-dev
docker-compose exec snapcraft-dev bash
```

### Environment Variables

```bash
# Enable debug mode
SNAPCRAFT_ENABLE_DEVELOPER_DEBUG=1 ./docker-dev.sh shell

# Enable Docker BuildKit for faster builds
DOCKER_BUILDKIT=1 ./docker-dev.sh build
```

### Volume Mounts

The setup includes several volume mounts for persistence:

- Source code: `.:/home/snapcraft/snapcraft` (live editing)
- Home directory: `snapcraft-home:/home/snapcraft` (settings persistence)
- Cache: `snapcraft-cache:/home/snapcraft/.cache` (build cache)
- UV cache: `uv-cache:/home/snapcraft/.cache/uv` (Python package cache)

## 🐛 Troubleshooting

### Common Issues

#### Permission Issues

```bash
# If you get permission errors, rebuild the image
./docker-dev.sh clean
./docker-dev.sh build
```

#### Container Won't Start

```bash
# Check container logs
docker-compose logs snapcraft-dev

# Restart everything
./docker-dev.sh clean
./docker-dev.sh setup
```

#### Dependencies Out of Date

```bash
# Rebuild with latest dependencies
./docker-dev.sh clean
./docker-dev.sh build --no-cache
./docker-dev.sh shell
# Inside: make setup
```

#### Tests Failing

```bash
# Make sure you have the latest image
./docker-dev.sh build

# Run tests with verbose output
./docker-dev.sh shell
# Inside: pytest -xvs
```

### Getting Help

- Check container logs: `docker-compose logs snapcraft-dev`
- Inspect container: `docker-compose exec snapcraft-dev bash`
- See running containers: `docker ps`
- See available images: `docker images`

## 🏗️ Architecture

### Container Structure

- **Base**: Ubuntu 24.04 (Noble)
- **User**: `snapcraft` (non-root for security)
- **Python**: Python 3.12+ with uv package manager
- **Working Directory**: `/home/snapcraft/snapcraft`
- **Dependencies**: All development, testing, and documentation dependencies

### File Structure

```
.
├── Dockerfile              # Main development container
├── docker-compose.yml       # Multi-service setup
├── docker-dev.sh           # Development helper script
├── .dockerignore           # Docker build optimization
└── DOCKER_DEVELOPMENT.md   # This documentation
```

## 🤝 Contributing

This Docker setup is designed to make contributing to Snapcraft as easy as possible. The environment matches the target deployment environment and includes all necessary tools.

### Making Changes to the Docker Setup

If you need to modify the Docker setup:

1. Edit `Dockerfile` for container changes
2. Edit `docker-compose.yml` for service changes
3. Edit `docker-dev.sh` for workflow improvements
4. Test your changes: `./docker-dev.sh clean && ./docker-dev.sh setup`
5. Update this documentation if needed

### Performance Tips

- Use `DOCKER_BUILDKIT=1` for faster builds
- The `.dockerignore` file optimizes build context
- Volume mounts provide fast file access
- UV package manager speeds up Python installs

## 📄 License

This Docker setup is part of the Snapcraft project and follows the same GPL-3.0 license.
