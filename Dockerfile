# Simple Dockerfile for Snapcraft development
FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-dev python3-pip python3-venv \
    build-essential git curl wget \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev \
    libapt-pkg-dev libgit2-dev pkg-config \
    gpg gpg-agent squashfs-tools \
    make nodejs npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Set working directory
WORKDIR /snapcraft

# Copy project files
COPY . .

# Install dependencies
RUN uv sync --frozen

# Set environment
ENV PATH="/snapcraft/.venv/bin:$PATH"
ENV PYTHONPATH="/snapcraft"

# Default command
CMD ["/bin/bash"]
