# frozen_string_literal: true

module Httpd
  module YAMLConfig
    # Native deep merge implementation (replaces deprecated Chef::Mixin::DeepMerge)
    # @param source [Hash] The source hash to merge from
    # @param target [Hash] The target hash to merge into
    # @return [Hash] The merged hash
    def deep_merge_hash(source, target)
      target = target.dup
      source.each do |key, value|
        target[key] = if value.is_a?(Hash) && target[key].is_a?(Hash)
                        deep_merge_hash(value, target[key])
                      else
                        value
                      end
      end
      target
    end

    # Process a YAML configuration file with Chef 18+ style handling
    # @param file_path [String] The path to write the YAML file
    # @param config [Hash] The configuration hash to write as YAML
    # @param owner [String] The owner of the file
    # @param group [String] The group of the file
    # @param mode [String] The file mode
    # @return [Chef::Resource] The file resource
    def create_yaml_config(file_path, config, owner: 'root', group: 'root', mode: '0644')
      require 'yaml'

      file file_path do
        content YAML.dump(config)
        owner owner
        group group
        mode mode
        action :create
      end
    end

    # Read a YAML configuration file with proper error handling
    # @param file_path [String] The path to the YAML file
    # @return [Hash] The parsed YAML content or empty hash on error
    def read_yaml_config(file_path)
      require 'yaml'

      if ::File.exist?(file_path)
        begin
          YAML.load_file(file_path, permitted_classes: [Symbol]) || {}
        rescue StandardError => e
          Chef.logger.warn("Error parsing YAML file #{file_path}: #{e.message}")
          {}
        end
      else
        Chef.logger.debug("YAML file not found: #{file_path}")
        {}
      end
    end

    # Merge new configuration with existing YAML file
    # @param file_path [String] The path to the YAML file
    # @param new_config [Hash] The new configuration to merge
    # @param owner [String] The owner of the file
    # @param group [String] The group of the file
    # @param mode [String] The file mode
    # @return [Chef::Resource] The file resource
    def merge_yaml_config(file_path, new_config, owner: 'root', group: 'root', mode: '0644')
      require 'yaml'

      existing_config = read_yaml_config(file_path)
      merged_config = deep_merge_hash(new_config, existing_config)

      file file_path do
        content YAML.dump(merged_config)
        owner owner
        group group
        mode mode
        action :create
      end
    end

    # Convert a Ruby hash to a YAML string with proper error handling
    # @param hash [Hash] The hash to convert to YAML
    # @return [String] The YAML string representation
    def hash_to_yaml(hash)
      require 'yaml'

      begin
        YAML.dump(hash)
      rescue StandardError => e
        Chef.logger.warn("Error converting hash to YAML: #{e.message}")
        "{}\n" # Return empty YAML object on error
      end
    end

    # Parse a YAML string to a Ruby hash with proper error handling
    # @param yaml_string [String] The YAML string to parse
    # @return [Hash] The parsed hash
    def yaml_to_hash(yaml_string)
      require 'yaml'

      begin
        YAML.safe_load(yaml_string, permitted_classes: [Symbol]) || {}
      rescue StandardError => e
        Chef.logger.warn("Error parsing YAML string: #{e.message}")
        {} # Return empty hash on error
      end
    end
  end
end

Chef::DSL::Recipe.include(Httpd::YAMLConfig)
Chef::Resource.include(Httpd::YAMLConfig)
