require 'json'
require 'knife/api'

class ChefSync
	class ChefResource

		#Need to extend Chef::Knife::API in this class because knife_capture is top-level.
		extend Chef::Knife::API

		CHANGE_LOG_SUMMARIES = {
			:create => " was created.",
			:update => " was updated."
		}

		ACTIONABLE_CHANGES = [:create, :update]

		FILE_EXTENSION = ".json"

		class << self; attr_reader :resource_type end
		@resource_type = ''

		class << self; attr_accessor :resource_total end
		@resource_total = 0

		attr_reader :name
		attr_accessor :change

		def initialize(name)
			@name = name
			@change = :none
		end

		def self.sync(dryrun=false)
			local_resource_list = self.get_local_resource_list
			self.resource_total = local_resource_list.count
			action_summary = {}

			local_resource_list.each do |resource_name|
				resource = self.new(resource_name)
				action_summary[resource] = resource.sync(dryrun)
			end
			return self.formatted_action_summary(action_summary)
		end

		def self.formatted_action_summary(action_summary)
			changed_resources = action_summary.reject {|resource, action| action == :none}
			output = []

			changed_resources.each do |resource, action|
				output << resource.resource_path + CHANGE_LOG_SUMMARIES[action]
			end
			return output
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

		def self.knife_upload_resource_command
			return "#{self.resource_type}_from_file".to_sym
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
			return Marshal.load(command_output)
		end

		def self.parse_knife_capture_output(output)
			stdout, sderr, status = output

			begin
				return JSON.parse(stdout)
			#Assuming here that a parser error means no data was returned and there was a knife error.
			rescue JSON::ParserError => e
				puts "Received #{stderr} when trying to run knife_capture(#{command}, #{args})."
				puts "STDERR: " + stderr
				return stdout
			end
		end

		#Helper function to parse knife data.
		def self.get_formatted_knife_data(command, args=[])
			args << '-fj'
			knife_output = self.fork_knife_capture(command, args)
			return self.parse_knife_capture_output(knife_output)
		end

		def self.knife_upload(command, args=[])
			knife_output = self.fork_knife_capture(command, args)
			stdout, sderr, status = knife_output
			unless status == 0
				puts "Received #{stderr} when trying to run knife_capture(#{command}, #{args})."
				puts "STDERR: " + stderr
			end
			return stdout
		end

		def resource_path
			return "#{self.class.resource_type}s/#{self.name}"
		end

		def file_name_with_extension
			return self.name + FILE_EXTENSION
		end

		def get_local_resource
			return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, '-z'])
		end

		def get_remote_resource
			return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name])
		end

		def update_remote_resource
			return self.class.knife_upload(self.class.knife_upload_resource_command, [self.file_name_with_extension])
		end

		def compare_local_and_remote_versions
			local_resource = self.get_local_resource
			remote_resource = self.get_remote_resource

			case
			when !remote_resource
				self.change = :create
			when local_resource != remote_resource
				self.change = :update
			end

			return self.change
		end

		def sync(dryrun)
			action = self.compare_local_and_remote_versions
			if !dryrun and ACTIONABLE_CHANGES.include?(self.change)
				self.update_remote_resource
			end
			return action
		end

	end
end
