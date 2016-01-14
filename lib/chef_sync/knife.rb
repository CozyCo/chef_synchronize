require 'json'
require 'knife/api'

class ChefSync
	class Knife

		#Need to extend Chef::Knife::API in this class because knife_capture is top-level.
		extend Chef::Knife::API

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

		def self.parse_output(output)
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

		def self.capture(command, args=[])
			args << '-fj'
			knife_output = self.fork_knife_capture(command, args)
			return self.parse_output(knife_output)
		end

		def self.upload(command, args=[])
			knife_output = self.fork_knife_capture(command, args)
			stdout, sderr, status = knife_output
			unless status == 0
				puts "Received #{stderr} when trying to run knife_capture(#{command}, #{args})."
				puts "STDERR: " + stderr
			end
			return stdout
		end
	end
end
