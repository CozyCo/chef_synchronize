require 'chef'
require 'ridley'

Ridley::Logging.logger.level = Logger.const_get('ERROR')

class Cookbook < ChefSync::ChefResource

	REQUIRED_ACTION_LOG_SUMMARIES = {
		:create => " was created.",
		:update => " was updated.",
		:version_regressed => " is newer than the local version.",
		:version_changed => " has changed without a version number increase."
	}

	FILE_AUDIT_LOG_SUMMARIES = {
		:file_changed => " has changed.",
		:file_missing => " does not exist locally."
	}

	@resource_type = 'cookbook'

	attr_reader :local_version_number
	attr_reader :remote_version_number
	attr_accessor :file_audit_log

	def initialize(name, local_version_number, remote_version_number)
		@local_version_number = local_version_number
		@remote_version_number = remote_version_number
		@file_audit_log = {}

		super(name)
	end

	def self.sync
		local_cookbook_list = self.get_local_resource_list
		remote_cookbook_list = self.get_remote_resource_list
		self.resource_total = local_cookbook_list.count
		action_summary = {}

		local_cookbook_list.each do |cb, ver|
			resource = self.new(cb, ver, remote_cookbook_list[cb])
			action_summary[resource] = resource.compare_local_and_remote_versions
		end
		return self.formatted_action_summary(action_summary)
	end

	def self.formatted_action_summary(action_summary)
		changed_resources = action_summary.reject {|resource, action| action == :none}
		output = []

		changed_resources.each do |resource, action|
			output << resource.resource_path + REQUIRED_ACTION_LOG_SUMMARIES[action]
			if action == :version_changed
				resource.file_audit_log.each do |file, file_action|
					output << file + FILE_AUDIT_LOG_SUMMARIES[file_action]
				end
			end
		end
		return output
	end

	def self.get_remote_resource_list
		return self.get_formatted_knife_data(self.knife_list_resource_command)
	end

	#Helper function to parse knife data.
	def self.get_formatted_knife_data(command, args=[])
		args << '-fj'
		parsed_output = self.fork_knife_capture(command, args)
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

	def compare_local_and_remote_versions
		local_ver = self.local_version_number
		remote_ver = self.remote_version_number

		case
		when !remote_ver
			self.required_action = :create
		when local_ver < remote_ver
			self.required_action = :version_regressed
		when local_ver == remote_ver
			self.required_action = :version_changed unless self.compare_cookbook_files.empty?
		when local_ver > remote_ver
			self.required_action = :update
		end

		return self.required_action
	end

	def compare_cookbook_files
		remote_cookbook_files = self.get_remote_resource

		remote_cookbook_files.each do |remote_file|
			local_file_path = "#{self.resource_path}/#{remote_file['path']}"
			begin
				local_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(File.open(local_file_path))
				file_audit_log[local_file_path] = :file_changed unless local_file_checksum == remote_file['checksum']
			rescue Errno::ENOENT => e
				file_audit_log[local_file_path] = :file_missing
			end
		end
		return self.file_audit_log
	end

end
