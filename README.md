# HTTPD Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/httpd.svg)](https://supermarket.chef.io/cookbooks/httpd)
[![CI](https://github.com/thomasvincent/chef-httpd-cookbook/actions/workflows/ci.yml/badge.svg)](https://github.com/thomasvincent/chef-httpd-cookbook/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A modern, advanced Chef cookbook to install and configure Apache HTTP Server 2.4+ with comprehensive SSL/TLS support, Let's Encrypt integration, and security best practices.

## Requirements

### Platforms

- Ubuntu 22.04+, 24.04+
- Debian 11+, 12+
- CentOS Stream 9+
- Red Hat Enterprise Linux 9+
- Amazon Linux 2023+
- Rocky Linux 9+
- AlmaLinux 9+
- Fedora 38+

### Chef

- Chef 18.0+

### Dependencies

- `acme` - For Let's Encrypt certificate management

## Features

- **Apache 2.4+ Support** - Modern Apache with HTTP/2 and HTTP/3
- **SSL/TLS Hardening** - Modern cipher suites based on Mozilla guidelines
- **Let's Encrypt Integration** - Automatic certificate provisioning and renewal
- **Multi-Platform** - Works across all major Linux distributions
- **Test Coverage** - Comprehensive unit and integration tests
- **CI/CD Ready** - GitHub Actions workflow included

## SSL/TLS Configuration

### Basic SSL Setup

Include the SSL recipe in your run list:

```ruby
include_recipe 'httpd::ssl'
```

Or in your node's run_list:

```json
{
  "run_list": [
    "recipe[httpd::default]",
    "recipe[httpd::ssl]"
  ]
}
```

### Let's Encrypt Integration

To enable automatic Let's Encrypt certificates:

```ruby
default['httpd']['ssl']['letsencrypt']['enabled'] = true
default['httpd']['ssl']['letsencrypt']['contact'] = 'admin@example.com'
default['httpd']['ssl']['letsencrypt']['domains'] = ['example.com', 'www.example.com']
default['httpd']['ssl']['letsencrypt']['staging'] = false  # Set to true for testing
```

### Custom SSL Configuration

```ruby
default['httpd']['ssl']['protocols'] = 'TLSv1.2 TLSv1.3'
default['httpd']['ssl']['ciphers'] = 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256'
default['httpd']['ssl']['honor_cipher_order'] = 'off'
default['httpd']['ssl']['hsts']['enabled'] = true
default['httpd']['ssl']['hsts']['max_age'] = 63072000
default['httpd']['ssl']['ocsp_stapling'] = true
```

### SSL Virtual Host Example

```ruby
httpd_vhost 'secure.example.com' do
  port 443
  document_root '/var/www/secure.example.com'
  ssl_enabled true
  ssl_cert '/etc/letsencrypt/live/example.com/fullchain.pem'
  ssl_key '/etc/letsencrypt/live/example.com/privkey.pem'
  redirect_http_to_https true
  action :create
end
```

## Security Best Practices

This cookbook implements the following security measures:

### TLS Configuration
- **TLS 1.2 and 1.3 only** - Older protocols (SSLv3, TLS 1.0, TLS 1.1) are disabled
- **Modern cipher suites** - Based on Mozilla SSL Configuration Generator
- **Perfect Forward Secrecy** - ECDHE and DHE key exchange only
- **OCSP Stapling** - Improved certificate validation performance

### HTTP Security Headers
- **HSTS** - Strict Transport Security with preload support
- **X-Content-Type-Options** - Prevents MIME type sniffing
- **X-Frame-Options** - Clickjacking protection
- **X-XSS-Protection** - XSS filter enabled
- **Referrer-Policy** - Controls referrer information

### Server Hardening
- **ServerTokens Prod** - Minimal server information disclosure
- **ServerSignature Off** - No server signature on error pages
- **TraceEnable Off** - HTTP TRACE method disabled
- **Directory listing disabled** - Prevents information disclosure

### Certificate Management
- **Automatic renewal** - Certbot cron job for Let's Encrypt
- **Secure key storage** - Proper file permissions (0600)
- **Certificate validation** - OCSP stapling enabled

## Custom Resources

### httpd_install

Install Apache HTTP Server.

```ruby
httpd_install 'default' do
  version '2.4'
  mpm 'event'
  install_method 'package'
  action :install
end
```

### httpd_vhost

Configure Apache virtual hosts.

```ruby
httpd_vhost 'example.com' do
  port 80
  document_root '/var/www/example.com'
  action :create
end
```

### httpd_module

Enable or disable Apache modules.

```ruby
httpd_module 'ssl' do
  action :enable
end
```

### httpd_service

Manage the Apache service.

```ruby
httpd_service 'default' do
  action [:enable, :start]
end
```

## Recipes

### default
Main recipe that orchestrates Apache HTTP Server installation. Includes installation, configuration, and service management.

### install
Installs Apache HTTP Server packages and dependencies appropriate for the platform.

### configure
Configures Apache settings including httpd.conf, security headers, and module configuration.

### service
Manages the Apache service including start, stop, restart, and reload operations.

### ssl
Configures SSL/TLS support with modern cipher suites and security best practices.

### letsencrypt
Integrates Let's Encrypt for automatic SSL certificate provisioning and renewal using the ACME protocol.

### modsecurity
Configures ModSecurity Web Application Firewall with OWASP Core Rule Set for enhanced security.

### vhosts
Manages Apache virtual hosts configuration for serving multiple websites.

### telemetry
Configures Apache metrics and monitoring integration for observability.

## Attributes

### SSL Attributes

| Attribute | Default | Description |
|-----------|---------|-------------|
| `node['httpd']['ssl']['protocols']` | `TLSv1.2 TLSv1.3` | Supported TLS protocols |
| `node['httpd']['ssl']['ciphers']` | Modern suite | SSL cipher suite |
| `node['httpd']['ssl']['honor_cipher_order']` | `off` | Server cipher preference |
| `node['httpd']['ssl']['hsts']['enabled']` | `true` | Enable HSTS header |
| `node['httpd']['ssl']['hsts']['max_age']` | `63072000` | HSTS max-age (2 years) |
| `node['httpd']['ssl']['ocsp_stapling']` | `true` | Enable OCSP stapling |
| `node['httpd']['ssl']['letsencrypt']['enabled']` | `false` | Enable Let's Encrypt |
| `node['httpd']['ssl']['letsencrypt']['contact']` | `nil` | Contact email |
| `node['httpd']['ssl']['letsencrypt']['domains']` | `[]` | Domains for certificates |

## Testing

This cookbook uses comprehensive testing:

```bash
# Run all tests
./bin/test-docker

# Run unit tests
bundle exec rspec

# Run integration tests
bundle exec kitchen test

# Run linting
bundle exec cookstyle
```

### Test Kitchen

```bash
# List available test suites
kitchen list

# Run default suite
kitchen test default-ubuntu-2204

# Run SSL suite
kitchen test ssl-ubuntu-2204
```

## Development

### Prerequisites

1. Install Docker and docker-compose
2. Install Ruby 3.2+
3. Install Bundler

### Setup

```bash
./bin/setup-dev
bundle install
```

### Running Tests Locally

```bash
# Unit tests
bundle exec rspec

# Integration tests (requires Docker)
bundle exec kitchen test
```

## Contributing

1. Fork the repository on GitHub
2. Create a feature branch (`git checkout -b feature/my-new-feature`)
3. Write tests for your changes
4. Make your changes
5. Run the test suite to ensure all tests pass
6. Commit your changes (`git commit -am 'Add new feature'`)
7. Push to the branch (`git push origin feature/my-new-feature`)
8. Create a Pull Request

Please ensure:
- All tests pass before submitting PR
- Code follows Cookstyle guidelines
- New features include appropriate tests
- Documentation is updated for any new attributes or recipes

## License

Apache 2.0

## Author

Thomas Vincent (<thomasvincent@example.com>)
