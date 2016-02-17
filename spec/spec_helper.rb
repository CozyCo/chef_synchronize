require 'chef_sync'

require 'json'
require 'knife/api'
require 'rspec'

class ChefSync
	class KnifeMock < Knife
		
		def set_success(hash)
			@result = [hash.to_json, '', 0]
		end

		def set_error(err, status)
			@result = ['', err, status]
		end

		def fork_knife_capture(command, args)
			return @result
		end

	end


	class ChefComponentMock < ChefComponent

		@resource_type = 'fake_resource'

		attr_accessor :sync_called

		def initialize( *args )
			super
			@sync_called = false
			@change = :update
		end

		def sync
			@sync_called = true
		end

		def sync_called?
			return @sync_called
		end

	end

end

RSpec.configure do |config|
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
end

