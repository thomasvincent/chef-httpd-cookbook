# frozen_string_literal: true

unified_mode true

provides :httpd_waf_rule

description 'Manages ModSecurity WAF rules for Apache HTTP Server'

property :rule_name, String,
         name_property: true,
         description: 'Name of the rule (used for file naming)'

property :rule_id, [Integer, String],
         description: 'ModSecurity rule ID (unique identifier)'

property :waf_action, String,
         equal_to: %w(block allow log pass deny drop),
         default: 'block',
         description: 'Action to take when rule matches'

property :phase, Integer,
         equal_to: [1, 2, 3, 4, 5],
         default: 2,
         description: 'ModSecurity processing phase'

property :operator, String,
         description: 'Operator for matching (e.g., @rx, @pm, @ipMatch)'

property :target, [String, Array],
         description: 'Target to inspect (e.g., ARGS, REQUEST_URI, REQUEST_HEADERS)'

property :pattern, String,
         description: 'Pattern to match against'

property :message, String,
         description: 'Log message when rule matches'

property :severity, String,
         equal_to: %w(EMERGENCY ALERT CRITICAL ERROR WARNING NOTICE INFO DEBUG),
         default: 'WARNING',
         description: 'Severity level for logging'

property :chain, [true, false],
         default: false,
         description: 'Chain to next rule'

property :skip_after, String,
         description: 'Skip to rule with this ID after match'

property :transformations, Array,
         default: [],
         description: 'Transformations to apply (e.g., lowercase, removeWhitespace)'

property :enabled, [true, false],
         default: true,
         description: 'Whether the rule is enabled'

property :raw_rule, String,
         description: 'Raw ModSecurity rule syntax (overrides other properties)'

property :exclusion, [true, false],
         default: false,
         description: 'This is a rule exclusion/exception'

property :exclusion_target, [Integer, String],
         description: 'Rule ID to exclude'

property :exclusion_condition, String,
         description: 'Condition for exclusion (e.g., specific URI)'

action_class do
  def rule_file_path
    "#{node['httpd']['modsecurity']['conf_dir']}/rules/#{new_resource.rule_name}.conf"
  end

  def rules_dir
    "#{node['httpd']['modsecurity']['conf_dir']}/rules"
  end

  def generate_rule
    return new_resource.raw_rule if new_resource.raw_rule

    if new_resource.exclusion
      generate_exclusion_rule
    else
      generate_standard_rule
    end
  end

  def generate_standard_rule
    targets = new_resource.target.is_a?(Array) ? new_resource.target.join('|') : new_resource.target
    operator = new_resource.operator || '@rx'

    rule_parts = [
      "SecRule #{targets} \"#{operator} #{new_resource.pattern}\"",
    ]

    action_parts = [
      "id:#{new_resource.rule_id}",
      "phase:#{new_resource.phase}",
    ]

    # Add transformations
    new_resource.transformations.each do |t|
      action_parts << "t:#{t}"
    end

    # Add action
    action_parts << case new_resource.waf_action
                    when 'block'
                      'deny,status:403'
                    when 'allow'
                      'allow'
                    when 'log'
                      'log,noauditlog'
                    when 'pass'
                      'pass'
                    when 'deny'
                      'deny,status:403'
                    when 'drop'
                      'drop'
                    end

    action_parts << 'log' unless new_resource.waf_action == 'log'
    action_parts << "msg:'#{new_resource.message}'" if new_resource.message
    action_parts << "severity:#{new_resource.severity}"
    action_parts << 'chain' if new_resource.chain
    action_parts << "skipAfter:#{new_resource.skip_after}" if new_resource.skip_after

    rule_parts << "\"#{action_parts.join(',')}\""

    rule_parts.join(' ')
  end

  def generate_exclusion_rule
    if new_resource.exclusion_condition
      <<~RULE
        SecRule REQUEST_URI "#{new_resource.exclusion_condition}" \\
            "id:#{new_resource.rule_id},phase:1,pass,nolog,ctl:ruleRemoveById=#{new_resource.exclusion_target}"
      RULE
    else
      "SecRuleRemoveById #{new_resource.exclusion_target}"
    end
  end
end

action :create do
  # Create rules directory if it doesn't exist
  directory rules_dir do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  rule_content = generate_rule

  template rule_file_path do
    source 'waf_rule.conf.erb'
    cookbook 'httpd'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      rule_name: new_resource.rule_name,
      enabled: new_resource.enabled,
      rule_content: rule_content
    )
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
    action :create
  end
end

action :delete do
  file rule_file_path do
    action :delete
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  end
end

action :enable do
  if ::File.exist?(rule_file_path)
    edit_resource!(:template, rule_file_path) do
      variables(
        rule_name: new_resource.rule_name,
        enabled: true,
        rule_content: generate_rule
      )
    end
  else
    action_create
  end
end

action :disable do
  if ::File.exist?(rule_file_path)
    edit_resource!(:template, rule_file_path) do
      variables(
        rule_name: new_resource.rule_name,
        enabled: false,
        rule_content: generate_rule
      )
    end
  end
end
