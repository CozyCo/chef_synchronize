#!/usr/bin/env ruby
class ChefSync

	require 'chef_sync/chef_resource'
	require 'chef_sync/chef_resource/cookbook'
	require 'chef_sync/chef_resource/data_bag_item'
	require 'chef_sync/chef_resource/environment'
	require 'chef_sync/chef_resource/role'
	require 'chef_sync/knife'

	RESOURCE_TYPES = [Role, Environment, DataBagItem, Cookbook]

	def run(dryrun=true)
		output = RESOURCE_TYPES.each_with_object({}) {|resource, output| output[resource] = resource.sync(dryrun)}

		return format_output(dryrun, output)
	end

	def format_output(dryrun, output)
		dryrun_message = "This was a dry run. Nothing has been updated on the chef server. "
		dryrun ? summary = dryrun_message : summary = ""
		log = [summary]
		output.each do |resource, responses|
			summary << "#{responses.count}/#{resource.action_summary.length} #{resource.resource_type}s have changed. "
			log += responses
		end
		return log
	end

end
