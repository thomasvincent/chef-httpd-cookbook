FROM ubuntu:22.04

# Install minimal dependencies and Chef Workstation via official script
RUN apt-get update && apt-get install -y \
    curl \
    sudo \
    && curl -L https://omnitruck.chef.io/install.sh | bash -s -- -P chef-workstation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace