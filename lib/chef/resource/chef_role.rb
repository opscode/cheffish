require 'cheffish'
require 'chef_compat/resource'
require 'chef/run_list/run_list_item'

class Chef
  class Resource
    class ChefRole < ChefCompat::Resource
      resource_name :chef_role

      allowed_actions :create, :delete, :nothing
      default_action :create

      # Grab environment from with_environment
      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      property :name, Cheffish::NAME_REGEX, name_property: true
      property :description, String
      property :run_list, Array # We should let them specify it as a series of parameters too
      property :env_run_lists, Hash
      property :default_attributes, Hash
      property :override_attributes, Hash

      # Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
      # reset to their defaults)
      property :complete, [true, false]

      property :raw_json, Hash
      property :chef_server, Hash

      # `NOT_PASSED` is defined in chef-12.5.0, this guard will ensure we
      # don't redefine it if it's already there
      NOT_PASSED=Object.new unless defined?(NOT_PASSED)

      # default_attribute 'ip_address', '127.0.0.1'
      # default_attribute [ 'pushy', 'port' ], '9000'
      # default_attribute 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # default_attribute 'ip_address', :delete
      attr_reader :default_attribute_modifiers
      def default_attribute(attribute_path, value=NOT_PASSED, &block)
        @default_attribute_modifiers ||= []
        if value != NOT_PASSED
          @default_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @default_attribute_modifiers << [ attribute_path, block ]
        else
          raise "default_attribute requires either a value or a block"
        end
      end

      # override_attribute 'ip_address', '127.0.0.1'
      # override_attribute [ 'pushy', 'port' ], '9000'
      # override_attribute 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # override_attribute 'ip_address', :delete
      attr_reader :override_attribute_modifiers
      def override_attribute(attribute_path, value=NOT_PASSED, &block)
        @override_attribute_modifiers ||= []
        if value != NOT_PASSED
          @override_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @override_attribute_modifiers << [ attribute_path, block ]
        else
          raise "override_attribute requires either a value or a block"
        end
      end

      # Order matters--if two things here are in the wrong order, they will be flipped in the run list
      # recipe 'apache', 'mysql'
      # recipe 'recipe@version'
      # recipe 'recipe'
      # role ''
      attr_reader :run_list_modifiers
      attr_reader :run_list_removers
      def recipe(*recipes)
        if recipes.size == 0
          raise ArgumentError, "At least one recipe must be specified"
        end
        @run_list_modifiers ||= []
        @run_list_modifiers += recipes.map { |recipe| Chef::RunList::RunListItem.new("recipe[#{recipe}]") }
      end
      def role(*roles)
        if roles.size == 0
          raise ArgumentError, "At least one role must be specified"
        end
        @run_list_modifiers ||= []
        @run_list_modifiers += roles.map { |role| Chef::RunList::RunListItem.new("role[#{role}]") }
      end
      def remove_recipe(*recipes)
        if recipes.size == 0
          raise ArgumentError, "At least one recipe must be specified"
        end
        @run_list_removers ||= []
        @run_list_removers += recipes.map { |recipe| Chef::RunList::RunListItem.new("recipe[#{recipe}]") }
      end
      def remove_role(*roles)
        if roles.size == 0
          raise ArgumentError, "At least one role must be specified"
        end
        @run_list_removers ||= []
        @run_list_removers += roles.map { |recipe| Chef::RunList::RunListItem.new("role[#{role}]") }
      end
    end
  end
end
