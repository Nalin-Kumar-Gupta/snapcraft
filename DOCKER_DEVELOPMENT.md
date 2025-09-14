# Snapcraft Docker Development Environment

Simple Docker setup for Snapcraft development that properly supports `make setup`, `make test`, `make lint`, etc.

## Quick Start

```bash
# 1. Build the development image
./docker-dev.sh build

# 2. Set up the development environment
./docker-dev.sh setup

# 3. Start interactive development shell
./docker-dev.sh shell

# 4. Inside the container, run make commands:
make lint
make test
make format
```

## Available Commands

| Command | Description |
|---------|-------------|
| `./docker-dev.sh build` | Build the Docker image |
| `./docker-dev.sh shell` | Start interactive shell |
| `./docker-dev.sh setup` | Run `make setup` |
| `./docker-dev.sh test` | Run `make test` |
| `./docker-dev.sh lint` | Run `make lint` |
| `./docker-dev.sh format` | Run `make format` |
| `./docker-dev.sh clean` | Clean up containers |

## Development Workflow

```bash
# 1. Build (first time only)
./docker-dev.sh build

# 2. Setup development environment (first time only)
./docker-dev.sh setup

# 3. Start development session
./docker-dev.sh shell

# 4. Inside container, work normally:
make lint
make test
python -m snapcraft --help
pytest tests/unit/
```

## Manual Docker Commands

If you prefer using Docker directly:

```bash
# Build
docker-compose build

# Run make commands
docker-compose run --rm snapcraft-dev make setup
docker-compose run --rm snapcraft-dev make test
docker-compose run --rm snapcraft-dev make lint

# Interactive shell
docker-compose run --rm snapcraft-dev bash
```

## Files

- `Dockerfile` - Simple Ubuntu 24.04 based development container
- `docker-compose.yml` - Basic service definition with volume mounts
- `docker-dev.sh` - Helper script for common commands
- `.dockerignore` - Optimizes build context

The container mounts your source code so you can edit files on your host and see changes immediately in the container.
