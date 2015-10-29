require 'cheffish'
require 'chef_compat/resource'
require 'chef/environment'

class Chef
  class Resource
    class ChefEnvironment < ChefCompat::Resource
      resource_name :chef_environment

      allowed_actions :create, :delete, :nothing
      default_action :create

      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      property :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
      property :description, :kind_of => String
      property :cookbook_versions, :kind_of => Hash, :callbacks => {
        "should have valid cookbook versions" => lambda { |value| Chef::Environment.validate_cookbook_versions(value) }
      }
      property :default_attributes, :kind_of => Hash
      property :override_attributes, :kind_of => Hash

      # Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
      # reset to their defaults)
      property :complete, :kind_of => [TrueClass, FalseClass]

      property :raw_json, :kind_of => Hash
      property :chef_server, :kind_of => Hash

      # `NOT_PASSED` is defined in chef-12.5.0, this guard will ensure we
      # don't redefine it if it's already there
      NOT_PASSED=Object.new unless defined?(NOT_PASSED)

      # default 'ip_address', '127.0.0.1'
      # default [ 'pushy', 'port' ], '9000'
      # default 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # default 'ip_address', :delete
      attr_reader :default_attribute_modifiers
      def default(attribute_path, value=NOT_PASSED, &block)
        @default_attribute_modifiers ||= []
        if value != NOT_PASSED
          @default_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @default_attribute_modifiers << [ attribute_path, block ]
        else
          raise "default requires either a value or a block"
        end
      end

      # override 'ip_address', '127.0.0.1'
      # override [ 'pushy', 'port' ], '9000'
      # override 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # override 'ip_address', :delete
      attr_reader :override_attribute_modifiers
      def override(attribute_path, value=NOT_PASSED, &block)
        @override_attribute_modifiers ||= []
        if value != NOT_PASSED
          @override_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @override_attribute_modifiers << [ attribute_path, block ]
        else
          raise "override requires either a value or a block"
        end
      end

      alias :attributes :default_attributes
      alias :property :default
    end
  end
end
