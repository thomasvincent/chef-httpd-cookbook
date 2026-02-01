# frozen_string_literal: true

unified_mode true

resource_name :httpd_certificate
provides :httpd_certificate

description 'Manages SSL/TLS certificates for Apache HTTP Server with Let\'s Encrypt support'

property :domain, String,
         name_property: true,
         description: 'Primary domain for the certificate'

property :alt_names, Array,
         default: [],
         description: 'Subject Alternative Names (additional domains)'

property :email, String,
         required: true,
         description: 'Email for certificate notifications'

property :cert_provider, String,
         equal_to: %w(letsencrypt self_signed manual),
         default: 'letsencrypt',
         description: 'Certificate provider'

property :staging, [true, false],
         default: false,
         description: 'Use staging server (for testing)'

property :challenge, String,
         equal_to: %w(http dns),
         default: 'http',
         description: 'ACME challenge type'

property :webroot, String,
         default: '/var/www/letsencrypt',
         description: 'Webroot for HTTP challenge'

property :key_size, Integer,
         default: 4096,
         description: 'RSA key size'

property :cert_dir, String,
         default: '/etc/letsencrypt/live',
         description: 'Certificate directory'

property :ocsp_stapling, [true, false],
         default: true,
         description: 'Enable OCSP stapling'

property :auto_renew, [true, false],
         default: true,
         description: 'Enable automatic renewal'

property :pre_hook, String,
         description: 'Script to run before obtaining certificate'

property :post_hook, String,
         description: 'Script to run after obtaining certificate'

property :deploy_hook, String,
         description: 'Script to run after deploying certificate'

property :agree_tos, [true, false],
         default: true,
         description: 'Agree to terms of service'

action_class do
  def certbot_cmd
    if platform_family?('freebsd')
      '/usr/local/bin/certbot'
    else
      '/usr/bin/certbot'
    end
  end

  def cert_path
    "#{new_resource.cert_dir}/#{new_resource.domain}/fullchain.pem"
  end

  def key_path
    "#{new_resource.cert_dir}/#{new_resource.domain}/privkey.pem"
  end

  def chain_path
    "#{new_resource.cert_dir}/#{new_resource.domain}/chain.pem"
  end

  def all_domains
    [new_resource.domain] + new_resource.alt_names
  end

  def domain_args
    all_domains.map { |d| "-d #{d}" }.join(' ')
  end

  def acme_server
    if new_resource.staging
      'https://acme-staging-v02.api.letsencrypt.org/directory'
    else
      'https://acme-v02.api.letsencrypt.org/directory'
    end
  end
end

action :create do
  case new_resource.cert_provider
  when 'letsencrypt'
    # Install certbot and Apache plugin
    package 'certbot' do
      package_name node['httpd']['letsencrypt']['certbot_package']
      action :install
    end

    package 'certbot-apache' do
      package_name node['httpd']['letsencrypt']['apache_plugin']
      action :install
      only_if { new_resource.challenge == 'http' }
    end

    # Create webroot directory for HTTP challenge
    if new_resource.challenge == 'http'
      directory new_resource.webroot do
        owner node['httpd']['user']
        group node['httpd']['group']
        mode '0755'
        recursive true
        action :create
      end

      # Create .well-known/acme-challenge directory
      directory "#{new_resource.webroot}/.well-known/acme-challenge" do
        owner node['httpd']['user']
        group node['httpd']['group']
        mode '0755'
        recursive true
        action :create
      end
    end

    # Build certbot command
    certbot_options = [
      'certonly',
      '--non-interactive',
      "--email #{new_resource.email}",
      "--server #{acme_server}",
      "--rsa-key-size #{new_resource.key_size}",
      domain_args,
    ]

    certbot_options << '--agree-tos' if new_resource.agree_tos

    certbot_options << if new_resource.challenge == 'http'
                         "--webroot -w #{new_resource.webroot}"
                       else
                         '--manual --preferred-challenges dns'
                       end

    certbot_options << "--pre-hook \"#{new_resource.pre_hook}\"" if new_resource.pre_hook
    certbot_options << "--post-hook \"#{new_resource.post_hook}\"" if new_resource.post_hook
    certbot_options << "--deploy-hook \"#{new_resource.deploy_hook}\"" if new_resource.deploy_hook

    # Request certificate
    execute "certbot_#{new_resource.domain}" do
      command "#{certbot_cmd} #{certbot_options.join(' ')}"
      not_if { ::File.exist?(cert_path) }
      action :run
    end

    # Enable OCSP stapling if requested
    if new_resource.ocsp_stapling
      template "#{node['httpd']['conf_dir']}/ssl-ocsp-#{new_resource.domain}.conf" do
        source 'ssl-ocsp.conf.erb'
        cookbook 'httpd'
        owner 'root'
        group 'root'
        mode '0644'
        variables(
          domain: new_resource.domain,
          cert_path: cert_path
        )
        notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
        action :create
      end
    end

  when 'self_signed'
    # Create SSL directory
    directory ::File.dirname(cert_path) do
      recursive true
      action :create
    end

    # Generate self-signed certificate
    execute "generate_self_signed_#{new_resource.domain}" do
      command <<~CMD
        openssl req -x509 -nodes -days 365 \
          -newkey rsa:#{new_resource.key_size} \
          -keyout #{key_path} \
          -out #{cert_path} \
          -subj "/CN=#{new_resource.domain}/emailAddress=#{new_resource.email}"
      CMD
      not_if { ::File.exist?(cert_path) }
      action :run
    end

  when 'manual'
    # Manual certificates - just verify paths exist
    Chef::Log.info("Manual certificate management for #{new_resource.domain}")
    Chef::Log.info("Expecting cert at: #{cert_path}")
    Chef::Log.info("Expecting key at: #{key_path}")
  end
end

action :renew do
  return unless new_resource.cert_provider == 'letsencrypt'

  execute "certbot_renew_#{new_resource.domain}" do
    command "#{certbot_cmd} renew --cert-name #{new_resource.domain}"
    only_if { ::File.exist?(cert_path) }
    action :run
  end
end

action :revoke do
  return unless new_resource.cert_provider == 'letsencrypt'

  execute "certbot_revoke_#{new_resource.domain}" do
    command "#{certbot_cmd} revoke --cert-name #{new_resource.domain} --non-interactive"
    only_if { ::File.exist?(cert_path) }
    action :run
  end
end

action :delete do
  case new_resource.cert_provider
  when 'letsencrypt'
    execute "certbot_delete_#{new_resource.domain}" do
      command "#{certbot_cmd} delete --cert-name #{new_resource.domain} --non-interactive"
      only_if { ::File.exist?(cert_path) }
      action :run
    end
  else
    file cert_path do
      action :delete
    end

    file key_path do
      action :delete
    end

    file chain_path do
      action :delete
      only_if { ::File.exist?(chain_path) }
    end
  end

  # Remove OCSP config
  file "#{node['httpd']['conf_dir']}/ssl-ocsp-#{new_resource.domain}.conf" do
    action :delete
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  end
end
