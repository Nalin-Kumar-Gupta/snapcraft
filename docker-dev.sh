#!/bin/bash

# Simple Snapcraft Docker development script
set -e

COMPOSE_CMD="docker-compose"
if ! command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
fi

case "${1:-shell}" in
    build)
        echo "Building Snapcraft development image..."
        $COMPOSE_CMD build
        ;;
    shell)
        echo "Starting interactive shell..."
        $COMPOSE_CMD run --rm snapcraft-dev bash
        ;;
    setup)
        echo "Running make setup..."
        $COMPOSE_CMD run --rm snapcraft-dev make setup
        ;;
    test)
        echo "Running tests..."
        $COMPOSE_CMD run --rm snapcraft-dev make test
        ;;
    lint)
        echo "Running linting..."
        $COMPOSE_CMD run --rm snapcraft-dev make lint
        ;;
    format)
        echo "Running formatting..."
        $COMPOSE_CMD run --rm snapcraft-dev make format
        ;;
    clean)
        echo "Cleaning up..."
        $COMPOSE_CMD down -v
        docker system prune -f
        ;;
    *)
        echo "Usage: $0 {build|shell|setup|test|lint|format|clean}"
        echo "  build  - Build the Docker image"
        echo "  shell  - Start interactive development shell"
        echo "  setup  - Run make setup"
        echo "  test   - Run make test"
        echo "  lint   - Run make lint"
        echo "  format - Run make format"
        echo "  clean  - Clean up containers and images"
        ;;
esac
