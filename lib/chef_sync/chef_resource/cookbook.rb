require 'chef'
require 'ridley'

Ridley::Logging.logger.level = Logger.const_get('ERROR')

class ChefSync::Cookbook < ChefSync::ChefResource

	CHANGE_LOG_SUMMARIES = {
		:create => " was created.",
		:update => " was updated.",
		:version_regressed => " is newer than the local version.",
		:version_changed => " has changed without a version number increase."
	}

	FILE_CHANGE_LOG_SUMMARIES = {
		:file_changed => " has changed.",
		:file_missing => " does not exist locally."
	}

	@resource_type = 'cookbook'

	attr_reader :local_version_number
	attr_reader :remote_version_number
	attr_accessor :file_change_log

	def initialize(local_version_number, remote_version_number, *args)
		@local_version_number = local_version_number
		@remote_version_number = remote_version_number
		@file_change_log = {}

		super(*args)
	end

	def self.sync(dryrun)
		local_knife = ChefSync::Knife.new(self.resource_type, :local)
		remote_knife = ChefSync::Knife.new(self.resource_type, :remote)

		local_cookbook_list = self.get_resource_list(local_knife)
		remote_cookbook_list = self.get_resource_list(remote_knife)
		self.resource_total = local_cookbook_list.count
		action_summary = {}

		local_cookbook_list.each do |cb, ver|
			resource = self.new(ver, remote_cookbook_list[cb], cb, dryrun, local_knife, remote_knife)
			action_summary[resource] = resource.sync
		end
		return self.formatted_action_summary(action_summary)
	end

	def self.formatted_action_summary(action_summary)
		changed_resources = action_summary.reject {|resource, action| action == :none}
		output = []

		changed_resources.each do |resource, action|
			output << resource.resource_path + CHANGE_LOG_SUMMARIES[action]
			if action == :version_changed
				resource.file_change_log.each do |file, file_action|
					output << file + FILE_CHANGE_LOG_SUMMARIES[file_action]
				end
			end
		end
		return output
	end

	def self.get_resource_list(knife)
		return self.format_knife_data(knife.list)
	end

	#Helper function to parse knife list data into cookbooks.
	def self.format_knife_data(knife_output)
		cookbooks = {}
		knife_output.each do |c|
			cb, ver = c.gsub(/\s+/m, ' ').strip.split(" ")
			cookbooks[cb] = ver
		end
		return cookbooks
	end

	def get_remote_resource
		ridley = Ridley.from_chef_config
		remote_cookbook = ridley.cookbook.find(self.name, self.remote_version_number)
		remote_cookbook_files = Chef::CookbookVersion::COOKBOOK_SEGMENTS.collect { |d| remote_cookbook.method(d).call }.flatten
		return remote_cookbook_files
	end

	def upload_resource
		return self.remote_knife.upload(self.name, '--freeze')
	end

	def compare_cookbook_files
		remote_cookbook_files = self.get_remote_resource

		remote_cookbook_files.each do |remote_file|
			local_file_path = "#{self.resource_path}/#{remote_file['path']}"
			begin
				local_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(File.open(local_file_path))
				file_change_log[local_file_path] = :file_changed unless local_file_checksum == remote_file['checksum']
			rescue Errno::ENOENT => e
				file_change_log[local_file_path] = :file_missing
			end
		end
		return self.file_change_log
	end

	def compare_local_and_remote_versions
		local_ver = self.local_version_number
		remote_ver = self.remote_version_number

		case
		when !remote_ver
			self.change = :create
		when local_ver < remote_ver
			self.change = :version_regressed
		when local_ver == remote_ver
			self.change = :version_changed unless self.compare_cookbook_files.empty?
		when local_ver > remote_ver
			self.change = :update
		end

		return self.change
	end

end
