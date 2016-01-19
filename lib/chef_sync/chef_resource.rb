class ChefSync
	class ChefResource

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
		attr_reader :name_with_extension

		attr_accessor :change

		attr_reader :local_knife
		attr_reader :remote_knife

		def initialize(name, dryrun, local_knife, remote_knife)
			@name = name
			@name_with_extension = name + FILE_EXTENSION

			@change = :none
			@dryrun = dryrun

			@local_knife = local_knife
			@remote_knife = remote_knife
		end

		def self.sync(dryrun)
			local_knife = ChefSync::Knife.new(self.resource_type, :local)
			remote_knife = ChefSync::Knife.new(self.resource_type, :remote)

			local_resource_list = local_knife.list
			self.resource_total = local_resource_list.count
			action_summary = {}

			local_resource_list.each do |resource_name|
				resource = self.new(resource_name, dryrun, local_knife, remote_knife)
				action_summary[resource] = resource.sync
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

		def dryrun?
			return @dryrun == true
		end

		def resource_path
			return "#{self.class.resource_type}s/#{self.name}"
		end

		def get_resource(knife)
			return knife.show(self.name)
		end

		def upload_resource
			return self.remote_knife.upload(self.name_with_extension)
		end

		def compare_local_and_remote_versions
			local_resource = self.get_resource(self.local_knife)
			remote_resource = self.get_resource(self.remote_knife)

			case
			when remote_resource.empty?
				self.change = :create
			when local_resource != remote_resource
				self.change = :update
			end

			return self.change
		end

		def sync
			action = self.compare_local_and_remote_versions
			if self.dryrun? and ACTIONABLE_CHANGES.include?(self.change)
				self.upload_resource
			end
			return action
		end

	end
end
