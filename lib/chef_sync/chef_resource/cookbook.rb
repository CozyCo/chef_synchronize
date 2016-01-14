require 'chef'
require 'ridley'

Ridley::Logging.logger.level = Logger.const_get('ERROR')

class Cookbook < ChefSync::ChefResource

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

	def initialize(name, local_version_number, remote_version_number)
		@local_version_number = local_version_number
		@remote_version_number = remote_version_number
		@file_change_log = {}

		super(name)
	end

	def self.sync(dryrun=false)
		local_cookbook_list = self.get_local_resource_list
		remote_cookbook_list = self.get_remote_resource_list
		self.resource_total = local_cookbook_list.count
		action_summary = {}

		local_cookbook_list.each do |cb, ver|
			resource = self.new(cb, ver, remote_cookbook_list[cb])
			action_summary[resource] = resource.sync(dryrun)
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

	def self.get_remote_resource_list
		return self.get_formatted_knife_data(self.knife_list_resource_command)
	end

	def self.knife_upload_resource_command
		return "#{self.resource_type}_upload".to_sym
	end

	#Helper function to parse knife data.
	def self.get_formatted_knife_data(command, args=[])
		args << '-fj'
		knife_output = self.fork_knife_capture(command, args)
		parsed_output = self.parse_knife_capture_output(knife_output)
		cookbooks = {}
		parsed_output.each do |c|
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

	def update_remote_resource
		return self.class.knife_upload(self.class.knife_upload_resource_command, [self.name, '--freeze'])
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
