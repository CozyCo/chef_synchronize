require 'json'
require 'knife/api'

class ChefSync
	class Knife

		#Need to extend Chef::Knife::API in this class because knife_capture is top-level.
		extend Chef::Knife::API

		attr_reader :chef_resource
		attr_reader :list_command
		attr_reader :show_command
		attr_reader :upload_command

		def initialize(chef_resource, mode)
			@chef_resource = chef_resource
			@list_command = "#{chef_resource}_list".to_sym
			@show_command = "#{chef_resource}_show".to_sym

			if chef_resource == 'cookbook'
				@upload_command = "#{chef_resource}_upload".to_sym
			else
				@upload_command = "#{chef_resource}_from_file".to_sym
			end

			@mode = mode
		end

		# This is the hackiest hack ever.
		# Chef::Knife keeps a persistent option state -- if you add
		# an option like `--local-mode` once, it will be used on
		# _every_ future call to Chef::Knife. I would _love_ to
		# figure out how to change this behavior (lost many hours trying),
		# but until then, we fork a new process for `knife_capture` so
		# that we do not taint our global state.
		# This has to stay a class method for the same reason.
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

		# This instance method exists so we can mock out Knife's output for
		# individual instances when testing.
		def fork_knife_capture(command, args)
			return self.class.fork_knife_capture(command, args)
		end

		def local?
			return @mode == :local
		end

		def parse_output(command, args, output)
			stdout, stderr, status = output

			begin
				return JSON.parse(stdout)
			#Assuming here that a parser error means no data was returned and there was a knife error.
			rescue JSON::ParserError => e
				puts "Received STDERR #{stderr} when trying to run knife_capture(#{command}, #{args})."
				return stdout
			end
		end

		#Helper method to parse knife cookbook list into cookbooks.
		def format_cookbook_list_output(knife_output)
			cookbooks = {}
			knife_output.each do |c|
				cb, ver = c.gsub(/\s+/m, ' ').strip.split(" ")
				cookbooks[cb] = ver
			end
			return cookbooks
		end

		def capture_output(command, args)
			args << '-fj'
			args << '-z' if self.local?
			knife_output = self.fork_knife_capture(command, args)
			return self.parse_output(command, args, knife_output)
		end

		def list(*args)
			parsed_output = self.capture_output(self.list_command, args)
			if self.chef_resource == 'cookbook'
				parsed_output = self.format_cookbook_list_output(parsed_output)
			end
			return parsed_output
		end

		def show(*args)
			return self.capture_output(self.show_command, args)
		end

		def upload(*args)
			knife_output = self.fork_knife_capture(self.upload_command, args)
			stdout, stderr, status = knife_output
			unless status == 0
				puts "Received STDERR #{stderr} when trying to run knife_capture(#{self.upload_command}, #{args})."
			end
			return stdout
		end
	end
end
