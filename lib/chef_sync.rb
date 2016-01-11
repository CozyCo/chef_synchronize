#!/usr/bin/env ruby
class ChefSync

	require 'chef_sync/chef_resource'
	require 'chef_sync/chef_resource/cookbook'
	require 'chef_sync/chef_resource/data_bag'
	require 'chef_sync/chef_resource/environment'
	require 'chef_sync/chef_resource/role'

	RESOURCE_TYPES = [Role, Environment, DataBag, Cookbook]

	def required_actions
		return RESOURCE_TYPES.each_with_object({}) {|r, output| output[r.resource_type] = r.sync}
	end

	def print_output
		self.required_actions.each do |resource, response|
			total_resources, messages = response
			update_count = messages.nil? ? 0 : messages.count
			puts "#{update_count}/#{total_resources} #{resource}s need updating."
			if messages
				messages.each do |m|
					puts m
				end
			end
		end
	end

end
