# frozen_string_literal: true

name 'httpd'
maintainer 'Thomas Vincent'
maintainer_email 'thomasvincent@example.com'
license 'Apache-2.0'
description 'Installs and configures Apache HTTP Server with advanced features'
version '1.1.0'
chef_version '>= 18.0'
source_url 'https://github.com/thomasvincent/chef-httpd-cookbook'
issues_url 'https://github.com/thomasvincent/chef-httpd-cookbook/issues'

# Supported platforms as of January 2026
# Linux - Docker/Dokken testable
supports 'ubuntu', '>= 22.04'
supports 'debian', '>= 12.0'
supports 'redhat', '>= 9.0'
supports 'rocky', '>= 9.0'
supports 'almalinux', '>= 9.0'
supports 'amazon', '>= 2023.0'

# BSD - Vagrant testable
supports 'freebsd', '>= 14.0'

# macOS - Vagrant or local testable
supports 'mac_os_x', '>= 13.0'

# Dependencies for SSL/Let's Encrypt functionality
depends 'acme', '~> 5.0'
