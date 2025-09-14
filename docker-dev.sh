#!/bin/bash

# Snapcraft Docker Development Environment Setup Script
# This script helps you set up and use Snapcraft in a Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show help
show_help() {
    cat << EOF
Snapcraft Docker Development Environment

Usage: $0 [COMMAND]

Commands:
    build       Build the Docker image
    up          Start the development container
    shell       Start an interactive shell in the container
    test        Run the test suite
    lint        Run linting checks
    format      Run code formatting
    docs        Start documentation server
    clean       Clean up containers and images
    setup       Full setup (build + install dependencies)
    help        Show this help message

Examples:
    $0 build                    # Build the Docker image
    $0 shell                    # Start interactive development session
    $0 test                     # Run all tests
    $0 lint                     # Run linting
    $0 docs                     # Start docs server on http://localhost:8000

Environment Variables:
    DOCKER_BUILDKIT=1          # Enable Docker BuildKit (recommended)
    
EOF
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_warning "docker-compose not found. Trying 'docker compose'..."
        if ! docker compose version &> /dev/null; then
            print_error "Neither docker-compose nor 'docker compose' found. Please install Docker Compose."
            exit 1
        fi
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
}

# Build the Docker image
build_image() {
    print_status "Building Snapcraft development image..."
    export DOCKER_BUILDKIT=1
    $COMPOSE_CMD build snapcraft-dev
    print_success "Docker image built successfully!"
}

# Start the container
start_container() {
    print_status "Starting Snapcraft development container..."
    $COMPOSE_CMD up -d snapcraft-dev
    print_success "Container started!"
}

# Start interactive shell
start_shell() {
    print_status "Starting interactive shell in Snapcraft container..."
    $COMPOSE_CMD run --rm snapcraft-dev /bin/bash
}

# Run tests
run_tests() {
    print_status "Running Snapcraft tests..."
    $COMPOSE_CMD run --rm snapcraft-dev make test
}

# Run linting
run_lint() {
    print_status "Running Snapcraft linting..."
    $COMPOSE_CMD run --rm snapcraft-dev make lint
}

# Run formatting
run_format() {
    print_status "Running Snapcraft code formatting..."
    $COMPOSE_CMD run --rm snapcraft-dev make format
}

# Start documentation server
start_docs() {
    print_status "Starting documentation server..."
    print_status "Documentation will be available at: http://localhost:8000"
    $COMPOSE_CMD --profile docs up docs
}

# Clean up
clean_up() {
    print_status "Cleaning up Docker containers and images..."
    $COMPOSE_CMD down -v
    docker system prune -f
    print_success "Cleanup completed!"
}

# Full setup
full_setup() {
    print_status "Setting up Snapcraft development environment..."
    build_image
    print_status "Running setup commands..."
    $COMPOSE_CMD run --rm snapcraft-dev make setup
    print_success "Setup completed! You can now run '$0 shell' to start developing."
}

# Main script logic
main() {
    check_docker
    
    case "${1:-help}" in
        build)
            build_image
            ;;
        up)
            start_container
            ;;
        shell)
            start_shell
            ;;
        test)
            run_tests
            ;;
        lint)
            run_lint
            ;;
        format)
            run_format
            ;;
        docs)
            start_docs
            ;;
        clean)
            clean_up
            ;;
        setup)
            full_setup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
