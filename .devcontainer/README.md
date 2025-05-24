# Development Container for Chef HTTPD Cookbook

This directory contains the configuration for a development container that provides a consistent, reproducible development environment for working with this Chef cookbook.

## Features

- **Chef Workstation**: Full Chef development tools pre-installed
- **Docker-in-Docker**: Run Test Kitchen with Docker driver inside the container
- **Ruby Environment**: Ruby and Bundler configured for ChefSpec tests
- **Testing Tools**: Cookstyle, ChefSpec, InSpec, and Kitchen pre-installed
- **VS Code Integration**: Recommended extensions and settings for Chef development

## Prerequisites

- Docker Desktop or Docker Engine
- Visual Studio Code with Remote-Containers extension (recommended)
- OR any IDE that supports Dev Containers

## Getting Started

### Using VS Code

1. Open the cookbook directory in VS Code
2. When prompted, click "Reopen in Container" or run the command "Remote-Containers: Reopen in Container"
3. Wait for the container to build (first time may take a few minutes)
4. The terminal will open with all Chef tools available

### Using Docker Compose Directly

```bash
cd .devcontainer
docker-compose up -d chef-dev
docker-compose exec chef-dev bash
```

## Available Commands

Inside the container, you have access to:

- `chef` - Chef Infra Client
- `cookstyle` - Ruby style checking for Chef cookbooks
- `kitchen` - Test Kitchen for integration testing
- `inspec` - InSpec for compliance testing
- `rspec` - RSpec for unit testing
- `bundle` - Bundler for dependency management

## Running Tests

### Linting and Style Checks
```bash
cookstyle .
```

### Unit Tests (ChefSpec)
```bash
bundle install
bundle exec rspec
```

### Integration Tests (Test Kitchen)
```bash
kitchen test
```

## Test Targets

The docker-compose.yml includes example test target containers:
- `test-ubuntu`: Ubuntu 22.04 for testing
- `test-centos`: CentOS 8 for testing

These can be used as Kitchen targets with the Docker driver.

## Customization

### Adding Dependencies

To add Ruby gems, update the Gemfile and run:
```bash
bundle install
```

### VS Code Extensions

The devcontainer.json includes recommended extensions. You can add more in the `customizations.vscode.extensions` array.

### Environment Variables

Add environment variables in docker-compose.yml under the `environment` section of the `chef-dev` service.

## Troubleshooting

### Permission Issues

The container runs as user `chef` (UID 1000) to match typical host user permissions. If you have permission issues, ensure your host user has UID 1000 or modify the Dockerfile accordingly.

### Docker Socket Access

The container mounts the Docker socket for Docker-in-Docker functionality. Ensure Docker Desktop/Engine is running on your host.

### Slow Performance on macOS

Use the `:cached` volume mount option (already configured) for better performance on macOS.