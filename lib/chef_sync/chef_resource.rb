class ChefSync
	class ChefResource

		CHANGE_LOG_SUMMARIES = {
			:create => " was created.",
			:update => " was updated."
		}

		ACTIONABLE_CHANGES = [:create, :update]

		FILE_EXTENSION = ".json"

		class << self; attr_reader :resource_type end
		class << self; attr_accessor :dryrun end
		class << self; attr_accessor :action_summary end
		class << self; attr_accessor :local_knife end
		class << self; attr_accessor :remote_knife end

		@action_summary = {}

		attr_reader :name
		attr_reader :name_with_extension
		attr_accessor :change

		def initialize(name:)
			@name = name
			@name_with_extension = name + FILE_EXTENSION

			@change = :none
		end

		def self.action_summary
			return @action_summary ||= {}
		end

		def self.sync(dryrun)
			self.local_knife = ChefSync::Knife.new(self.resource_type, :local)
			self.remote_knife = ChefSync::Knife.new(self.resource_type, :remote)
			self.dryrun = dryrun

			local_resources = self.get_local_resources

			local_resources.each do |args|
				resource = self.new(args)
				self.action_summary[resource] = resource.sync
			end
			return self.formatted_action_summary
		end

		def self.get_local_resources
			local_resources = self.local_knife.list
			return local_resources.map {|resource_name| {name: resource_name}}
		end

		def self.formatted_action_summary
			changed_resources = self.action_summary.select {|_, action| self.actionable_change?(action)}
			output = []

			changed_resources.each do |resource, action|
				output << resource.resource_path + CHANGE_LOG_SUMMARIES[action]
			end
			return output
		end

		def self.dryrun?
			return @dryrun == true
		end

		def self.actionable_change?(action)
			return ACTIONABLE_CHANGES.include?(action)
		end

		def resource_path
			return "#{self.class.resource_type}s/#{self.name}"
		end

		def get_local_resource
			return self.class.local_knife.show(self.name)
		end

		def get_remote_resource
			return self.class.remote_knife.show(self.name)
		end

		def upload_resource
			return self.class.remote_knife.upload(self.name_with_extension)
		end

		def compare_local_and_remote_versions
			local_resource = self.get_local_resource
			remote_resource = self.get_remote_resource

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
			if self.class.dryrun? and self.class.actionable_change?(self.change)
				self.upload_resource
			end
			return action
		end

	end
end
