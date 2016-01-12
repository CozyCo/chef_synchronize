#!/usr/bin/env ruby
class ChefSync

	require 'chef_sync/chef_resource'
	require 'chef_sync/chef_resource/cookbook'
	require 'chef_sync/chef_resource/data_bag_item'
	require 'chef_sync/chef_resource/environment'
	require 'chef_sync/chef_resource/role'

	RESOURCE_TYPES = [Role, Environment, DataBagItem, Cookbook]

	def required_actions
		return RESOURCE_TYPES.each_with_object({}) {|r, output| output[r.resource_type] = r.sync}
	end

	def print_output
		self.required_actions.each do |resource, responses|
			puts "#{resource}:"
			puts responses
		end
	end

end
