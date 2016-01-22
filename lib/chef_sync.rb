#!/usr/bin/env ruby
require 'slack/post'

class ChefSync

	require 'chef_sync/chef_resource'
	require 'chef_sync/chef_resource/cookbook'
	require 'chef_sync/chef_resource/data_bag_item'
	require 'chef_sync/chef_resource/environment'
	require 'chef_sync/chef_resource/role'
	require 'chef_sync/knife'

	RESOURCE_TYPES = [Role, Environment, DataBagItem, Cookbook]

	DRYRUN_MESSAGE = "This was a dry run. Nothing has been updated on the chef server. "

	attr_reader :post_to_slack
	attr_reader :dryrun
	attr_accessor :summary
	attr_accessor :log

	def initialize(post_to_slack=false,dryrun=true)
		@post_to_slack = post_to_slack
		@dryrun = dryrun
		@summary = ""
		@log = [summary]
	end

	def run
		self.summary = DRYRUN_MESSAGE if self.dryrun

		RESOURCE_TYPES.each do |resource|
			responses = resource.sync(self.dryrun)
			self.summary << "#{responses.count}/#{resource.action_summary.length} #{resource.resource_type}s have changed. "
			self.log += responses
		end

		case self.post_to_slack
		when true
			self.post
		when false
			puts self.summary, self.log
		end
	end

	def post
		if ENV['CHEFSYNC_WEBHOOK_URL']
			::Slack::Post.configure(
				webhook_url: ENV['CHEFSYNC_WEBHOOK_URL'],
				username: ENV['CHEFSYNC_USERNAME'],
				channel: ENV['CHEFSYNC_CHANNEL']
				)

			::Slack::Post.post_with_attachments(self.summary, self.slack_attachment)
		else
			puts "CHEFSYNC_WEBHOOK_URL was not set. Cannot post to Slack."
		end
	end

	def slack_attachment
		[
			{
				fallback: self.summary,
				fields: [
					{
						value: self.log.join("\n"),
						short: false
					}
				]
			}
		]
	end

end
