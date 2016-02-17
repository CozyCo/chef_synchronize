#!/usr/bin/env ruby
require 'slack/post'

class ChefSync

	require 'chef_sync/chef_component'
	require 'chef_sync/chef_component/cookbook'
	require 'chef_sync/chef_component/data_bag_item'
	require 'chef_sync/chef_component/environment'
	require 'chef_sync/chef_component/role'
	require 'chef_sync/knife'

	RESOURCE_TYPES = [Role, Environment, DataBagItem, Cookbook]

	DRYRUN_MESSAGE = "This was a dry run. Nothing has been updated on the chef server. "
	DEFAULT_LOG_MESSAGE = "There were no changes."

	def initialize(slack=false,dryrun=true)
		@slack = slack
		@dryrun = dryrun
		@summary = ""
		@log = []
	end

	def run
		@summary = DRYRUN_MESSAGE.dup if @dryrun

		RESOURCE_TYPES.each do |resource|
			responses = resource.changes(@dryrun)
			@summary << "#{responses.count}/#{resource.total_resources} #{resource.resource_type}s have changed. "
			@log += responses
		end

		@log << DEFAULT_LOG_MESSAGE if @log.empty?

		self.post_to_slack if @slack
		return @summary, @log
	end

	def post_to_slack
		opts = { webhook_url: ENV['CHEFSYNC_SLACK_WEBHOOK_URL'] }
		opts[:username] = ENV['CHEFSYNC_SLACK_USERNAME'] if ENV['CHEFSYNC_SLACK_USERNAME']
		opts[:channel] = ENV['CHEFSYNC_SLACK_CHANNEL'] if ENV['CHEFSYNC_SLACK_CHANNEL']

		::Slack::Post.configure( opts )
		begin
			::Slack::Post.post_with_attachments(self.pretext, self.slack_attachment)
		#Assuming that a RuntimeError is due to improperly configured Slack::Post.
		rescue RuntimeError => e
			puts "Couldn't post to Slack: #{e}"
		end
	end

	def slack_attachment
		[
			{
				fallback: @summary,
				fields: [
					{
						title: 'Summary',
						value: @summary,
						short: false
					},
					{
						title: 'Changes',
						value: @log.join("\n"),
						short: false
					}
				]
			}
		]
	end

	def pretext
		if ENV['CHEFSYNC_CI_BUILD_URL'].nil? or ENV['CHEFSYNC_COMMIT_URL'].nil?
			return "chef-sync run triggered."
		else
			return "<#{ENV['CHEFSYNC_CI_BUILD_URL']}|CI build> triggered by <#{ENV['CHEFSYNC_COMMIT_URL']}|commit>."
		end
	end

end
