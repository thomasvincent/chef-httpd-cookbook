# frozen_string_literal: true

# Policyfile.rb - Cookbook version policy for httpd cookbook
name 'httpd'

# Where to find external cookbooks
default_source :supermarket

# Run List for nodes using this cookbook
run_list 'httpd::default'

# Cookbook:: versions we use
cookbook 'httpd', path: '.'
cookbook 'apt', '~> 7.4'
cookbook 'yum', '~> 7.4'
cookbook 'selinux', '~> 4.0'

# Gem dependencies are managed via Gemfile, not Policyfile
