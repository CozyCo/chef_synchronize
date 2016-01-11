require 'json'
require 'knife/api'

class ChefSync
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
end
