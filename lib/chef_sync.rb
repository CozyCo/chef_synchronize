#!/usr/bin/env ruby
require 'json'
require 'chef'
require 'ridley'
require 'knife/api'

Ridley::Logging.logger.level = Logger.const_get('FATAL')
Celluloid.shutdown_timeout = 0.1

module ChefSync
	
	def sync
		resources = [Role, Environment, DataBag, Cookbook]
		return resources.each_with_object({}) {|r, output| output[r.resource_type] = r.sync}
	end
	module_function :sync

	class ChefResource

		#Need to extend Chef::Knife::API in this class because knife_capture is top-level.
		extend Chef::Knife::API

		class << self; attr_accessor :resource_type end
		@resource_type = ''

		attr_reader :name

		def initialize(name)
			@name = name
		end

		def self.sync
			local_resource_list = self.get_local_resource_list
			notifications = []
			local_resource_list.each do |resource_name|
				resource = self.new(resource_name)
				response = resource.compare_local_and_remote_versions
				notifications << response if response
			end

			return [local_resource_list.length, notifications]
		end

		def self.get_local_resource_list
			return self.get_formatted_knife_data(self.knife_list_resource_command, ['-z'])
		end

		def self.knife_list_resource_command
			return "#{self.resource_type}_list".to_sym
		end

		def self.knife_show_resource_command
			return "#{self.resource_type}_show".to_sym
		end

		# This is the hackiest hack ever.
		# Chef::Knife keeps a persistent option state -- if you add
		# an option like `--local-mode` once, it will be used on
		# _every_ future call to Chef::Knife. I would _love_ to
		# figure out how to change this behavior (lost many hours trying),
		# but until then, we fork a new process for `knife_capture` so
		# that we do not taint our global state.
		def self.fork_knife_capture(command, args)
			reader, writer = IO.pipe

			pid = fork do
				reader.close
				output, stderr, status = knife_capture(command, args)
				Marshal.dump([output, stderr, status], writer)
			end

			writer.close
			command_output = reader.read
			Process.wait(pid)
			output, stderr, status = Marshal.load(command_output)

			begin
				return JSON.parse(output)
			#Assuming here that a parser error means no data was returned and there was a knife error.
			rescue JSON::ParserError => e
				puts "Received error #{stderr} when trying to run knife_capture(#{command}, #{args})."
				puts "STDOUT:\n" + output
				puts "STDERR:\n" + stderr
			end
		end

		#Helper function to parse knife data.
		def self.get_formatted_knife_data(command, args=[])
			args << '-fj'
			return self.fork_knife_capture(command, args)
		end

		def resource_path
			return "#{self.class.resource_type}s/#{self.name}"
		end

		def get_local_resource
			return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, '-z'])
		end

		def get_remote_resource
			return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name])
		end

		def compare_local_and_remote_versions
			local_resource = self.get_local_resource
			remote_resource = self.get_remote_resource

			case
			when local_resource != remote_resource
				return "#{self.resource_path} should be uploaded to the chef server."
			when !remote_resource
				return "#{self.resource_path} is new and should be uploaded to the chef server."
			end
		end

	end

	class Role < ChefResource

		@resource_type = 'role'

	end

	class Environment < ChefResource

		@resource_type = 'environment'

	end

	class DataBag < ChefResource

		@resource_type = 'data_bag'

		def get_local_resource_show_list
			return self.class.get_formatted_knife_data(:data_bag_show, [self.name, '-z'])
		end

		def get_local_resource(dbag_file)
			return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, dbag_file, '-z'])
		end

		def get_remote_resource(dbag_file)
			return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, dbag_file])
		end

		def compare_local_and_remote_versions
			data_bag_files = self.get_local_resource_show_list

			data_bag_files.each do |file|
				local_resource = self.get_local_resource(file)
				remote_resource = self.get_remote_resource(file)
				file_path = "#{self.resource_path}/#{file}"

				case
				when local_resource != remote_resource
					return "#{file_path} should be uploaded to the chef server."
				when !remote_resource
					return "#{file_path} is new and should be uploaded to the chef server."
				end
			end
			return nil
		end

	end

	class Cookbook < ChefResource

		class << self; attr_accessor :ridley end
		@ridley = Ridley.from_chef_config
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
			remote_cookbook = self.class.ridley.cookbook.find(self.name, self.remote_version_number)
			remote_cookbook_files = Chef::CookbookVersion::COOKBOOK_SEGMENTS.collect { |d| remote_cookbook.method(d).call }.flatten
			return remote_cookbook_files
		end

		def compare_local_and_remote_versions
			local_ver = self.local_version_number
			remote_ver = self.remote_version_number

			case
			when local_ver < remote_ver
				return "Warning: remote #{self.resource_path} is newer than the local version."
			when local_ver == remote_ver
				return self.compare_cookbook_file_checksums
			when local_ver > remote_ver
				return "#{self.resource_path} should be uploaded to the chef server."
			when !remote_ver
				return "#{self.resource_path} is new and should be uploaded to the chef server."
			end
		end

		def compare_cookbook_file_checksums
			remote_cookbook_files = self.get_remote_resource

			remote_cookbook_files.each do |remote_file|
				local_file_path = "#{self.resource_path}/#{remote_file['path']}"
				begin
					local_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(File.open(local_file_path))
					return "Warning: local file #{local_file_path} has changed without a cookbook version change." unless local_file_checksum == remote_file['checksum']
				rescue Errno::ENOENT => e
					return "Warning: remote file #{local_file_path} doesn't exist locally."
				end
			end
		end

	end

end
