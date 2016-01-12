require 'chef'
require 'ridley'

Ridley::Logging.logger.level = Logger.const_get('ERROR')

class Cookbook < ChefSync::ChefResource

	@resource_type = 'cookbook'

	attr_reader :local_version_number
	attr_reader :remote_version_number
	attr_accessor :detailed_audit_log

	def initialize(name, local_version_number, remote_version_number)
		@local_version_number = local_version_number
		@remote_version_number = remote_version_number
		@detailed_audit_log = []

		super(name)
	end

	def self.sync
		local_cookbook_list = self.get_local_resource_list
		remote_cookbook_list = self.get_remote_resource_list
		all_required_actions = {}

		local_cookbook_list.each do |cb, ver|
			resource = self.new(cb, ver, remote_cookbook_list[cb])
			all_required_actions[resource.name] = resource.compare_local_and_remote_versions
		end
		return all_required_actions
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
			file_action = {:path => local_file_path, :action => :none}
			begin
				local_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(File.open(local_file_path))
				file_action[:action] = :file_changed unless local_file_checksum == remote_file['checksum']
			rescue Errno::ENOENT => e
				file_action[:action] = :file_missing
			end
			self.detailed_audit_log << file_action if file_action[:action] != :none
		end
		return self.detailed_audit_log
	end

end
