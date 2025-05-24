FROM ubuntu:22.04

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    build-essential \
    wget \
    sudo \
    vim \
    jq \
    unzip \
    rsync \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Chef Workstation (multi-architecture support)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        CHEF_ARCH="aarch64"; \
    else \
        CHEF_ARCH="amd64"; \
    fi && \
    wget "https://packages.chef.io/files/stable/chef-workstation/24.2.1058/ubuntu/22.04/chef-workstation_24.2.1058-1_${CHEF_ARCH}.deb" \
    && dpkg -i "chef-workstation_24.2.1058-1_${CHEF_ARCH}.deb" \
    && rm "chef-workstation_24.2.1058-1_${CHEF_ARCH}.deb"

# Install Ruby (for ChefSpec and other Ruby-based testing)
RUN apt-get update && apt-get install -y \
    ruby-full \
    ruby-bundler \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI for kitchen-docker (multi-architecture support)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Create chef user
RUN useradd -m -s /bin/bash -u 1000 chef \
    && echo "chef ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/chef \
    && chmod 0440 /etc/sudoers.d/chef

# Set up Chef environment
USER chef
WORKDIR /home/chef

# Initialize Chef Workstation
RUN chef -v && \
    eval "$(chef shell-init bash)" && \
    echo 'eval "$(chef shell-init bash)"' >> ~/.bashrc

# Pre-install some common gems globally
RUN sudo gem install \
    bundler \
    cookstyle \
    kitchen-docker \
    kitchen-inspec \
    chefspec \
    rspec

# Set environment variables
ENV PATH="/opt/chef-workstation/bin:/opt/chef-workstation/embedded/bin:${PATH}"
ENV GEM_HOME="/home/chef/.gem"
ENV GEM_PATH="/home/chef/.gem:/opt/chef-workstation/embedded/lib/ruby/gems/3.1.0"

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

WORKDIR /workspace