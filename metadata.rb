# frozen_string_literal: true

name 'httpd'
maintainer 'Thomas Vincent'
maintainer_email 'thomasvincent@example.com'
license 'Apache-2.0'
description 'Installs and configures Apache HTTP Server with advanced features'
version '1.1.0'
chef_version '>= 19.0'
source_url 'https://github.com/thomasvincent/httpd-cookbook'
issues_url 'https://github.com/thomasvincent/httpd-cookbook/issues'

supports 'ubuntu', '>= 22.04'
supports 'debian', '>= 11.0'
supports 'centos', '>= 9.0'
supports 'redhat', '>= 9.0'
supports 'amazon', '>= 2.0'
supports 'rocky', '>= 9.0'
supports 'alma', '>= 9.0'
supports 'fedora', '>= 38.0'
supports 'opensuse', '>= 15.0'
supports 'arch', '>= 1.0'

# We can handle our own firewall, logging, and SELinux
# depends 'selinux', '~> 4.0' # Removed - causes warnings, we handle SELinux directly
# depends 'zypper', '~> 0.4' # Removed - causes dependency issues in tests

# Suggesting (but not requiring) useful related cookbooks
# suggest 'vault', '~> 5.0' # Modern secrets management
# suggest 'audit', '~> 9.0' # For compliance phase integration
