# Dockerfile for Snapcraft local development
# Based on Ubuntu 24.04 (Noble) to match the target environment

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Set working directory
WORKDIR /snapcraft

# Install system dependencies required for Snapcraft
RUN apt-get update && apt-get install -y \
    # Python and build essentials
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    build-essential \
    # Git for version control
    git \
    # Required for various snapcraft operations
    curl \
    wget \
    unzip \
    # Required for cryptography and other Python packages
    libffi-dev \
    libssl-dev \
    # Required for lxml
    libxml2-dev \
    libxslt1-dev \
    # Required for python-apt
    libapt-pkg-dev \
    # Required for pygit2
    libgit2-dev \
    # Required for various operations
    pkg-config \
    # Required for gnupg
    gpg \
    gpg-agent \
    # Required for snapcraft operations
    squashfs-tools \
    # Required for spread testing
    openssh-client \
    # Required for multipass/lxd integration
    snapd \
    # Development tools
    make \
    # For debugging
    vim \
    nano \
    # Node.js for prettier (documentation formatting)
    nodejs \
    npm \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install uv (modern Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Create snapcraft user (non-root for security)
RUN groupadd -r snapcraft && useradd -r -g snapcraft -m -d /home/snapcraft -s /bin/bash snapcraft

# Switch to snapcraft user
USER snapcraft
WORKDIR /home/snapcraft/snapcraft

# Copy project files (do this after switching to user to set correct ownership)
COPY --chown=snapcraft:snapcraft . .

# Install Python dependencies using uv
RUN ~/.local/bin/uv sync --frozen

# Install development dependencies for linting and testing
RUN ~/.local/bin/uv sync --group=dev --group=lint --group=types --frozen

# Install documentation dependencies
RUN ~/.local/bin/uv sync --group=docs --frozen

# Install prettier for documentation formatting
RUN npm install -g prettier@3.6.0

# Set up environment variables
ENV PATH="/home/snapcraft/snapcraft/.venv/bin:$PATH"
ENV PYTHONPATH="/home/snapcraft/snapcraft:$PYTHONPATH"

# Create directories for snapcraft operations
RUN mkdir -p ~/.local/share/snapcraft \
    && mkdir -p ~/.cache/snapcraft \
    && mkdir -p ~/.config/snapcraft

# Expose port for documentation server (if needed)
EXPOSE 8000

# Default command - start an interactive bash shell
CMD ["/bin/bash"]

# Labels for metadata
LABEL maintainer="Snapcraft Development Team"
LABEL description="Snapcraft local development environment"
LABEL version="dev"
LABEL org.opencontainers.image.source="https://github.com/canonical/snapcraft"
