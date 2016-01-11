require 'chef'
require 'ridley'

Ridley::Logging.logger.level = Logger.const_get('ERROR')

class Cookbook < ChefSync::ChefResource

	@resource_type = 'cookbook'

	attr_reader :local_version_number
	attr_reader :remote_version_number

	def initialize(name, local_version_number, remote_version_number)
		@local_version_number = local_version_number
		@remote_version_number = remote_version_number

		super(name)
	end

	def self.sync
		local_cookbook_list = self.get_local_resource_list
		remote_cookbook_list = self.get_remote_resource_list
		notifications = []

		local_cookbook_list.each do |cb, ver|
			resource = self.new(cb, ver, remote_cookbook_list[cb])
			response = resource.compare_local_and_remote_versions
			notifications << response if response
		end
		return [local_cookbook_list.length, notifications]
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
			return "#{self.resource_path} is new and should be uploaded to the chef server."
		when local_ver < remote_ver
			return "Warning: remote #{self.resource_path} is newer than the local version."
		when local_ver == remote_ver
			return self.compare_cookbook_file_checksums
		when local_ver > remote_ver
			return "#{self.resource_path} should be uploaded to the chef server."
		end
	end

	def compare_cookbook_file_checksums
		remote_cookbook_files = self.get_remote_resource

		remote_cookbook_files.each do |remote_file|
			local_file_path = "#{self.resource_path}/#{remote_file['path']}"
			begin
				local_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(File.open(local_file_path))
				message = "Warning: local file #{local_file_path} has changed without a cookbook version change." unless local_file_checksum == remote_file['checksum']
				return message
			rescue Errno::ENOENT => e
				return "Warning: remote file #{local_file_path} doesn't exist locally."
			end
		end
	end

end
