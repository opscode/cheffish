require 'cheffish'
require 'chef_compat/resource'

class Chef
  class Resource
    class ChefAcl < ChefCompat::Resource
      resource_name :chef_acl

      allowed_actions :create, :nothing
      default_action :create

      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      # Path of the thing being secured, e.g. nodes, nodes/*, nodes/mynode,
      # */*, **, roles/base, data/secrets, cookbooks/apache2, /users/*,
      # /organizations/foo/nodes/x
      property :path, String, name_property: true

      # Whether to change things recursively.  true means it will descend all children
      # and make the same modifications to them.  :on_change will only descend if
      # the parent has changed.  :on_change is the default.
      property :recursive, [ true, false, :on_change ], default: :on_change

      # Specifies that this is a complete specification for the acl (i.e. rights
      # you don't specify will be reset to their defaults)
      property :complete, [true, false]

      property :raw_json, Hash
      property :chef_server, Hash

      # rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]
      # rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]
      # rights :all, :users => 'jkeiser'
      def rights(*values)
        if values.size == 0
          @rights
        else
          args = values.pop
          args[:permissions] ||= []
          values.each do |value|
            args[:permissions] |= Array(value)
          end
          @rights ||= []
          @rights << args
        end
      end

      # remove_rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]
      # remove_rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]
      # remove_rights :all, :users => [ 'jkeiser', 'adam' ]
      def remove_rights(*values)
        if values.size == 0
          @remove_rights
        else
          args = values.pop
          args[:permissions] ||= []
          values.each do |value|
            args[:permissions] |= Array(value)
          end
          @remove_rights ||= []
          @remove_rights << args
        end
      end
    end
  end
end
