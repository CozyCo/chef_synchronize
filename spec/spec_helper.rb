require 'chef_sync'

require 'json'
require 'knife/api'

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
end

