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

	attr_reader :file_change_log

	def initialize(local_version_number:, remote_version_number:, **opts)
		@local_version_number = local_version_number
		@remote_version_number = remote_version_number
		@file_change_log = {}

		super(opts)
	end

	def self.changes(dryrun)
		self.reject {|resource| resource.change == :none}.flat_map do |resource|
			self.actionable_change?(resource.change) ? prefix = "" : prefix = "WARNING: "
			summary = [prefix + resource.resource_path + CHANGE_LOG_SUMMARIES[resource.change]]
			file_changes = resource.file_change_log.map {|file, file_action| file + FILE_CHANGE_LOG_SUMMARIES[file_action]}
			file_changes.empty? ? summary : summary << file_changes
		end
	end

	def self.get_local_resources
		local_cookbooks = self.local_knife.list
		remote_cookbooks = self.remote_knife.list

		return local_cookbooks.map do |cb, local_ver|
			{name: cb, local_version_number: local_ver, remote_version_number: remote_cookbooks[cb]}
		end
	end

	def get_remote_resource
		ridley = Ridley.from_chef_config
		remote_cookbook = ridley.cookbook.find(@name, @remote_version_number)
		remote_cookbook_files = Chef::CookbookVersion::COOKBOOK_SEGMENTS.collect { |d| remote_cookbook.method(d).call }.flatten
		return remote_cookbook_files
	end

	def upload_resource
		return self.class.remote_knife.upload(@name, '--freeze')
	end

	def compare_cookbook_files
		remote_cookbook_files = self.get_remote_resource

		remote_cookbook_files.each do |remote_file|
			local_file_path = "#{self.resource_path}/#{remote_file['path']}"
			begin
				local_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(File.open(local_file_path))
				@file_change_log[local_file_path] = :file_changed unless local_file_checksum == remote_file['checksum']
			rescue Errno::ENOENT => e
				@file_change_log[local_file_path] = :file_missing
			end
		end
		return @file_change_log
	end

	def compare_local_and_remote_versions
		local_ver = @local_version_number
		remote_ver = @remote_version_number

		case
		when !@remote_version_number
			@change = :create
		when @local_version_number < @remote_version_number
			@change = :version_regressed
		when @local_version_number == @remote_version_number
			@change = :version_changed unless self.compare_cookbook_files.empty?
		when @local_version_number > @remote_version_number
			@change = :update
		end

		return @change
	end

end
